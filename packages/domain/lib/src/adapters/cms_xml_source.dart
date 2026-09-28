import 'package:xml/xml.dart';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../net/http_fetch.dart';
import 'cms_json_source.dart';

/// 苹果CMS XML 适配器（type=0；docs/04 §5.3，实测 `<rss version="5.1">` 结构）。
///
/// 端点约定：列表/搜索/详情统一走 `ac=videolist&at=xml`（V10 中 videolist 等价
/// detail，返回含 `<dl><dd flag>` 的全量数据，浏览页直接可播）；`class` 节点
/// 提供分类树。老式 `from` 属性与 `|` 行尾（V8/MaxCMS 遗留）在解析时兼容。
class CmsXmlSource implements VideoSource {
  @override
  final SourceDef def;
  final HttpFetch _http;

  CmsXmlSource({required this.def, HttpFetch? http})
      : _http = http ?? const IoHttpFetch(),
        assert(def.kind == SourceKind.cmsXml, 'def.kind 必须为 cmsXml');


  Uri get _base {
    final ep = def.endpoint;
    if (ep == null || ep.isEmpty) {
      throw const FetchException('cmsXml 源未配置 endpoint');
    }
    return Uri.parse(ep);
  }

  Uri _uri(Map<String, String> params) =>
      _base.replace(queryParameters: params);

  Future<XmlDocument> _getXml(Map<String, String> params) async {
    final result = await _http.get(
      _uri(params),
      headers: def.headers,
      timeout: Duration(seconds: def.timeoutSec ?? 12),
    );
    if (result.notModified) {
      throw const FetchException('缓存协商返回 304，但无缓存可用');
    }
    try {
      return XmlDocument.parse(result.body);
    } on XmlException catch (e) {
      throw FetchException('接口返回不是合法的 XML', cause: e.message);
    }
  }

  // ---------------- VideoSource ----------------

  @override
  Future<HomeFeed> home() async {
    final doc = await _getXml({'ac': 'list', 'at': 'xml', 'pg': '1'});
    return HomeFeed(recommend: _videosToCards(_videoNodes(doc)));
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async {
    final doc = await _getXml({
      'ac': 'list',
      'at': 'xml',
      if (query.typeId != null) 't': query.typeId!,
      'pg': '${query.page}',
      for (final e in query.filters.entries)
        if (_filterKeys.contains(e.key)) e.key: e.value,
    });
    return _pageOf(doc);
  }

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    final doc =
        await _getXml({'ac': 'videolist', 'at': 'xml', 'wd': keyword, 'pg': '$page'});
    return _pageOf(doc);
  }

  @override
  Future<WorkDetail> detail(String workId) async {
    final doc = await _getXml({'ac': 'videolist', 'at': 'xml', 'ids': workId});
    final video = _videoNodes(doc).firstOrNull;
    if (video == null) {
      throw FetchException('未找到影片（ids=$workId）');
    }
    return WorkDetail(
      card: _videoToCard(video),
      actor: _text(video, 'actor'),
      director: _text(video, 'director'),
      content: _text(video, 'des'),
      lines: _linesOf(video),
    );
  }

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    final workDetail = await detail(request.workId);
    final lines = workDetail.lines;
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
      needsParse: !CmsJsonSource.isDirectMedia(episode.url),
    );
  }

  // ---------------- XML 解析 ----------------

  /// `<dl>` 内多个 `<dd flag="线路">集1$地址#集2$地址</dd>` → 线路树。
  /// 复用 cms_json 的 `$$$` 解析器：把 dd 按 flag 拼回 $$$ 形态。
  static List<PlayLine> linesOf(XmlElement video) => _linesOf(video);

  static List<PlayLine> _linesOf(XmlElement video) {
    final dls = video.findElements('dl');
    if (dls.isEmpty) return const [];
    final flags = <String>[];
    final urlParts = <String>[];
    for (final dd in dls.first.findElements('dd')) {
      final flag = dd.getAttribute('flag') ?? dd.getAttribute('from') ?? '';
      var content = dd.innerText;
      // V8/MaxCMS 遗留：行尾以 | 分隔的多集
      content = content.replaceAll('|', '#');
      flags.add(flag);
      urlParts.add(content);
    }
    if (flags.isEmpty) return const [];
    return CmsJsonSource.parseLines(
      from: flags.join(r'$$$'),
      urls: urlParts.join(r'$$$'),
    );
  }

  static Iterable<XmlElement> _videoNodes(XmlDocument doc) =>
      doc.findAllElements('video');

  static XmlElement? _listNode(XmlDocument doc) {
    final lists = doc.findAllElements('list');
    return lists.isEmpty ? null : lists.first;
  }

  PageResult<WorkCard> _pageOf(XmlDocument doc) {
    final list = _listNode(doc);
    return PageResult(
      items: _videosToCards(_videoNodes(doc)),
      page: int.tryParse(list?.getAttribute('page') ?? '') ?? 1,
      pageCount: int.tryParse(list?.getAttribute('pagecount') ?? ''),
      total: int.tryParse(list?.getAttribute('recordcount') ?? ''),
    );
  }

  List<WorkCard> _videosToCards(Iterable<XmlElement> videos) =>
      [for (final v in videos) _videoToCard(v)];

  WorkCard _videoToCard(XmlElement v) {
    final workId = _text(v, 'id') ?? '';
    if (workId.isEmpty) {
      throw const FetchException('接口返回的作品缺少 <id>');
    }
    return WorkCard(
      sourceKey: def.key,
      workId: workId,
      title: _text(v, 'name') ?? '',
      posterUrl: _text(v, 'pic'),
      remarks: _text(v, 'note'),
      year: _text(v, 'year'),
      area: _text(v, 'area'),
      genre: _text(v, 'type'),
      score: _text(v, 'score'),
    );
  }

  static String? _text(XmlElement parent, String tag) {
    final nodes = parent.findElements(tag);
    if (nodes.isEmpty) return null;
    final value = nodes.first.innerText.trim();
    return value.isEmpty ? null : value;
  }

  /// 分类树（`<class><ty id="6">子类1</ty></class>`）—— 供分类页筛选使用。
  static Map<String, String> classOf(XmlDocument doc) => {
        for (final ty in doc.findAllElements('ty'))
          if (ty.getAttribute('id') != null)
            ty.getAttribute('id')!: ty.innerText.trim(),
      };

  static const _filterKeys = {'year', 'isend', 'h'};
}
