import '../contracts/video_source.dart';
import '../models/models.dart';
import '../search/search_engine.dart';

/// 跨源同片候选（换源的数据源）。
class AltSource {
  final SourceDef def;
  final WorkCard card;

  const AltSource({required this.def, required this.card});
}

/// 详情/换源服务（docs/09 M2-2）。
///
/// 跨源同片匹配：以标题（去空白）为主指纹、年份一致者优先；
/// 聚合搜索的渐进结果中筛选出「其他源」的同一部影片。
class DetailService {
  final List<VideoSource> sources;
  final int concurrency;
  final Duration timeout;

  DetailService({
    required this.sources,
    this.concurrency = 8,
    this.timeout = const Duration(seconds: 8),
  });

  /// 找同片的其他源（排除原源）。[year] 传入时优先精确匹配年份，
  /// 无年份一致的候选时回退为仅标题匹配。
  Future<List<AltSource>> findAltSources({
    required SourceDef origin,
    required WorkCard card,
  }) async {
    if (card.title.trim().isEmpty) return const [];
    final engine = SearchEngine(
      sources: sources.where((s) => s.def.key != origin.key).toList(),
      concurrency: concurrency,
      timeout: timeout,
    );
    final updates = await engine.searchAll(card.title).toList();
    final cards = <WorkCard>[
      for (final u in updates)
        if (u is SearchSourceDone) ...u.items,
    ];
    final normTitle = SearchEngine.normalizeTitle(card.title);
    final sameTitle = cards
        .where((c) => SearchEngine.normalizeTitle(c.title) == normTitle)
        .toList();
    if (sameTitle.isEmpty) return const [];

    final sameYear = sameTitle
        .where((c) => card.year != null && c.year == card.year)
        .toList();
    final picked = sameYear.isNotEmpty ? sameYear : sameTitle;

    final defByKey = {for (final s in sources) s.def.key: s.def};
    return [
      for (final c in picked)
        if (defByKey[c.sourceKey] != null)
          AltSource(def: defByKey[c.sourceKey]!, card: c),
    ];
  }
}
