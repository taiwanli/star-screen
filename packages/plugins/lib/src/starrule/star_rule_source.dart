import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:star_domain/star_domain.dart';

import '../pdfh_engine.dart';

/// StarRule v1 源适配器（docs/17）—— 三端同一解释器。
///
/// - `html`：PdfhEngine 选择器链（纯 Dart，手机/桌面/TV 一致）
/// - `json` / `xml`：路径取值
/// - `cms`：内嵌苹果 CMS 协议（与 CmsJsonSource 同契约）
///
/// 不做网页嗅探：`needsParse` 一律上抛，由合规层过滤。
class StarRuleSource implements VideoSource {
  @override
  final SourceDef def;
  final StarRule rule;
  final HttpFetch _http;

  StarRuleSource({required this.def, required this.rule, HttpFetch? http})
      : _http = http ?? const IoHttpFetch(),
        assert(def.kind == SourceKind.starRule, 'def.kind 必须为 starRule');

  /// 从 SourceDef.extRaw（规则原文）构造。
  static StarRuleSource fromDef(SourceDef def, {HttpFetch? http}) {
    final raw = def.extRaw;
    if (raw == null || raw.isEmpty) {
      throw FetchException('StarRule 源缺少规则原文（ext）');
    }
    final parsed = StarRuleParser.parse(raw, baseUrl: Uri.tryParse(def.endpoint ?? ''));
    return StarRuleSource(def: def, rule: parsed.rule, http: http);
  }

  Map<String, String> get _headers => rule.site.effectiveHeaders();

  Duration get _timeout => Duration(seconds: rule.site.timeoutSec);

