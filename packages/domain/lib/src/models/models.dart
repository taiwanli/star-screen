/// 星映领域模型（docs/03 §6 数据模型 / docs/05 §4 统一模型）。
///
/// 全部为不可变值对象；JSON 序列化由各适配器负责，模型层不做反射。
library;

/// 源的解析器种类 —— 决定由哪个适配器执行（docs/05 §2 兼容矩阵）。
enum SourceKind {
  /// 苹果CMS JSON（type=1；AppYsV2 归入本类的变体）。
  cmsJson,

  /// 苹果CMS XML（type=0；海洋/飞飞老式变体）。
  cmsXml,

  /// csp_XPath 系规则源 —— 由原生"XPath 规则引擎"转译，不执行 jar。
  xpathRule,

  /// drpy/drpy2 JS 源 —— QuickJS 沙箱执行。
  drpyJs,

  /// csp_AList 网盘挂载（Alist API）。
  alist,

  /// 直播频道组（m3u/txt/json）。
  live,

  /// jar 蜘蛛（type=3 + csp_*）：经端上执行桥（Android DexClassLoader / Java）。
  spiderJar,

  /// 星映统一源规则（StarRule v1，docs/17）—— 三端同一解释器。
  starRule,

  /// 明确不支持。UI 置灰并展示 [SourceDef.unsupportedReason]，绝不静默失败。
  unsupported;

  bool get isSupported => this != unsupported;

  /// 是否已有原生适配器（可 browse/search/detail/play）。
  /// xpath/alist/live 等：导入可注册，但浏览链路暂无适配器。
  bool get hasAdapter =>
      this == cmsJson ||
      this == cmsXml ||
      this == drpyJs ||
      this == spiderJar ||
      this == starRule;
}

/// CMS 接口变体（docs/04 §5.5）。
enum CmsVariant { none, appysV2 }

/// 源能力声明 —— 注册时产出，聚合搜索与 UI 据此分流（docs/05 §3 关键设计原则 3）。
class SourceCaps {
  final bool searchable;
  final bool quickSearch;
  final bool filterable;
  final bool changeable;

  const SourceCaps({
    this.searchable = true,
    this.quickSearch = true,
    this.filterable = true,
    this.changeable = true,
  });

  const SourceCaps.disabled()
      : searchable = false,
        quickSearch = false,
        filterable = false,
        changeable = false;
}

/// 源健康度（docs/05 §8 评分模型）。
enum HealthLevel { excellent, good, degraded, dead }

class SourceHealth {
  final int? latencyMs;
  final double successRate; // 0.0 - 1.0，近 20 次滑动窗口
  final DateTime? lastCheck;

  const SourceHealth({
    this.latencyMs,
    this.successRate = 1.0,
    this.lastCheck,
  });

  HealthLevel get level {
    if (successRate >= 0.95 && (latencyMs ?? 999) < 300) return HealthLevel.excellent;
    if (successRate >= 0.8) return HealthLevel.good;
    if (successRate >= 0.4) return HealthLevel.degraded;
    return HealthLevel.dead;
  }
}

/// 归一后的源定义 —— 订阅解析管线的产物，也是 source_registry 的持久化对象。
///
/// 关键设计（docs/05 §3 原则 1「解析器固化」）：注册时即固化 kind 与全部初始化
/// 参数，后续配置合并永不覆盖，根治生态中"全局 spider 被覆盖导致站点失效"的问题。
class SourceDef {
  final String key;
  final String name;
  final SourceKind kind;
  final CmsVariant cmsVariant;

  /// cms 基地址 / drpy 运行时地址（已按订阅 URL 解析为绝对地址）。
  final String? endpoint;

  /// ext 原文（URL / JSON / `$$$` 复合串，语义由适配器解释）。
  final String? extRaw;

  /// ext 为 http(s) 时解析后的绝对地址（由 fetcher 拉取）。
  final String? extUrl;

  /// drpy JS 源文件地址（`api=运行时` + `ext=源文件`，docs/04 §3.3）。
  final String? sourceUrl;

  /// 站点级 jar ?? 全局 spider（仅作引用记录与 unsupported 判定，永不下载执行）。
  final String? jarRef;

  final SourceCaps caps;
  final Map<String, String> headers;
  final int? timeoutSec;
  final String? unsupportedReason;
  final bool enabled;

  /// 源分组（多仓导入时 = 仓库名；组级启停/展示用，docs/09 M2-4）。
  final String? groupId;

  const SourceDef({
    required this.key,
    required this.name,
    required this.kind,
    this.cmsVariant = CmsVariant.none,
    this.endpoint,
    this.extRaw,
    this.extUrl,
    this.sourceUrl,
    this.jarRef,
    this.caps = const SourceCaps(),
    this.headers = const {},
    this.timeoutSec,
    this.unsupportedReason,
    this.enabled = true,
    this.groupId,
  });

  SourceDef withEnabled(bool value) => SourceDef(
        key: key,
        name: name,
        kind: kind,
        cmsVariant: cmsVariant,
        endpoint: endpoint,
        extRaw: extRaw,
        extUrl: extUrl,
        sourceUrl: sourceUrl,
        jarRef: jarRef,
        caps: caps,
        headers: headers,
        timeoutSec: timeoutSec,
        unsupportedReason: unsupportedReason,
        enabled: value,
        groupId: groupId,
      );

