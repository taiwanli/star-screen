import 'dart:convert';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../net/http_fetch.dart';
import '../playback/play_url_filter.dart';
import '../util/ttl_cache.dart';
import 'line_names.dart';

/// 苹果CMS JSON 适配器（docs/05 §6.1；规范依据 docs/04 §5，实测 bfzy/suoni）。
///
/// AppYsV2（`/api.php/v1.vod`）归入本适配器的 [CmsVariant.appysV2] 分支：
/// 响应的列表可能位于 `data.list` / `data`。
class CmsJsonSource implements VideoSource {
  @override
  final SourceDef def;
  final HttpFetch _http;

  /// 同实例内 JSON 响应 TTL 缓存（首页/列表 3 分钟，详情 10 分钟）。
  final TtlCache<Map<String, dynamic>> _cache =
      TtlCache(ttl: const Duration(minutes: 3), maxEntries: 128);

  CmsJsonSource({required this.def, HttpFetch? http})
      : _http = http ?? const IoHttpFetch(),
        assert(def.kind == SourceKind.cmsJson, 'def.kind 必须为 cmsJson');

  Uri get _base {
    final ep = def.endpoint;
    if (ep == null || ep.isEmpty) {
      throw const FetchException('cmsJson 源未配置 endpoint');
    }
    return Uri.parse(ep);
  }

  Uri _uri(Map<String, String> params) =>
      _base.replace(queryParameters: params);

  Future<Map<String, dynamic>> _getJson(
    Map<String, String> params, {
    int? timeoutSec,
    bool cache = true,
  }) async {
    final uri = _uri(params);
    final key = uri.toString();
    if (cache) {
      final hit = _cache.get(key);
      if (hit != null) return hit;
    }
    final result = await _http.get(
      uri,
      headers: def.headers,
      timeout: Duration(seconds: timeoutSec ?? def.timeoutSec ?? 12),
    );
    if (result.notModified) {
      throw const FetchException('缓存协商返回 304，但无缓存可用');
    }
    final decoded = jsonDecode(result.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FetchException('接口返回不是 JSON 对象');
    }
    if (cache) _cache.set(key, decoded);
    return decoded;
  }

  /// CMS 的 code!=1 与网络层错误同等对待（docs/04 §5.1）。
  void _assertOk(Map<String, dynamic> doc) {
    final code = doc['code'];
    if (code is! num || code != 1) {
      throw FetchException('接口返回异常（code=${code ?? '缺失'}）');
    }
  }

  // ---------------- VideoSource ----------------

  @override
  Future<HomeFeed> home() async {
    final doc = await _getJson({'ac': 'list', 'pg': '1'});
    _assertOk(doc);
    return HomeFeed(recommend: _cardsOf(doc));
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async {
    final params = <String, String>{
      'ac': 'list',
      if (query.typeId != null) 't': query.typeId!,
      'pg': '${query.page}',
      // 仅透传 CMS 官方支持的筛选参数（docs/04 §5.1）
      for (final e in query.filters.entries)
        if (_filterKeys.contains(e.key)) e.key: e.value,
    };
    final doc = await _getJson(params);
    _assertOk(doc);
    return _pageOf(doc);
  }

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    final doc = await _getJson({
      'ac': 'detail',
      'wd': keyword,
      'pg': '$page',
    });
    _assertOk(doc);
    // 实测容错：部分源搜索响应缺 total（docs/04 §5.1 坑清单）
    return _pageOf(doc);
  }

