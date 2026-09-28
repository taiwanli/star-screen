// 源兼容性批量探测器（docs/11）。
// 用真实引擎（FeedFetcher + TvBoxConfigParser）对样本库全量实测：
//   直连失败自动走代理 → 分类识别 → 单仓解析统计 → 多仓一层递归 →
//   从存活配置抽取内嵌 CMS 端点实测 → 输出 Markdown 报告。
// 运行（仓库根目录）：
//   STAR_PROXY=http://127.0.0.1:7890 dart run tools/source_probe.dart
import 'dart:convert';
import 'dart:io';

import 'package:star_domain/star_domain.dart';

const _timeout = Duration(seconds: 10);
const _poolSize = 6;

Future<void> main() async {
  final samplesFile = File('tools/source_samples.json');
  final doc = jsonDecode(await samplesFile.readAsString()) as Map<String, dynamic>;
  final sources = (doc['sources'] as List).cast<Map<String, dynamic>>();

  final results = <ProbeResult>[];
  final cmsExtra = <(String, Uri)>{}; // 从存活配置抽取的内嵌 CMS 端点

  // 并发池
  var cursor = 0;
  Future<void> worker() async {
    while (cursor < sources.length) {
      final idx = cursor++;
      final s = sources[idx];
      // 每条 60s 硬看门狗：个别死域名的 DNS/连接会挂死超过所有套接字超时
      final r = await probeEntry(
        name: s['name'] as String,
        url: s['url'] as String,
        cat: s['cat'] as String,
        cmsSink: cmsExtra,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => ProbeResult(
            s['name'] as String, s['cat'] as String, '❌', '探测总超时（60s）—— DNS 或连接挂死'),
      );
      results.add(r);
      stdout.writeln(r.mark());
    }
  }

  await Future.wait([for (var i = 0; i < _poolSize; i++) worker()]);

  // 内嵌 CMS 端点实测（去重后，上限 40）
  final extraList = cmsExtra.toList()..removeRange(40.clamp(0, cmsExtra.length), cmsExtra.length);
  cursor = 0;
  Future<void> cmsWorker() async {
    while (cursor < extraList.length) {
      final idx = cursor++;
      final (name, uri) = extraList[idx];
      final r = await probeCms(name, uri).timeout(
        const Duration(seconds: 45),
        onTimeout: () => ProbeResult(name, 'cms-harvest', '❌', '探测总超时'),
      );
      results.add(r);
      stdout.writeln(r.mark());
    }
  }

  await Future.wait([for (var i = 0; i < _poolSize; i++) cmsWorker()]);

  results.sort((a, b) => a.category.compareTo(b.category));

  // ---- 输出 Markdown 报告 ----
  final buf = StringBuffer();
  buf.writeln('| 名称 | 类别 | 状态 | 明细 |');
  buf.writeln('|---|---|---|---|');
  for (final r in results) {
    buf.writeln(r.mdRow());
  }
  final ok = results.where((r) => r.status.startsWith('✅')).length;
  final warn = results.where((r) => r.status.startsWith('⚠️')).length;
  final fail = results.where((r) => r.status.startsWith('❌')).length;
  final header =
      '探测时间：${DateTime.now()} ｜ 样本 ${results.length} 个：'
      '✅ $ok ｜ ⚠️ $warn ｜ ❌ $fail\n\n';
  final content = header + buf.toString();
  await File('tools/probe_report.md').writeAsString(content);
  stdout.writeln('== 报告已写入 tools/probe_report.md（共 ${results.length} 条）');
}

class ProbeResult {
  final String name;
  final String category;
  final String status; // ✅ / ⚠️ / ❌
  final String detail;

  ProbeResult(this.name, this.category, this.status, this.detail);

  String mark() => '$status [$category] $name — $detail';

  String mdRow() => '| $name | $category | $status | ${detail.replaceAll('|', '丨')} |';
}