  SourceDef withGroup(String? group) => SourceDef(
        key: key,
        name: name,
        kind: kind,
        cmsVariant: cmsVariant,
        endpoint: endpoint,
        extRaw: extRaw,
        extUrl: extUrl,
        sourceUrl: sourceUrl,
        jarRef: jarRef,
        caps: caps,
        headers: headers,
        timeoutSec: timeoutSec,
        unsupportedReason: unsupportedReason,
        enabled: enabled,
        groupId: group,
      );

  /// 跨源唯一键：sourceKey + workId（docs/03 §6 workKey 复合键）。
  static String workKey(String sourceKey, String workId) => '$sourceKey::$workId';

  /// 从 [workKey] 拆出 workId（`sourceKey::workId`；sourceKey 自身可含 `::` 时取首个分隔后全部）。
  static String workIdFromKey(String workKey, String sourceKey) {
    final prefix = '$sourceKey::';
    return workKey.startsWith(prefix)
        ? workKey.substring(prefix.length)
        : workKey;
  }
}

/// 作品卡片（列表/搜索/推荐的最小单元）。
class WorkCard {
  final String sourceKey;
  final String workId;
  final String title;
  final String? posterUrl;
  final String? remarks; // “更新至第 N 集 / HD / 蓝光”等，做角标
  final String? year;
  final String? area;
  final String? genre;
  final String? score;

  const WorkCard({
    required this.sourceKey,
    required this.workId,
    required this.title,
    this.posterUrl,
    this.remarks,
    this.year,
    this.area,
    this.genre,
    this.score,
  });

  String get workKey => SourceDef.workKey(sourceKey, workId);
}

/// 播放线路（源内多线路，`vod_play_from` $$$ 归一）。
class PlayLine {
  final String lineId;
  final String name;
  final List<Episode> episodes;

  const PlayLine({required this.lineId, required this.name, required this.episodes});
}

/// 选集。序号规则三端统一前导零（规范 6.6），展示由 UI 层处理。
class Episode {
  final int index;
  final String name;
  final String url;

  const Episode({required this.index, required this.name, required this.url});
}

/// 作品详情（ac=detail / Spider detailContent 归一）。
class WorkDetail {
  final WorkCard card;
  final String? actor;
  final String? director;
  final String? content;
  final List<PlayLine> lines;

  const WorkDetail({
    required this.card,
    this.actor,
    this.director,
    this.content,
    required this.lines,
  });
}

/// 清晰度轨。名称使用规范锁死口径：自动/流畅/标清/高清/超清/蓝光（docs/07 §4.4）。
/// docs/13 B3：v0.1 占位 —— 适配器尚未填充 [PlayCandidate.qualities]，
/// v0.2 由适配器按线路名/扩展名归类产出真实清晰度轨。
class QualityTrack {
  final String name;
  final String url;

  const QualityTrack({required this.name, required this.url});
}

/// 字幕轨（内封轨道或外挂 srt/ass）。
class SubtitleTrack {
  final String name;
  final String? url; // 内封轨为 null，由播放器内核选择
  final bool isExternal;

  const SubtitleTrack({required this.name, this.url, this.isExternal = false});
}

/// 单集播放候选（resolve 的产物）。
class PlayCandidate {
  final String url;
  final List<QualityTrack> qualities;
  final List<SubtitleTrack> subtitles;
  final Map<String, String> headers;

  /// 地址为网页/需嗅探解析时为 true —— 按合规基线默认过滤并计数提示。
  final bool needsParse;

  const PlayCandidate({
    required this.url,
    this.qualities = const [],
    this.subtitles = const [],
    this.headers = const {},
    this.needsParse = false,
  });
}

/// 观看记录（断点续播唯一事实源；阈值语义见 docs/07 §4.5）。
class PlayRecord {
  final String workKey;
  final String sourceKey;
  final int episodeIndex;
  final int positionSec;
  final int durationSec;
  final DateTime updatedAt;

  /// 本次使用的线路（P05：线路记忆）。
  final String? lineId;

  const PlayRecord({
    required this.workKey,
    required this.sourceKey,
    required this.episodeIndex,
    required this.positionSec,
    required this.durationSec,
    required this.updatedAt,
    this.lineId,
  });

  double get progress {
    if (durationSec <= 0) return 0;
    final p = positionSec / durationSec;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  /// ≥90% 视为已看完，自动移出「继续观看」（docs/07 §4.5 锁死阈值）。
  bool get isFinished => progress >= 0.9;

  /// <5% 不生成续播记录（误点不污染继续观看轨道）。
  bool get shouldRecord => progress >= 0.05;
}

/// 收藏（含作品快照，源失效后「我的」仍完整）。
class Favorite {
  final String workKey;
  final String folderId;
  final WorkCard snapshot;
  final DateTime createdAt;

  const Favorite({
    required this.workKey,
    required this.folderId,
    required this.snapshot,
    required this.createdAt,
  });
}

/// 直播频道组（TVBox `lives[]` 归一）。
class LiveGroup {
  final String name;
  final String url; // m3u / txt / json 频道表地址
  final String? epg; // 模板：{name} {date}
  final String? logo;

  const LiveGroup({required this.name, required this.url, this.epg, this.logo});
}

/// 多仓库条目（storeHouse，docs/04 §6.1）。
class WarehouseEntry {
  final String name;
  final String url;

  const WarehouseEntry({required this.name, required this.url});
}
