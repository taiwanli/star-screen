import 'dart:async';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../starrule/converters/xpath_to_star_rule.dart';
import '../starrule/star_rule.dart';
import '../starrule/star_rule_importer.dart';
import '../starrule/star_rule_parser.dart';
import '../util/semaphore.dart';

/// 测活层级（docs/18 §6 四链路）。
enum CheckLevel {
  /// L1 订阅可达（由 importer/feeder 负责，此处不跑）。
  subscription,

  /// L2 首页推荐。
  home,

  /// L3 搜索（输入「爱」）。
  search,

  /// L4 详情 + 播放抽检（取第一条推荐）。
  detailPlay,
}

/// 失败原因代码（docs/18 §6 文案表）。
enum CheckFailCode {
  none,
  timeout,
  dns,
  http,
  empty,
  parse,
  needsJar,
  needsJs,
  unknown,
}

/// 源有效性检测（模仿阅读 APP「检测书源」，docs/18 §6 四链路升级）。
///
/// 对每个源做轻量探活：L2 首页 → 失败再 L3 搜索 → 可选 L4 详情+播放；
/// 记录通过/失败原因与错误码。并发限流 + 单源超时；结果写入
/// [SourceCheckResult] 供 UI 筛选与一键删除。
class SourceChecker {
  SourceChecker({
    this.concurrency = 6,
    this.timeout = const Duration(seconds: 8),
    this.depth = CheckLevel.search,
  });

  final int concurrency;
  final Duration timeout;

  /// 测活深度：home 只跑 L2；search 到 L3（默认）；detailPlay 到 L4。
  final CheckLevel depth;

  /// 批量检测；[onProgress] 回传已完成数/总数；[onResult] 每源完成即回调。
  Future<List<SourceCheckResult>> checkAll(
    List<VideoSource> sources, {
    void Function(int done, int total)? onProgress,
    void Function(SourceCheckResult result)? onResult,
  }) async {
    final sem = Semaphore(concurrency);
    final out = List<SourceCheckResult?>.filled(sources.length, null);
    var done = 0;
    await Future.wait([
      for (var i = 0; i < sources.length; i++)
        () async {
          await sem.acquire();
          try {
            out[i] = await check(sources[i]);
          } on Object catch (e) {
            out[i] = SourceCheckResult(
              key: sources[i].def.key,
              name: sources[i].def.name,
              ok: false,
              reason: e.toString(),
              code: CheckFailCode.unknown,
            );
          } finally {
            sem.release();
            done++;
            final r = out[i];
            if (r != null) onResult?.call(r);
            onProgress?.call(done, sources.length);
          }
        }(),
    ]);
    return [for (final r in out) if (r != null) r];
  }

  Future<SourceCheckResult> check(VideoSource source) async {
    final sw = Stopwatch()..start();

    SourceCheckResult fail(String reason, CheckFailCode code) =>
        SourceCheckResult(
          key: source.def.key,
          name: source.def.name,
          ok: false,
          reason: reason,
          code: code,
          latencyMs: sw.elapsedMilliseconds,
        );

    // 需 jar / 需 JS 的端上能力差异（docs/17 §11）
    final kind = source.def.kind;
    if (kind == SourceKind.spiderJar && source.def.unsupportedReason != null) {
      return fail(source.def.unsupportedReason!, CheckFailCode.needsJar);
    }

    try {
      // ── L2 首页 ──
      final home = await source.home().timeout(timeout);
      final hasHome = home.recommend.isNotEmpty;

      // ── L3 搜索 ──
      var hasSearch = false;
      if (depth != CheckLevel.home) {
        try {
          final page = await source.search('爱').timeout(timeout);
          hasSearch = page.items.isNotEmpty;
        } on Object {
          hasSearch = false;
        }
      }

      if (!hasHome && !hasSearch) {
        return fail('首页与搜索均无结果', CheckFailCode.empty);
      }

      // ── L4 详情 + 播放抽检 ──
      if (depth == CheckLevel.detailPlay) {
        String? workId;
        String? lineId;
        if (hasHome && home.recommend.isNotEmpty) {
          workId = home.recommend.first.workId;
        }
        if (workId == null && hasSearch) {
          try {
            final page = await source.search('爱').timeout(timeout);
            if (page.items.isNotEmpty) workId = page.items.first.workId;
          } on Object {
            // 已有 search 结果时忽略
          }
        }
        if (workId != null) {
          try {
            final detail = await source.detail(workId).timeout(timeout);
            if (detail.lines.isEmpty || detail.lines.first.episodes.isEmpty) {
              return fail('详情无可用选集', CheckFailCode.empty);
            }
            lineId = detail.lines.first.lineId;
            final cand = await source
                .resolve(PlayRequest(
                  workId: workId,
                  episodeIndex: 0,
                  lineId: lineId,
                ))
                .timeout(timeout);
            if (cand.url.isEmpty) {
              return fail('播放地址为空', CheckFailCode.empty);
            }
          } on TimeoutException {
            return fail('检测超时（${timeout.inSeconds}s）', CheckFailCode.timeout);
          } on Object catch (e) {
            final msg = e.toString();
            final code = _codeOf(msg);
            return fail(_humanize(msg, code), code);
          }
        }
      }

      return SourceCheckResult(
        key: source.def.key,
        name: source.def.name,
        ok: true,
        latencyMs: sw.elapsedMilliseconds,
      );
    } on TimeoutException {
      return fail('检测超时（${timeout.inSeconds}s）', CheckFailCode.timeout);
    } on Object catch (e) {
      final msg = e.toString();
      final code = _codeOf(msg);
      return fail(_humanize(msg, code), code);
    }
  }