  Uri _abs(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Uri.parse(pathOrUrl);
    }
    final host = rule.site.host;
    if (pathOrUrl.startsWith('/')) return Uri.parse('$host$pathOrUrl');
    return Uri.parse('$host/$pathOrUrl');
  }

  /// 模板展开：占位符见 docs/17 §4.4。
  String _expand(
    String template, {
    String? cateId,
    String? cateName,
    int? page,
    String? vid,
    String? wd,
    String? playUrl,
    String? lineId,
    Map<String, String> filters = const {},
  }) {
    var s = template;
    s = s.replaceAll('{host}', rule.site.host);
    if (cateId != null) s = s.replaceAll('{cateId}', Uri.encodeComponent(cateId));
    if (cateName != null) s = s.replaceAll('{cateName}', Uri.encodeComponent(cateName));
    if (page != null) s = s.replaceAll('{catePg}', '$page');
    if (vid != null) s = s.replaceAll('{vid}', Uri.encodeComponent(vid));
    if (wd != null) s = s.replaceAll('{wd}', Uri.encodeComponent(wd));
    if (playUrl != null) s = s.replaceAll('{playUrl}', playUrl);
    if (lineId != null) s = s.replaceAll('{lineId}', lineId);
    filters.forEach((k, v) {
      s = s.replaceAll('{filter_$k}', Uri.encodeComponent(v));
    });
    return s;
  }

  Future<String> _fetchText(Uri uri) async {
    final res = await _http.get(uri, headers: _headers, timeout: _timeout);
    if (res.notModified) {
      throw FetchException('缓存协商 304，但无缓存可用');
    }
    return res.body;
  }

  // ---------------- 选择器求值 ----------------

  List<dynamic> _selectList(dynamic root, String sel, StarSourceType type) {
    switch (type) {
      case StarSourceType.html:
        if (root is! Element && root is! Document) return const [];
        final el = root is Document ? root.documentElement : root as Element;
        if (el == null) return const [];
        return PdfhEngine.pdfaIn(el, sel);
      case StarSourceType.json:
      case StarSourceType.cms:
        final path = sel.startsWith('json:') ? sel.substring(5) : sel;
        final v = _jsonPath(root, path);
        if (v is List) return v;
        return v == null ? const [] : [v];
      case StarSourceType.xml:
        return const []; // XML 列表见 _xmlList
    }
  }

  String? _selectValue(dynamic node, StarField field, StarSourceType type) {
    String? raw;
    switch (type) {
      case StarSourceType.html:
        if (node is Element) {
          raw = PdfhEngine.pdfh(node, field.sel);
        }
      case StarSourceType.json:
      case StarSourceType.cms:
        final path = field.sel.startsWith('json:')
            ? field.sel.substring(5)
            : field.sel.startsWith('cms:')
                ? field.sel.substring(4)
                : field.sel;
        // 字段在条目节点内相对取值
        final v = path == '.' || path.isEmpty ? node : _jsonPath(node, path);
        raw = v?.toString();
      case StarSourceType.xml:
        raw = _xmlValue(node, field.sel);
    }
    return _post(raw, field);
  }

  String? _post(String? raw, StarField field) {
    if (raw == null) return null;
    var s = raw;
    if (field.trim) s = s.trim();
    if (field.regex != null && field.regex!.isNotEmpty) {
      final re = RegExp(field.regex!);
      final m = re.firstMatch(s);
      if (m == null) {
        s = field.fallback ?? '';
      } else if (field.replace != null && field.replace!.contains(r'$')) {
        // replace 为正则替换模板（$1/$2…）
        s = field.replace!.replaceAllMapped(RegExp(r'\$(\d)'), (mm) {
          final idx = int.parse(mm.group(1)!);
          return m.group(idx) ?? '';
        });
      } else {
        s = m.groupCount >= 1 ? (m.group(1) ?? '') : m.group(0)!;
        if (field.replace != null && field.replace!.isNotEmpty) {
          s = s.replaceAll(field.replace!, '');
        }
      }
    } else if (field.replace != null && field.replace!.isNotEmpty) {
      // 无 regex：replace 为要剥离的字面量
      s = s.replaceAll(field.replace!, '');
    }
    if (s.isEmpty && field.fallback != null) s = field.fallback!;
    return s;
  }

  dynamic _jsonPath(dynamic root, String path) {
    if (root == null) return null;
    var cur = root;
    for (var seg in path.split(RegExp(r'[>.]'))) {
      seg = seg.trim();
      if (seg.isEmpty) continue;
      if (cur is List) {
        final idx = int.tryParse(seg);
        if (idx == null || idx < 0 || idx >= cur.length) return null;
        cur = cur[idx];
        continue;
      }
      if (cur is Map) {
        cur = cur[seg];
        continue;
      }
      return null;
    }
    return cur;
  }

  List<Element> _htmlList(Element? root, String sel) {
    if (root == null) return const [];
    return PdfhEngine.pdfaIn(root, sel);
  }

  String? _xmlValue(dynamic node, String sel) {
    // v1 简化：非 HTML 节点直接字符串化；完整 XPath 求值留给 P1。
    if (node == null) return null;
    return node.toString();
  }

  // ---------------- 条目归一 ----------------

  WorkCard _card(dynamic node, StarItemMap map) {
    final title = _selectValue(node, map.title, rule.sourceType) ?? '未知标题';
    var id = _selectValue(node, map.id, rule.sourceType) ?? '';
    if (id.isEmpty) id = title;
    if (map.idIsUrl || id.startsWith('http')) {
      // 详情 URL 作为 id（去掉 host 前缀以便 detail 复用）
      id = _stripHost(id);
    }
    String? cover = map.cover == null ? null : _selectValue(node, map.cover!, rule.sourceType);
    if (cover != null && cover.isNotEmpty && !cover.startsWith('http')) {
      cover = _abs(cover).toString();
    }
    final badge = map.badge == null ? null : _selectValue(node, map.badge!, rule.sourceType);
    final year = map.year == null ? null : _selectValue(node, map.year!, rule.sourceType);
    return WorkCard(
      sourceKey: def.key,
      workId: id,
      title: title,
      posterUrl: (cover == null || cover.isEmpty) ? null : cover,
      remarks: (badge == null || badge.isEmpty) ? null : badge,
      year: (year == null || year.isEmpty) ? null : year,
    );
  }

  String _stripHost(String url) {
    final host = rule.site.host;
    if (url.startsWith(host)) {
      final rest = url.substring(host.length);
      return rest.isEmpty ? '/' : rest;
    }
    return url;
  }

  List<WorkCard> _cardsFromBody(String body, StarItemMap map) {
    final type = rule.sourceType;
    if (type == StarSourceType.json || type == StarSourceType.cms) {
      final doc = jsonDecode(body);
      final items = _selectList(doc, map.list.sel, type);
      return [for (final n in items) _card(n, map)];
    }
    if (type == StarSourceType.xml) {
      return const []; // 见 Xml 分支简化
    }
    final doc = html_parser.parse(body);
    final root = doc.documentElement;
    if (root == null) return const [];
    final nodes = _htmlList(root, map.list.sel);
    return [for (final n in nodes) _card(n, map)];
  }

  // ---------------- VideoSource ----------------

  bool get _isCms => rule.sourceType == StarSourceType.cms;

  /// 苹果 CMS JSON 协议（docs/04 §5 / docs/17 §6.4）。
  Future<Map<String, dynamic>> _cmsGet(Map<String, String> params) async {
    final base = rule.site.host;
    final uri = Uri.parse(base).replace(queryParameters: {
      ...Uri.parse(base).queryParameters,
      ...params,
    });
    final text = await _fetchText(uri);
    final doc = jsonDecode(text);
    if (doc is! Map<String, dynamic>) {
      throw FetchException('CMS 接口返回不是 JSON 对象');
    }
    final code = doc['code'];
    if (code is num && code != 1) {
      throw FetchException('CMS 接口异常（code=$code）');
    }
    return doc;
  }

  static List<Map<String, dynamic>> _cmsList(Map<String, dynamic> doc) {
    final list = doc['list'] ?? (doc['data'] is Map ? (doc['data'] as Map)['list'] : null);
    if (list is List) {
      return [for (final x in list) if (x is Map) Map<String, dynamic>.from(x)];
    }
    return const [];
  }

  WorkCard _cmsCard(Map<String, dynamic> v) {
    final id = (v['vod_id'] ?? v['id'] ?? '').toString();
    final title = (v['vod_name'] ?? v['name'] ?? id).toString();
    final pic = (v['vod_pic'] ?? v['pic'] ?? '').toString();
    final remarks = (v['vod_remarks'] ?? v['remarks'] ?? '').toString();
    final year = (v['vod_year'] ?? v['year'] ?? '').toString();
    return WorkCard(
      sourceKey: def.key,
      workId: id,
      title: title,
      posterUrl: pic.isEmpty ? null : pic,
      remarks: remarks.isEmpty ? null : remarks,
      year: year.isEmpty ? null : year,
    );
  }

  @override
  Future<HomeFeed> home() async {
    if (_isCms) {
      final doc = await _cmsGet({'ac': 'list', 'pg': '1'});
      return HomeFeed(recommend: [for (final v in _cmsList(doc)) _cmsCard(v)]);
    }
    final home = rule.home;
    final url = home?.url ?? rule.site.homeUrl;
    final body = await _fetchText(_abs(_expand(url)));
    final rec = home?.recommend;
    if (rec == null) return const HomeFeed(recommend: []);
    return HomeFeed(recommend: _cardsFromBody(body, rec));
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async {
    if (_isCms) {
      final doc = await _cmsGet({
        'ac': 'list',
        if (query.typeId != null) 't': query.typeId!,
        'pg': '${query.page}',
        for (final e in query.filters.entries) e.key: e.value,
      });
      final items = [for (final v in _cmsList(doc)) _cmsCard(v)];
      final pc = doc['pagecount'] ?? (doc['data'] is Map ? (doc['data'] as Map)['pagecount'] : null);
      return PageResult(
        items: items,
        page: query.page,
        pageCount: pc is num ? pc.toInt() : int.tryParse(pc?.toString() ?? ''),
      );
    }
    final cat = rule.category;
    if (cat == null) throw FetchException('该源未声明 category');
    final url = _expand(
      cat.url,
      cateId: query.typeId,
      page: query.page,
      filters: query.filters,
    );
    final body = await _fetchText(_abs(url));
    final items = _cardsFromBody(body, cat.items);
    return _pageOf(body, cat.items, items, query.page, urlTemplate: cat.url);
  }

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    if (_isCms) {
      final doc = await _cmsGet({
        'ac': 'detail',
        'wd': keyword,
        'pg': '$page',
      });
      final items = [for (final v in _cmsList(doc)) _cmsCard(v)];
      return PageResult(items: items, page: page);
    }
    final s = rule.search;
    if (s == null) throw FetchException('该源未声明 search');
    final url = _expand(s.url, wd: keyword, page: page);
    final body = await _fetchText(_abs(url));
    final items = _cardsFromBody(body, s.items);
    return _pageOf(body, s.items, items, page, urlTemplate: s.url);
  }

  /// 分页归一（docs/17 §5.2 hasMore 语义）。
  PageResult<WorkCard> _pageOf(
    String body,
    StarItemMap map,
    List<WorkCard> items,
    int page, {
    required String urlTemplate,
  }) {
    int? pageCount;
    final mode = map.hasMore; // auto | pageCount | none
    final hasPgPlaceholder = urlTemplate.contains('{catePg}');

    if (mode == 'none') {
      return PageResult(items: items, page: page, pageCount: page);
    }

    final pcField = map.pageCount;
    if (pcField != null) {
      String? v;
      if (rule.sourceType == StarSourceType.html) {
        final doc = html_parser.parse(body);
        v = doc.documentElement == null
            ? null
            : _selectValue(doc.documentElement, pcField, rule.sourceType);
      } else {
        final doc = jsonDecode(body);
        v = _selectValue(doc, pcField, rule.sourceType);
      }
      pageCount = int.tryParse((v ?? '').trim());
    }

    if (mode == 'pageCount') {
      // 显式用 pageCount；取不到则视为无更多
      return PageResult(
        items: items,
        page: page,
        pageCount: pageCount ?? page,
      );
    }

    // auto：list 非空即有下一页；模板无页码占位符则单页
    if (!hasPgPlaceholder) {
      return PageResult(items: items, page: page, pageCount: 1);
    }
    if (pageCount != null) {
      return PageResult(items: items, page: page, pageCount: pageCount);
    }
    return PageResult(items: items, page: page);
  }

  @override
  Future<WorkDetail> detail(String workId) async {
    if (_isCms) {
      final doc = await _cmsGet({'ac': 'detail', 'ids': workId});
      final list = _cmsList(doc);
      if (list.isEmpty) throw FetchException('未找到影片（ids=$workId）');
      final v = list.first;
      final card = _cmsCard(v);
      final lines = _splitCmsPlay(
        (v['vod_play_from'] ?? '').toString(),
        (v['vod_play_url'] ?? '').toString(),
      );
      String? s(Object? x) {
        final t = x?.toString().trim();
        return (t == null || t.isEmpty) ? null : t;
      }

      return WorkDetail(
        card: card,
        actor: s(v['vod_actor']),
        director: s(v['vod_director']),
        content: s(v['vod_content']),
        lines: lines,
      );
    }
    final d = rule.detail;
    if (d == null) throw FetchException('该源未声明 detail');
    final urlTpl = d.url;
    // 仅当 workId 已是路径/URL，或未声明 detail.url 时直接请求；
    // 否则走 {vid} 模板（避免 `123.html` 被误判为路径而丢掉模板）
    final idIsPath = workId.startsWith('/') ||
        workId.startsWith('http://') ||
        workId.startsWith('https://');
    late final String body;
    dynamic doc;
    if (urlTpl == null || urlTpl.isEmpty || idIsPath) {
      body = await _fetchText(_abs(workId));
    } else {
      // 模板自带扩展名时避免 `123.html` 叠成 `123.html.html`
      var vidVal = workId;
      if (RegExp(r'\{vid\}\.[A-Za-z0-9]+').hasMatch(urlTpl)) {
        vidVal = vidVal.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '');
      }
      final url = _expand(urlTpl, vid: vidVal);
      body = await _fetchText(_abs(url));
    }
    final type = rule.sourceType;
    if (type == StarSourceType.html) {
      final parsed = html_parser.parse(body);
      doc = parsed.documentElement;
    } else {
      doc = jsonDecode(body);
    }

    final card = WorkCard(
      sourceKey: def.key,
      workId: workId,
      title: d.title == null
          ? workId
          : (_selectValue(doc, d.title!, type) ?? workId),
      posterUrl: d.cover == null ? null : _selectValue(doc, d.cover!, type),
      remarks: d.remarks == null ? null : _selectValue(doc, d.remarks!, type),
      year: d.year == null ? null : _selectValue(doc, d.year!, type),
    );

    final lines = _parseLines(doc, d.lines, workId);
    return WorkDetail(
      card: card,
      actor: d.actor == null ? null : _selectValue(doc, d.actor!, type),
      director: d.director == null ? null : _selectValue(doc, d.director!, type),
      content: d.desc == null ? null : _selectValue(doc, d.desc!, type),
      lines: lines,
    );
  }

  List<PlayLine> _parseLines(dynamic doc, StarLines? lines, String workId) {
    if (lines == null) return const [];
    final type = rule.sourceType;

    // CMS 线路字段
    if (lines.fromField != null && lines.urlField != null) {
      final from = _selectValue(doc, lines.fromField!, type) ?? '';
      final urls = _selectValue(doc, lines.urlField!, type) ?? '';
      return _splitCmsPlay(from, urls);
    }

    if (lines.flat || lines.list == null) {
      final eps = _parseEpisodes(doc, lines.episodes, lineIndex: 0);
      return [
        PlayLine(lineId: 'main', name: '主线', episodes: eps),
      ];
    }

    // 线路节点列表
    List<dynamic> lineNodes;
    if (type == StarSourceType.html && doc is Element) {
      lineNodes = _htmlList(doc, lines.list!.sel);
    } else {
      lineNodes = _selectList(doc, lines.list!.sel, type);
    }

    final out = <PlayLine>[];
    for (var i = 0; i < lineNodes.length; i++) {
      final node = lineNodes[i];
      final name = lines.name == null
          ? '线路${i + 1}'
          : (_selectValue(node, lines.name!, type) ?? '线路${i + 1}');
      final eps = _parseEpisodes(
        type == StarSourceType.html && doc is Element ? doc : node,
        lines.episodes,
        lineIndex: i,
      );
      out.add(PlayLine(lineId: 'L$i', name: name, episodes: eps));
    }
    return out;
  }

  List<Episode> _parseEpisodes(
    dynamic root,
    StarEpisodes? eps, {
    required int lineIndex,
  }) {
    if (eps == null) return const [];
    final type = rule.sourceType;
    var listSel = eps.list.sel.replaceAll('#line', '$lineIndex');

    List<dynamic> nodes;
    if (type == StarSourceType.html) {
      final el = root is Document
          ? root.documentElement
          : root is Element
              ? root
              : null;
      nodes = _htmlList(el, listSel);
    } else {
      nodes = _selectList(root, listSel, type);
    }

    final out = <Episode>[];
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final name = _selectValue(n, eps.name, type) ?? '${i + 1}';
      var url = _selectValue(n, eps.url, type) ?? '';
      if (url.isNotEmpty &&
          !url.startsWith('http') &&
          !url.startsWith('magnet') &&
          !url.startsWith('rtmp')) {
        url = _abs(url).toString();
      }
      out.add(Episode(index: i, name: name, url: url));
    }
    return out;
  }

  List<PlayLine> _splitCmsPlay(String from, String urls) {
    // CMS 契约（docs/04 §5.4）：from/urls 用 `$$$` 分线路，`#` 分集，`集名$地址`。
    // 兼容误写的 `###`（部分配置）。
    List<String> splitLines(String s) {
      if (s.contains('###')) return s.split('###');
      return s.split(r'$$$');
    }

    final froms = splitLines(from);
    final groups = splitLines(urls);
    final out = <PlayLine>[];
    for (var i = 0; i < froms.length && i < groups.length; i++) {
      final episodes = <Episode>[];
      final parts = groups[i].split('#');
      for (var j = 0; j < parts.length; j++) {
        final seg = parts[j];
        if (seg.isEmpty) continue;
        final dollar = seg.indexOf(r'$');
        final name = dollar < 0 ? '${j + 1}' : seg.substring(0, dollar);
        final url = dollar < 0 ? seg : seg.substring(dollar + 1);
        episodes.add(Episode(index: episodes.length, name: name, url: url));
      }
      out.add(PlayLine(lineId: 'L$i', name: froms[i], episodes: episodes));
    }
    return out;
  }

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    // 重新解析选集树取目标集 URL（上游已调过 detail 时由缓存兜底）
    final detailResult = await detail(request.workId);
    PlayLine? line;
    if (request.lineId != null) {
      for (final l in detailResult.lines) {
        if (l.lineId == request.lineId) {
          line = l;
          break;
        }
      }
    }
    line ??= detailResult.lines.isNotEmpty ? detailResult.lines.first : null;
    if (line == null || line.episodes.isEmpty) {
      throw FetchException('无可用选集');
    }
    final idx = request.episodeIndex;
    if (idx < 0 || idx >= line.episodes.length) {
      throw FetchException('选集下标越界：$idx');
    }
    final ep = line.episodes[idx];
    var playUrl = ep.url;

    final play = rule.play;
    if (play != null && play.url.isNotEmpty && play.url != '{playUrl}') {
      playUrl = _expand(
        play.url,
        vid: request.workId,
        playUrl: ep.url,
        lineId: request.lineId,
      );
      if (!playUrl.startsWith('http')) {
        playUrl = _abs(playUrl).toString();
      }
    }

    final parseMode = play?.parseMode ?? 'auto';
    var needsParse = false;
    if (parseMode == '1' || parseMode == 'true') {
      needsParse = true;
    } else if (parseMode == 'auto') {
      final lower = playUrl.toLowerCase();
      final isDirect = lower.contains('.m3u8') ||
          lower.contains('.mp4') ||
          lower.contains('.flv') ||
          lower.contains('.mkv') ||
          lower.contains('.ts') ||
          lower.startsWith('rtmp') ||
          lower.startsWith('rtsp');
      needsParse = !isDirect && playUrl.startsWith('http');
    }

    // 广告过滤
    for (final ad in play?.filterAds ?? const <String>[]) {
      if (ad.isNotEmpty && playUrl.contains(ad)) {
        throw FetchException('播放地址命中广告规则，已过滤');
      }
    }

    return PlayCandidate(
      url: playUrl,
      headers: {
        ..._headers,
        ...?play?.headers,
      },
      needsParse: needsParse,
    );
  }
}