Future<FetchResult> _fetchFlexible(Uri url) async {
  // 三级回退：直连 → 代理 → 代理+信任自签（docs/11 压测反馈）
  try {
    return await const IoHttpFetch().get(url, timeout: _timeout);
  } on FetchException {
    try {
      return await const IoHttpFetch(proxy: 'PROXY 127.0.0.1:7890')
          .get(url, timeout: _timeout);
    } on FetchException {
      return const IoHttpFetch(
        proxy: 'PROXY 127.0.0.1:7890',
        trustSelfSigned: true,
      ).get(url, timeout: _timeout);
    }
  }
}

ProbeResult _classify({
  required String name,
  required String cat,
  required Uri url,
  required String body,
  Set<(String, Uri)>? cmsSink,
}) {
  final head = body.trimLeft();
  // 直播
  if (head.startsWith('#EXTM3U')) {
    final chans = '#EXTINF'.allMatches(body).length;
    return ProbeResult(name, cat, '✅', 'M3U · $chans 个频道');
  }
  if (body.contains('#genre#')) {
    final lines = body
        .split('\n')
        .where((l) => l.contains(',') && !l.contains('#genre#'))
        .length;
    return ProbeResult(name, cat, '✅', 'TXT直播 · $lines 个频道行');
  }
  // XML（含注释前缀的响应，实测卧龙备份站）
  if (head.startsWith('<rss') ||
      head.startsWith('<!') ||
      head.startsWith('<?xml') ||
      body.contains('<rss ')) {
    return ProbeResult(name, cat, '✅', 'CMS XML 响应');
  }
  if (head.startsWith('<')) {
    final suggestion = RegExp(r'https?://[^\s"<>]+\.json').firstMatch(body);
    return ProbeResult(name, cat, '⚠️',
        'HTML 页面（入口型接口）${suggestion == null ? '' : '，页面内含 ${suggestion.group(0)}'}');
  }
  // JSON（走引擎清洗器：注释行/BOM/尾逗号/控制字符）
  try {
    final json = ConfigCleaner.decode(body, source: url);
    if (json is Map<String, dynamic>) {
      if (json['storeHouse'] is List) {
        final n = (json['storeHouse'] as List).length;
        return ProbeResult(name, cat, '✅', '多仓 · $n 个子仓');
      }
      if (json['sites'] is List) {
        final report = TvBoxConfigParser.parse(raw: body, baseUrl: url);
        final t = <String, int>{};
        for (final s in report.sources) {
          t[s.kind.name] = (t[s.kind.name] ?? 0) + 1;
        }
        // 抽取内嵌 CMS 端点供二段实测
        if (cmsSink != null) {
          for (final s in report.sources) {
            if ((s.kind == SourceKind.cmsJson || s.kind == SourceKind.cmsXml) &&
                s.endpoint != null) {
              final u = Uri.tryParse(s.endpoint!);
              if (u != null && u.host.isNotEmpty) cmsSink.add((s.name, u));
            }
          }
        }
        final dist = t.entries.map((e) => '${e.key}=${e.value}').join('/');
        final live = report.lives.isEmpty ? '' : ' · 直播${report.lives.length}组';
        final issue = report.issues.isEmpty ? '' : ' · 问题${report.issues.length}';
        return ProbeResult(name, cat, '✅',
            '单仓 · ${report.sources.length}站($dist)$live$issue');
      }
      if (json['code'] != null && (json['list'] is List)) {
        final list = json['list'] as List;
        final total = json['total'];
        final pagecount = json['pagecount'];
        final hasClass = json['class'] is List;
        return ProbeResult(
            name, cat, '✅', 'CMS JSON · list=${list.length} total=$total pagecount=$pagecount class=$hasClass');
      }
      if (json['channels'] != null || json['groups'] != null) {
        return ProbeResult(name, cat, '✅', 'JSON 直播表');
      }
      return ProbeResult(name, cat, '⚠️', 'JSON（未知结构：顶层${json.keys.take(5).join(',')}）');
    }
  } on ConfigParseException {
    rethrow; // 交给上层按无效源提示（引擎错误消息自带上下文）
  } on FormatException {
    // 不是 JSON
  }
  return ProbeResult(name, cat, '⚠️',
      '非配置内容（前20字符：${body.trim().substring(0, body.trim().length > 20 ? 20 : body.trim().length)}）');
}