  static CheckFailCode _codeOf(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('timeout') || m.contains('超时')) return CheckFailCode.timeout;
    if (m.contains('failed host lookup') || m.contains('dns')) {
      return CheckFailCode.dns;
    }
    if (m.contains('为空') || m.contains('empty') || m.contains('无可用') || m.contains('无结果')) {
      return CheckFailCode.empty;
    }
    if (m.contains('http') || RegExp(r'\b[45]\d\d\b').hasMatch(m)) {
      return CheckFailCode.http;
    }
    if (m.contains('无法解析') || m.contains('parse')) return CheckFailCode.parse;
    if (m.contains('jar') || m.contains('蜘蛛')) return CheckFailCode.needsJar;
    if (m.contains('js') || m.contains('quickjs')) return CheckFailCode.needsJs;
    return CheckFailCode.unknown;
  }

  static String _humanize(String msg, CheckFailCode code) {
    switch (code) {
      case CheckFailCode.timeout:
        return '检测超时';
      case CheckFailCode.dns:
        return '域名解析失败';
      case CheckFailCode.http:
        return msg.length > 60 ? msg.substring(0, 60) : msg;
      case CheckFailCode.parse:
        return '响应无法解析（规则可能失效）';
      case CheckFailCode.needsJar:
        return '该源需 jar，当前端不支持';
      case CheckFailCode.needsJs:
        return '该源含脚本，引擎未就绪';
      case CheckFailCode.empty:
        return '无结果';
      case CheckFailCode.none:
      case CheckFailCode.unknown:
        return msg.length > 60 ? msg.substring(0, 60) : msg;
    }
  }
}

/// 单源检测结果。
class SourceCheckResult {
  final String key;
  final String name;
  final bool ok;
  final String? reason;
  final int? latencyMs;
  final CheckFailCode code;

  const SourceCheckResult({
    required this.key,
    required this.name,
    required this.ok,
    this.reason,
    this.latencyMs,
    this.code = CheckFailCode.none,
  });
}

/// 书源筛选（阅读 APP：全部 / 启用 / 失效 / 停用 / 不支持）。
enum SourceFilter { all, enabled, invalid, disabled, unsupported }

extension SourceFilterX on SourceFilter {
  List<SourceDef> apply(
    List<SourceDef> all,
    Map<String, SourceCheckResult> checks,
  ) {
    switch (this) {
      case SourceFilter.all:
        return all;
      case SourceFilter.enabled:
        return [for (final s in all) if (s.enabled) s];
      case SourceFilter.invalid:
        return [
          for (final s in all)
            if (checks[s.key]?.ok == false) s,
        ];
      case SourceFilter.disabled:
        return [for (final s in all) if (!s.enabled) s];
      case SourceFilter.unsupported:
        return [for (final s in all) if (!s.kind.isSupported) s];
    }
  }
}

/// XPath 规则源 → StarRule 转译落库（导入管线调用，docs/17 §7.3）。
///
/// ext 为内联 JSON 时可直接转；为 URL 时由调用方先拉取再传入。
/// 转成功返回 StarRule [SourceDef]，失败返回 null（保持 xpathRule 原样）。
SourceDef? tryConvertXpathToStarRule(SourceDef xpathDef, {String? extBody}) {
  if (xpathDef.kind != SourceKind.xpathRule) return null;
  final raw = extBody ?? xpathDef.extRaw;
  if (raw == null || raw.isEmpty) return null;
  try {
    final converted = XpathToStarRule.convert(raw);
    // 转译结果的 raw 必须是 StarRule JSON（而非原 xpath map）
    final rule = StarRule(
      version: converted.rule.version,
      meta: converted.rule.meta,
      site: converted.rule.site,
      sourceType: converted.rule.sourceType,
      home: converted.rule.home,
      category: converted.rule.category,
      detail: converted.rule.detail,
      search: converted.rule.search,
      play: converted.rule.play,
      caps: converted.rule.caps,
      tags: converted.rule.tags,
      enabled: converted.rule.enabled,
      convertedFrom: 'tvbox-xpath',
      raw: const {},
    );
    final def = StarRuleImporter.toSourceDef(
      rule,
      groupId: xpathDef.groupId,
    );
    // 保留原 key，便于订阅刷新时对齐
    return SourceDef(
      key: xpathDef.key,
      name: xpathDef.name,
      kind: SourceKind.starRule,
      cmsVariant: def.cmsVariant,
      endpoint: def.endpoint,
      extRaw: def.extRaw,
      extUrl: xpathDef.extUrl,
      sourceUrl: def.sourceUrl,
      jarRef: xpathDef.jarRef,
      caps: def.caps,
      headers: {
        ...def.headers,
        ...xpathDef.headers,
      },
      timeoutSec: def.timeoutSec ?? xpathDef.timeoutSec,
      enabled: xpathDef.enabled,
      groupId: xpathDef.groupId,
    );
  } on StarRuleParseException {
    return null;
  } on Object {
    return null;
  }
}

/// 批量转译列表中的 xpathRule → starRule；失败项原样保留。
/// 返回 `(defs, convertedCount)`。
(List<SourceDef> defs, int converted) convertXpathDefs(
  List<SourceDef> defs, {
  Map<String, String>? extBodies,
}) {
  var n = 0;
  final out = <SourceDef>[];
  for (final d in defs) {
    if (d.kind != SourceKind.xpathRule) {
      out.add(d);
      continue;
    }
    final converted = tryConvertXpathToStarRule(
      d,
      extBody: extBodies?[d.key] ?? d.extRaw,
    );
    if (converted != null) {
      out.add(converted);
      n++;
    } else {
      out.add(d);
    }
  }
  return (out, n);
}
