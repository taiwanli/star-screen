import '../models/models.dart';

/// 解析报告 —— 导入向导 UI 的数据来源（docs/05 §5「输出导入报告」）。
///
/// 用户必须能看到：哪些源成功注册、哪些源不支持及原因、解析中发现的问题。
class ParseReport {
  final List<WarehouseEntry> warehouses;
  final List<SourceDef> sources;
  final List<LiveGroup> lives;
  final List<ParseIssue> issues;

  /// 单仓配置的全局 spider 原文（仅记录引用，永不下载执行 —— docs/05 §10）。
  final String? spiderRef;

  /// 广告 URL/域名过滤串（TVBox `ads`，FongMi/TV 同构）。
  final List<String> adFilters;

  /// 播放 flag 白名单（VIP 线路标识，`flags`）。
  final List<String> playFlags;

  /// 配置指定的首页源 key（`home`）。
  final String? homeSiteKey;

  const ParseReport({
    required this.warehouses,
    required this.sources,
    required this.lives,
    required this.issues,
    this.spiderRef,
    this.adFilters = const [],
    this.playFlags = const [],
    this.homeSiteKey,
  });

  /// 是否为多仓文档（仅包含仓库列表，需对每个子仓递归解析）。
  bool get isWarehouseList => sources.isEmpty && warehouses.isNotEmpty;

  Iterable<SourceDef> sourcesOf(SourceKind kind) =>
      sources.where((s) => s.kind == kind);

  int countOf(SourceKind kind) => sourcesOf(kind).length;
}

/// 解析过程中发现的问题（非致命，逐条呈现给用户）。
class ParseIssue {
  final String message;
  final String? siteKey;

  const ParseIssue(this.message, {this.siteKey});

  @override
  String toString() =>
      siteKey == null ? message : '$message（站点：$siteKey）';
}