  @override
  Future<WorkDetail> detail(String workId) async {
    final doc = await _getJson({'ac': 'detail', 'ids': workId});
    _assertOk(doc);
    final list = _extractList(doc);
    if (list.isEmpty) {
      throw FetchException('未找到影片（ids=$workId）');
    }
    final v = list.first;
    final card = _card(v);
    final actor = v['vod_actor']?.toString();
    final director = v['vod_director']?.toString();
    final content = _stripHtml(v['vod_content']?.toString());
    return WorkDetail(
      card: card,
      actor: (actor == null || actor.isEmpty) ? null : actor,
      director: (director == null || director.isEmpty) ? null : director,
      content: (content == null || content.isEmpty) ? null : content,
      lines: parseLines(
        from: v['vod_play_from']?.toString() ?? '',
        urls: v['vod_play_url']?.toString() ?? '',
      ),
    );
  }

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    final workDetail = await detail(request.workId);
    final lines = workDetail.lines
        .where((l) => PlayUrlFilter.lineAllowed(l.lineId) || PlayUrlFilter.lineAllowed(l.name))
        .toList();
    final PlayLine? line = request.lineId == null
        ? lines.firstOrNull
        : lines.where((l) => l.lineId == request.lineId).firstOrNull;
    if (line == null || line.episodes.isEmpty) {
      throw const FetchException('该影片没有可用播放线路');
    }
    final index = request.episodeIndex.clamp(0, line.episodes.length - 1);
    final episode = line.episodes[index];
    return PlayCandidate(
      url: episode.url,
      needsParse: !isDirectMedia(episode.url),
    );
  }

  // ---------------- 解析规则（docs/04 §5.4，源码级约定） ----------------

  /// `vod_play_from`（$$$ / 兼容 list 模式的 ,）× `vod_play_url`（$$$ → # → $）。
  static List<PlayLine> parseLines({
    required String from,
    required String urls,
  }) {
    if (from.isEmpty || urls.isEmpty) return const [];
    var fromParts = from.split(r'$$$');
    var urlParts = urls.split(r'$$$');
    // 兼容个别站点在 detail 中也使用 , 分隔线路
    if (fromParts.length == 1 &&
        urlParts.length == 1 &&
        from.contains(',') &&
        urls.contains(',')) {
      fromParts = from.split(',');
      urlParts = urls.split(',');
    }

    final lines = <PlayLine>[];
    final n = fromParts.length < urlParts.length ? fromParts.length : urlParts.length;
    for (var i = 0; i < n; i++) {
      final rawName = fromParts[i].trim();
      final episodes = <Episode>[];
      final parts = urlParts[i].split('#');
      for (var j = 0; j < parts.length; j++) {
        final part = parts[j].trim();
        if (part.isEmpty) continue;
        final dollar = part.indexOf(r'$');
        final name =
            dollar < 0 ? part : part.substring(0, dollar).trim();
        final url = dollar < 0 ? '' : part.substring(dollar + 1).trim();
        if (url.isEmpty) continue;
        episodes.add(Episode(
          index: j,
          name: name.isEmpty ? '第${j + 1}集' : name,
          url: url,
        ));
      }
      if (episodes.isEmpty) continue;
      lines.add(PlayLine(
        lineId: rawName,
        name: LineNames.display(rawName),
        episodes: episodes,
      ));
    }
    return lines;
  }

  /// 是否直连媒体地址。网页地址等需解析 —— 按合规基线默认过滤（docs/05 §10）。
  static bool isDirectMedia(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') ||
        lower.contains('.mp4') ||
        lower.contains('.flv') ||
        lower.contains('.ts');
  }

  static String? _stripHtml(String? text) {
    if (text == null || text.isEmpty) return null;
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ---------------- 响应归一 ----------------

  /// CMS list / AppYsV2 的列表抽取（list / data.list / data）。
  static List<Map<String, dynamic>> _extractList(Map<String, dynamic> doc) {
    final direct = doc['list'];
    if (direct is List) return _castMaps(direct);
    final data = doc['data'];
    if (data is Map<String, dynamic> && data['list'] is List) {
      return _castMaps(data['list'] as List);
    }
    if (data is List) return _castMaps(data);
    return const [];
  }

  static List<Map<String, dynamic>> _castMaps(List<Object?> raw) => [
        for (final item in raw)
          if (item is Map<String, dynamic>) item,
      ];

  List<WorkCard> _cardsOf(Map<String, dynamic> doc) =>
      [for (final v in _extractList(doc)) _card(v)];

  PageResult<WorkCard> _pageOf(Map<String, dynamic> doc) => PageResult(
        items: _cardsOf(doc),
        page: _asInt(doc['page']) ?? 1,
        // pagecount=0 / total 缺失按容错处理（docs/04 §5.1）
        pageCount: _asInt(doc['pagecount']),
        total: _asInt(doc['total']),
      );

  WorkCard _card(Map<String, dynamic> v) => CmsJsonSource.cardFrom(v, sourceKey: def.key);

  /// VOD 字段对象 → 归一卡片（CMS JSON 与 drpy js 片段结果共用，docs/04 §4.3）。
  static WorkCard cardFrom(Map<String, dynamic> v, {required String sourceKey}) {
    final workId = v['vod_id']?.toString() ?? '';
    if (workId.isEmpty) {
      throw const FetchException('接口返回的作品缺少 vod_id');
    }
    return WorkCard(
      sourceKey: sourceKey,
      workId: workId,
      title: v['vod_name']?.toString() ?? '',
      posterUrl: _absoluteUrl(_emptyToNull(v['vod_pic']?.toString())),
      remarks: _emptyToNull(v['vod_remarks']?.toString()),
      year: _emptyToNull(v['vod_year']?.toString()),
      area: _emptyToNull(v['vod_area']?.toString()),
      genre: _emptyToNull(v['vod_class']?.toString() ?? v['type_name']?.toString()),
      score: _emptyToNull(v['vod_score']?.toString()),
    );
  }

  static String? _absoluteUrl(String? url) {
    if (url == null) return null;
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }

  static String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static const _filterKeys = {'year', 'isend', 'h'};
}
