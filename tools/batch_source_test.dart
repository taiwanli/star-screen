import 'dart:async' show Completer;
import 'dart:convert';
import 'dart:io';

import 'package:star_domain/star_domain.dart';

/// 批量实测 docs/06 / source_samples.json 中全部测试源。
/// 输出：控制台摘要 + tools/batch_source_report.md
Future<void> main() async {
  final samplesFile = File('tools/source_samples.json');
  final root = jsonDecode(samplesFile.readAsStringSync()) as Map<String, dynamic>;
  final sources = (root['sources'] as List).cast<Map<String, dynamic>>();
  stdout.writeln('样本数: ${sources.length}');

  final fetcher = FeedFetcher();
  final results = <_Row>[];
  final semaphore = _Sem(6);

  await Future.wait([
    for (final s in sources)
      () async {
        await semaphore.acquire();
        try {
          results.add(await _testOne(fetcher, s));
        } finally {
          semaphore.release();
        }
      }(),
  ]);

  // 汇总
  final ok = results.where((r) => r.status == '✅').length;
  final warn = results.where((r) => r.status == '⚠️').length;
  final fail = results.where((r) => r.status == '❌').length;
  final buf = StringBuffer()
    ..writeln('# 批量源实测报告')
    ..writeln()
    ..writeln('生成: ${DateTime.now().toIso8601String()}')
    ..writeln('样本: ${results.length} · ✅$ok · ⚠️$warn · ❌$fail')
    ..writeln()
    ..writeln('| 状态 | 名称 | 类别 | 说明 |')
    ..writeln('|---|---|---|---|');
  for (final r in results) {
    buf.writeln('| ${r.status} | ${r.name} | ${r.cat} | ${r.note} |');
  }
  File('tools/batch_source_report.md').writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().split('\n').take(12).join('\n'));
  stdout.writeln('…完整报告 tools/batch_source_report.md');
  stdout.writeln('汇总 ✅$ok ⚠️$warn ❌$fail');
}

class _Row {
  final String status;
  final String name;
  final String cat;
  final String note;
  const _Row(this.status, this.name, this.cat, this.note);
}

class _Sem {
  _Sem(this.n);
  int n;
  final _wait = <void Function()>[];
  Future<void> acquire() {
    if (n > 0) {
      n--;
      return Future<void>.value();
    }
    final c = Completer<void>();
    _wait.add(c.complete);
    return c.future;
  }

  void release() {
    n++;
    if (_wait.isNotEmpty) {
      n--;
      final fn = _wait.removeAt(0);
      fn();
    }
  }
}

Future<_Row> _testOne(
    FeedFetcher fetcher, Map<String, dynamic> s) async {
  final name = s['name']?.toString() ?? '?';
  final url = s['url']?.toString() ?? '';
  final cat = s['cat']?.toString() ?? '';
  try {
    final raw = await fetcher
        .fetchSubscription(url, timeout: const Duration(seconds: 12));
    final body = raw.body;
    if (body.isEmpty) {
      return _Row('❌', name, cat, '空响应');
    }
    switch (cat) {
      case 'cms-json':
        return await _probeCmsJson(name, url);
      case 'cms-xml':
        return await _probeCmsXml(name, url);
      case 'live':
        final live = LiveParser.parse(body);
        return _Row('✅', name, cat, '频道 ${live.channels.length} · EPG ${live.epgUrl != null ? 'Y' : 'N'}');
      case 'jssrc':
        return body.length > 50
            ? _Row('✅', name, cat, 'JS 文件 ${body.length}B')
            : _Row('⚠️', name, cat, '内容过短');
      case 'warehouse':
        final report = TvBoxConfigParser.parse(raw: body, baseUrl: raw.url);
        return _Row(
            report.warehouses.isNotEmpty || report.sources.isNotEmpty ? '✅' : '⚠️',
            name,
            cat,
            '仓库 ${report.warehouses.length} · 站 ${report.sources.length}');
      case 'known-dead':
        return _Row('⚠️', name, cat, '已知失效样本（容错）HTTP ${raw.statusCode}');
      default:
        final report = TvBoxConfigParser.parse(raw: body, baseUrl: raw.url);
        final kinds = <String, int>{};
        for (final x in report.sources) {
          kinds[x.kind.name] = (kinds[x.kind.name] ?? 0) + 1;
        }
        final adapt = report.sources.where((x) => x.kind.hasAdapter).length;
        return _Row('✅', name, cat,
            '站 ${report.sources.length}（可浏览 $adapt）· ${kinds} · 问题 ${report.issues.length}');
    }
  } on Object catch (e) {
    final msg = e.toString();
    final short = msg.length > 80 ? msg.substring(0, 80) : msg;
    return _Row(cat == 'known-dead' ? '⚠️' : '❌', name, cat, short);
  }
}

Future<_Row> _probeCmsJson(String name, String url) async {
  final def = SourceDef(
    key: name,
    name: name,
    kind: SourceKind.cmsJson,
    endpoint: url,
    headers: const {'User-Agent': 'StarScreen/0.1'},
    timeoutSec: 12,
  );
  final src = CmsJsonSource(def: def);
  final home = await src.home();
  if (home.recommend.isEmpty) return _Row('⚠️', name, 'cms-json', '首页空');
  final card = home.recommend.first;
  final detail = await src.detail(card.workId);
  final play = await src.resolve(
      PlayRequest(workId: card.workId, episodeIndex: 0));
  return _Row('✅', name, 'cms-json',
      '首页${home.recommend.length} · ${detail.lines.length}线路 · 播放${play.needsParse ? "需解析" : "直链"}');
}

Future<_Row> _probeCmsXml(String name, String url) async {
  final def = SourceDef(
    key: name,
    name: name,
    kind: SourceKind.cmsXml,
    endpoint: url,
    headers: const {'User-Agent': 'StarScreen/0.1'},
    timeoutSec: 12,
  );
  final src = CmsXmlSource(def: def);
  final home = await src.home();
  if (home.recommend.isEmpty) return _Row('⚠️', name, 'cms-xml', '首页空');
  return _Row('✅', name, 'cms-xml', '首页${home.recommend.length} · 样例 ${home.recommend.first.title}');
}

