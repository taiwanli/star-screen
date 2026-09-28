import '../models/models.dart';

/// 统一源契约 —— 所有源适配器的唯一抽象（docs/05 §5.1）。
///
/// 上游（catalog/search/detail/playback）只见此契约，不知道源的真实形态；
/// 适配器负责把异构数据清洗归一（标题去噪、海报兜底、备注规范化）。
abstract interface class VideoSource {
  SourceDef get def;

  /// 首页推荐流。
  Future<HomeFeed> home();

  /// 分类 + 筛选 + 分页。
  Future<PageResult<WorkCard>> category(CategoryQuery query);

  /// 搜索（分页）。失败由上层聚合器捕获并按源粒度跳过，不阻塞其他源。
  Future<PageResult<WorkCard>> search(String keyword, {int page});

  /// 详情：元信息 + 多线路 + 每线路选集。
  Future<WorkDetail> detail(String workId);

  /// 解析单集播放地址 + 清晰度轨 + 字幕轨。
  Future<PlayCandidate> resolve(PlayRequest request);
}

/// 首页推荐流。
class HomeFeed {
  final List<WorkCard> recommend;

  const HomeFeed({required this.recommend});
}

/// 分类查询。筛选条件由源的 caps 声明（docs/05 §3）。
class CategoryQuery {
  final String? typeId;
  final int page;
  final Map<String, String> filters;

  const CategoryQuery({this.typeId, this.page = 1, this.filters = const {}});
}

/// 分页结果。`pageCount` 缺失时以 items 是否非空判断 hasMore
///（实测部分源搜索响应缺 total —— docs/04 §5.1 容错清单）。
class PageResult<T> {
  final List<T> items;
  final int page;
  final int? pageCount;
  final int? total;

  const PageResult({
    required this.items,
    required this.page,
    this.pageCount,
    this.total,
  });

  bool get hasMore =>
      pageCount == null ? items.isNotEmpty : page < pageCount!;
}

/// 播放请求。
class PlayRequest {
  final String workId;
  final int episodeIndex;
  final String? lineId;
  final String? qualityName;

  const PlayRequest({
    required this.workId,
    required this.episodeIndex,
    this.lineId,
    this.qualityName,
  });
}