Future<ProbeResult> probeEntry({
  required String name,
  required String url,
  required String cat,
  Set<(String, Uri)>? cmsSink,
}) async {
  final uri = Uri.parse(url);
  try {
    final result = await _fetchFlexible(uri);
    final r = _classify(
        name: name, cat: cat, url: uri, body: result.body, cmsSink: cmsSink);
    // 多仓：一层递归实测第一个子仓
    if (r.detail.startsWith('多仓')) {
      try {
        final report = TvBoxConfigParser.parse(raw: result.body, baseUrl: uri);
        if (report.warehouses.isNotEmpty) {
          final first = report.warehouses.first.url;
          final sub = await _fetchFlexible(Uri.parse(first));
          final subR = _classify(
              name: '${name}→${report.warehouses.first.name}',
              cat: 'warehouse-sub',
              url: Uri.parse(first),
              body: sub.body);
          return ProbeResult(name, cat, r.status,
              '${r.detail}；首子仓 ${subR.status} ${subR.detail}');
        }
      } on Object {
        return ProbeResult(name, cat, '⚠️', '${r.detail}；子仓递归解析失败');
      }
    }
    return r;
  } on FetchException catch (e) {
    return ProbeResult(name, cat, '❌', '获取失败：${e.message}${e.statusCode == null ? '' : ' (HTTP ${e.statusCode})'}');
  } on ConfigParseException catch (e) {
    return ProbeResult(name, cat, '⚠️', '解析失败：${e.message}');
  } on Object catch (e) {
    return ProbeResult(name, cat, '❌', '异常：$e');
  }
}

Future<ProbeResult> probeCms(String name, Uri base) async {
  final probeName = 'CMS抽取·$name';
  try {
    final r1 = await _fetchFlexible(base.replace(queryParameters: {'ac': 'list'}));
    // XML 型端点（实测：玉兔等 type0 端点出现在 type1 混用配置里）
    final head1 = r1.body.trimLeft();
    if (head1.startsWith('<rss') ||
        head1.startsWith('<?xml') ||
        head1.startsWith('<!')) {
      return ProbeResult(probeName, 'cms-harvest', '✅', 'CMS XML 响应');
    }
    final doc = jsonDecode(r1.body);
    if (doc is! Map<String, dynamic> || doc['code'] != 1) {
      return ProbeResult(probeName, 'cms-harvest', '❌', 'ac=list code≠1');
    }
    final list = doc['list'];
    final firstId = (list is List && list.isNotEmpty)
        ? (list.first as Map<String, dynamic>)['vod_id']?.toString()
        : null;
    var detail = '';
    if (firstId != null) {
      final r2 = await _fetchFlexible(
          base.replace(queryParameters: {'ac': 'detail', 'ids': firstId}));
      final d = jsonDecode(r2.body);
      if (d is Map<String, dynamic> &&
          d['list'] is List &&
          (d['list'] as List<Object?>).isNotEmpty) {
        final v = ((d['list'] as List<Object?>).first ?? {}) as Map<String, dynamic>;
        final from = v['vod_play_from']?.toString() ?? '';
        final urls = v['vod_play_url']?.toString() ?? '';
        detail = ' · 线路[$from] play_url=${urls.isEmpty ? '缺' : '有'}';
      }
    }
    final total = doc['total'] as Object?;
    final pagecount = doc['pagecount'] as Object?;
    return ProbeResult(probeName, 'cms-harvest', '✅',
        'CMS可用 total=$total pagecount=$pagecount$detail');
  } on Object catch (e) {
    return ProbeResult(probeName, 'cms-harvest', '❌', '不可用：$e');
  }
}
