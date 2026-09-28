import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:star_domain/star_domain.dart';

import 'drpy_host.dart';
import 'drpy_js_runtime.dart';
import 'drpy_rule_parser.dart';
import 'pdfh_engine.dart';

/// drpy 源执行器（docs/09 M3-4）：rule 模板 + js: 内联片段。
///
/// - 纯模板源：PdfhEngine 原生求值，零 JS 引擎、三端可用；
/// - 含 js: 片段的源：经注入的 [JsRuntimeFactory]（QuickJS）执行 ——
///   [DrpyHost] 提供 req/pdfa/pdfh/pd/setResult 注入 API 与限额熔断；
///   工厂未注入时运行期抛出明确提示（绝不静默失败）。
///
/// 二级深解析（docs/04 §4.3 rule 契约）：字符串形态（`*;标题;图片;描述;内容;线路;剧集容器;;集标题;集链接`，
/// `#id`/`:eq(#id)` 按线路下标展开）与对象形态（{title,img,desc,content,tabs,lists}）；
/// play_parse + lazy js 片段解析播放地址；星映不做网页嗅探 —— 非直链一律
/// needsParse 标记（docs/04 §5.4 合规基线）。
class DrpyTemplateSource implements VideoSource {
  final SourceDef def;
  final HttpFetch http;

  /// QuickJS 工厂（端上注入；null → 仅支持纯模板源）。
  final JsRuntimeFactory? jsFactory;

  DrpyRule? _rule;
  String? _ruleError;
  JsRuntime? _js;
  DrpyHost? _host;

  DrpyTemplateSource({required this.def, HttpFetch? http, this.jsFactory})
      : http = http ?? const IoHttpFetch(),
        assert(def.kind == SourceKind.drpyJs, 'def.kind 必须为 drpyJs');

  /// 释放 js 运行时（宿主端关闭/重建缓存时调用；纯模板源为空操作）。
  void disposeRuntime() {
    _js?.dispose();
    _js = null;
    _host = null;
    _rule = null;
    _ruleError = null;
  }

  Future<DrpyRule> _ensureRule() async {
    final cached = _rule;
    if (cached != null) return cached;
    if (_ruleError != null) throw StateError(_ruleError!);
    final srcUrl = def.sourceUrl;
    if (srcUrl == null) {
      _ruleError = 'drpy 源缺少源文件地址（ext）';
      throw StateError(_ruleError!);
    }
    try {
      final res = await http.get(Uri.parse(srcUrl),
          headers: def.headers, timeout: const Duration(seconds: 12));
      final rule = DrpyRuleParser.parse(res.body);
      if (rule == null) {
        _ruleError = 'drpy 源文件解析失败：未找到 rule 对象';
        throw StateError(_ruleError!);
      }
      _rule = rule;
      return rule;
    } on Object catch (e) {
      _ruleError ??= e.toString();
      throw StateError(_ruleError!);
    }
  }

  /// js: 片段宿主（惰性创建；纯模板源或未接入引擎时返回 null）。
  /// 仅当后续真正执行 js: 字段时才 [_ensureHost]（会因缺引擎抛出）。
  Future<DrpyHost?> _maybeHost(DrpyRule rule) async {
    if (jsFactory == null || rule.isTemplateOnly) return null;
    return _ensureHost(rule);
  }

  Future<DrpyHost> _ensureHost(DrpyRule rule) async {
    final cached = _host;
    if (cached != null) return cached;
    if (jsFactory == null) {
      throw FetchException(
          '该源包含 js: 内联代码（${rule.firstJsField ?? 'js'}），需要 QuickJS 运行时，当前端未接入');
    }
    final rt = jsFactory!();
    _js = rt;
    final headers = {...def.headers};
    rule.mapField('headers')?.forEach((k, v) {
      if (v != null) headers[k] = v.toString();
    });
    final host = DrpyHost(
      runtime: rt,
      http: http,
      baseHeaders: headers,
      ruleHost: rule.host,
    );
    await host.install(rule);
    _host = host;
    return host;
  }

  Uri _pageUrl(DrpyRule rule, String path, {String? keyword, int page = 1}) {
    var p = path;
    if (keyword != null) p = p.replaceAll('**', keyword);
    p = p.replaceAll('fyclass', 'fyall').replaceAll('fypage', '$page');
    p = p.replaceAll('fyall', '');
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return Uri.parse(p);
    }
    final host = rule.host ?? '';
    final base = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return Uri.parse('$base${p.startsWith('/') ? '' : '/'}$p');
  }

  String _absolute(DrpyRule rule, String href, {String? baseUrl}) {
    return DrpyHost.completeUrl(href, baseUrl ?? rule.host) ?? href;
  }

  // ---------------- 列表解析（模板 + js 共用） ----------------

  /// 一级/搜索/推荐 片段结果 → 卡片（跳过缺 vod_id 的条目，不抛；
  /// 相对海报按当前页/宿主补全）。
  List<WorkCard> _cardsFromResult(DrpyHost host, Object? result) {
    final base = host.currentUrl ?? host.ruleHost;
    final out = <WorkCard>[];
    for (final v in host.resultAsList(result)) {
      try {
        final card = CmsJsonSource.cardFrom(v, sourceKey: def.key);
        out.add(WorkCard(
          sourceKey: card.sourceKey,
          workId: card.workId,
          title: card.title,
          posterUrl: DrpyHost.completeUrl(card.posterUrl ?? '', base),
          remarks: card.remarks,
          year: card.year,
          area: card.area,
          genre: card.genre,
          score: card.score,
        ));
      } on FetchException {
        // 缺 vod_id 的条目跳过（详情不可达，无意义展示）
      }
    }
    return out;
  }

  Future<List<WorkCard>> _parseList(
    DrpyRule rule,
    String html,
    String selectorKey,
  ) async {
    final spec = rule.fields[selectorKey]?.toString() ?? '';
    if (spec.isEmpty) return const [];
    final parts = spec.split(';');
    if (parts.length < 2) return const [];
    final listRule = parts[0];
    final titleRule = parts[1];
    final imgRule = parts.length > 2 ? parts[2] : '';
    final descRule = parts.length > 3 ? parts[3] : '';
    final linkRule = parts.length > 4 ? parts[4] : (parts.length > 2 ? parts[2] : '');

    // docs/13 D1：一次解析后在内存 DOM 上求值，避免逐元素重复全文解析
    final docRoot = html_parser.parse(html).documentElement;
    final items = PdfhEngine.pdfaIn(docRoot, listRule);
    final out = <WorkCard>[];
    for (final el in items) {
      final title = PdfhEngine.pdfh(el, titleRule) ?? '';
      var href = linkRule.isEmpty ? null : _fragPdfh(el, linkRule);
      href ??= _fragPdfh(el, 'a&&href');
      if (title.isEmpty || href == null || href.isEmpty) continue;
      out.add(WorkCard(
        sourceKey: def.key,
        workId: href,
        title: title,
        posterUrl: imgRule.isEmpty ? null : _fragPdfh(el, imgRule),
        remarks: descRule.isEmpty ? null : _fragPdfh(el, descRule),
      ));
    }
    return out;
  }

  /// 片段根级求值：把元素 outerHTML 重新解析为根，规则对片段生效
  /// （与 QuickJS 注入函数行为一致 —— `a&&Text` 对 `<a>` 元素本身可命中）。
  String? _fragPdfh(Element el, String rule) {
    final root = html_parser.parse(el.outerHtml).documentElement;
    return root == null ? null : PdfhEngine.pdfh(root, rule);
  }

  // ---------------- VideoSource ----------------

  @override
  Future<HomeFeed> home() async {
    final rule = await _ensureRule();
    final homePath = rule.homeUrl ??
        (rule.url ?? (rule.classUrls.isEmpty ? '/' : rule.classUrls.first));
    final homeUri = _pageUrl(rule, homePath, page: 1);
    final html = await (await http.get(homeUri, headers: def.headers)).body;
    _applyClassParse(rule, html);

    // js 推荐 → js 一级（首页推荐兜底走分类片段）→ 模板 推荐/一级
    final homeJsKey =
        rule.isJs('推荐') ? '推荐' : (rule.isJs('一级') ? '一级' : null);
    if (homeJsKey != null) {
      final host = await _ensureHost(rule);
      host.currentUrl = homeUri.toString();
      final result = await _runSnippet(
        host,
        rule.jsCode(homeJsKey)!,
        globals: {'input': homeUri.toString(), 'MY_PAGE': 1},
      );
      return HomeFeed(recommend: _cardsFromResult(host, result));
    }
    final listKey = rule.fields['推荐'] != null ? '推荐' : '一级';
    return HomeFeed(recommend: await _parseList(rule, html, listKey));
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async {
    final rule = await _ensureRule();
    final tid = query.typeId ?? rule.classUrls.firstOrNull ?? '';
    final path = _categoryPath(rule, tid);
    final uri = _pageUrl(rule, path, page: query.page);

    if (rule.isJs('一级')) {
      final host = await _ensureHost(rule);
      host.currentUrl = uri.toString();
      final result = await _runSnippet(
        host,
        rule.jsCode('一级')!,
        globals: {
          'input': uri.toString(),
          'MY_CATE': tid,
          'MY_PAGE': query.page,
          'MY_FL': query.filters,
          'TYPE': 'file',
        },
      );
      return PageResult(items: _cardsFromResult(host, result), page: query.page);
    }

    final html = await (await http.get(uri, headers: def.headers)).body;
    return PageResult(
      items: await _parseList(rule, html, '一级'),
      page: query.page,
    );
  }

  /// 分类地址：url 含 fyclass 占位 → 替换；否则 tid 本身即相对路径/绝对地址
  ///（class_parse 产物；与 dr_py 同语义）。
  String _categoryPath(DrpyRule rule, String tid) {
    final url = rule.url ?? '';
    if (url.contains('fyclass')) return url.replaceAll('fyclass', tid);
    if (tid.startsWith('http')) return tid;
    return tid;
  }

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    final rule = await _ensureRule();
    final searchUrl = rule.searchUrl ?? '';
    if (searchUrl.isEmpty) return PageResult(items: const [], page: page);
    final path = searchUrl.replaceAll('**', keyword);
    final uri = _pageUrl(rule, path, page: page);

    if (rule.isJs('搜索')) {
      final host = await _ensureHost(rule);
      host.currentUrl = uri.toString();
      final result = await _runSnippet(
        host,
        rule.jsCode('搜索')!,
        globals: {'input': uri.toString(), 'MY_PAGE': page},
      );
      return PageResult(items: _cardsFromResult(host, result), page: page);
    }

    final html = await (await http.get(uri, headers: def.headers)).body;
    return PageResult(items: await _parseList(rule, html, '搜索'), page: page);
  }

  @override
  Future<WorkDetail> detail(String workId) async {
    final rule = await _ensureRule();
    if (rule.double) {
      throw const FetchException('该源为 double 模式（v0.1 暂不支持）');
    }

    if (rule.isJs('二级')) {
      final host = await _ensureHost(rule);
      host.currentUrl = _absolute(rule, workId);
      final result = await _runSnippet(host, rule.jsCode('二级')!, globals: {
        'input': workId,
        'MY_URL': host.currentUrl,
      });
      final vods = host.resultAsList(result);
      if (vods.isEmpty) {
        throw const FetchException('drpy 二级：未返回影片数据');
      }
      return _detailFromVod(host, vods.first, fallbackId: workId);
    }

    final host = await _maybeHost(rule);
    final spec = rule.fields['二级'];
    if (spec is Map || (spec is String && _detailParts(spec).length >= 5)) {
      return _detailFromTemplate(rule, workId, spec, host);
    }
    return _detailNaive(rule, workId);
  }

  /// js 二级返回的 VOD 对象 → WorkDetail（复用 CMS 播放地址解析，docs/04 §5.4）。
  WorkDetail _detailFromVod(DrpyHost host, Map<String, dynamic> v,
      {required String fallbackId}) {
    final card = WorkCard(
      sourceKey: def.key,
      workId: v['vod_id']?.toString() ?? fallbackId,
      title: v['vod_name']?.toString() ?? fallbackId,
      posterUrl: _absoluteHost(
          v['vod_pic']?.toString(), host.currentUrl ?? host.ruleHost),
      remarks: _emptyToNull(v['vod_remarks']?.toString()),
      year: _emptyToNull(v['vod_year']?.toString()),
      area: _emptyToNull(v['vod_area']?.toString()),
      genre: _emptyToNull(v['vod_class']?.toString() ?? v['type_name']?.toString()),
    );
    return WorkDetail(
      card: card,
      actor: _emptyToNull(v['vod_actor']?.toString()),
      director: _emptyToNull(v['vod_director']?.toString()),
      content: _stripHtml(v['vod_content']?.toString()),
      lines: CmsJsonSource.parseLines(
        from: v['vod_play_from']?.toString() ?? '',
        urls: v['vod_play_url']?.toString() ?? '',
      ),
    );
  }

  /// 模板二级深解析：tabs（线路）× lists（选集）。
  Future<WorkDetail> _detailFromTemplate(
    DrpyRule rule,
    String workId,
    Object? spec,
    DrpyHost? host,
  ) async {
    final detailUrl = rule.detailUrl;
    final path = detailUrl == null || detailUrl.isEmpty
        ? workId
        : detailUrl.replaceAll('{id}', workId);
    final uri = _pageUrl(rule, path, page: 1);
    final res = await http.get(uri, headers: def.headers,
        timeout: const Duration(seconds: 12));
    final html = res.body;
    host?.currentUrl = uri.toString();

    String titleRule = '', imgRule = '', descRule = '', contentRule = '', tabsRule = '', listsSpec = '';
    if (spec is Map) {
      final m = Map<String, dynamic>.from(spec);
      titleRule = m['title']?.toString() ?? '';
      imgRule = m['img']?.toString() ?? '';
      descRule = m['desc']?.toString() ?? '';
      contentRule = m['content']?.toString() ?? '';
      tabsRule = m['tabs']?.toString() ?? '';
      final l = m['lists'];
      listsSpec = l is List ? l.map((e) => e.toString()).join(';;') : (l?.toString() ?? '');
    } else {
      final p = _detailParts(spec.toString());
      titleRule = p[1];      imgRule = p[2];
      descRule = p[3];
      contentRule = p[4];
      tabsRule = p.length > 5 ? p[5] : '';
      listsSpec = p.length > 6 ? p[6] : '';
    }

    final doc = html_parser.parse(html).documentElement;
    String? pick(String ruleText) {
      if (ruleText.isEmpty || ruleText == '*') return null;
      return doc == null ? null : PdfhEngine.pdfh(doc, ruleText);
    }

    final title = pick(titleRule) ?? workId;
    final poster = _absoluteHost(pick(imgRule), uri.toString());

    // 线路名（tabs）：支持规则尾段带取值后缀（…&&Text）
    var lineNames = <String>[];
    if (tabsRule.isNotEmpty) {
      final split = _splitValueTail(tabsRule);
      // docs/13 D1：复用 doc 一次解析结果
      final items = PdfhEngine.pdfaIn(doc, split.$1);
      lineNames = [
        for (final el in items)
          split.$2 == null ? el.text.trim() : (PdfhEngine.pdfh(el, split.$2!) ?? '')
      ];
    }
    lineNames = _postTabs(rule, lineNames);

    // 剧集（lists）：`容器(含 :eq(#id));;集标题;集链接`
    final lparts = listsSpec.split(';;');
    final listContainer = lparts.isEmpty ? '' : lparts[0].trim();
    final epTitle = lparts.length > 1 ? lparts[1].trim() : '';
    final epLink = lparts.length > 2 ? lparts[2].trim() : '';
    final hasIndex = listContainer.contains('#id');

    final lines = <PlayLine>[];
    if (listContainer.isEmpty) {
      // 无 lists 规则：退化为整页直链抓取
      final eps = _directMediaEpisodes(rule, doc, uri.toString());
      if (eps.isNotEmpty) {
        lines.add(PlayLine(lineId: 'default', name: '默认线路', episodes: eps));
      }
    } else {
      final tabCount = hasIndex && lineNames.isNotEmpty ? lineNames.length : 1;
      for (var i = 0; i < tabCount; i++) {
        // #id 下标语义生态不一（0 基/1 基并存）：先取本线路下标，
        // 空结果再试 +1 —— 两种写法在该策略下均正确映射到对应线路块
        List<Element> items = const [];
        for (final k in hasIndex ? [i, i + 1] : const <int>[]) {
          // docs/13 D1：复用 doc 一次解析结果
          items = PdfhEngine.pdfaIn(doc, listContainer.replaceAll('#id', '$k'));
          if (items.isNotEmpty) break;
        }
        if (!hasIndex) {
          items = PdfhEngine.pdfaIn(doc, listContainer);
        }
        final eps = <Episode>[];
        var index = 0;
        for (final el in items) {
          final name = (epTitle.isEmpty ? el.text.trim() : (_fragPdfh(el, epTitle) ?? el.text.trim()));
          var href = epLink.isEmpty ? null : _fragPdfh(el, epLink);
          href ??= _fragPdfh(el, 'a&&href') ?? el.attributes['href'];
          var urlText = href ?? '';
          // 无链接规则时退化解析「集名$地址」文本
          if (urlText.isEmpty && name.contains(r'$')) {
            final dollar = name.indexOf(r'$');
            urlText = name.substring(dollar + 1);
          }
          if (urlText.isEmpty) continue;
          eps.add(Episode(
            index: index++,
            name: name.isEmpty ? '第${index}集' : name.split(r'$').first.trim(),
            url: _absolute(rule, urlText, baseUrl: uri.toString()),
          ));
        }
        if (eps.isEmpty) continue;
        final name = i < lineNames.length && lineNames[i].isNotEmpty
            ? lineNames[i]
            : '线路${i + 1}';
        lines.add(PlayLine(lineId: 'line$i', name: name, episodes: eps));
      }
    }

    return WorkDetail(
      card: WorkCard(
        sourceKey: def.key,
        workId: workId,
        title: title,
        posterUrl: poster,
        remarks: _emptyToNull(pick(descRule)),
      ),
      content: _stripHtml(pick(contentRule)),
      lines: lines,
    );
  }

  /// 兜底（无 二级/二级 过简）：整页直链抓取（保持既有行为）。
  Future<WorkDetail> _detailNaive(DrpyRule rule, String workId) async {
    final detailUrl = rule.detailUrl;
    final path = detailUrl == null || detailUrl.isEmpty
        ? workId
        : detailUrl.replaceAll('{id}', workId);
    final url = _absolute(rule, path);
    final res = await http.get(Uri.parse(url),
        headers: def.headers, timeout: const Duration(seconds: 12));
    final doc = html_parser.parse(res.body).documentElement;
    final title = doc == null ? null : PdfhEngine.pdfh(doc, 'h1&&Text');
    final poster = doc == null ? null : PdfhEngine.pdfh(doc, 'img&&src');
    final eps = _directMediaEpisodes(rule, doc, url);
    final lines = <PlayLine>[];
    if (eps.isNotEmpty) {
      lines.add(PlayLine(lineId: 'default', name: '默认线路', episodes: eps));
    }
    return WorkDetail(
      card: WorkCard(
        sourceKey: def.key,
        workId: workId,
        title: title ?? workId,
        posterUrl: poster,
      ),
      lines: lines,
    );
  }

  /// 页面内全部直链（a[href*=.m3u8/.mp4/…]）→ 选集。
  List<Episode> _directMediaEpisodes(DrpyRule rule, Element? doc, String baseUrl) {
    final eps = <Episode>[];
    var index = 0;
    for (final a in doc?.querySelectorAll('a') ?? const <Element>[]) {
      final href = a.attributes['href'] ?? '';
      if (!CmsJsonSource.isDirectMedia(href)) continue;
      final name = a.text.trim();
      eps.add(Episode(
        index: index++,
        name: name.isEmpty ? '第${index}集' : name,
        url: _absolute(rule, href, baseUrl: baseUrl),
      ));
    }
    return eps;
  }

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    final rule = await _ensureRule();
    final workDetail = await detail(request.workId);
    final line = request.lineId == null
        ? workDetail.lines.firstOrNull
        : workDetail.lines.where((l) => l.lineId == request.lineId).firstOrNull;
    if (line == null || line.episodes.isEmpty) {
      throw const FetchException('该源没有可用播放线路');
    }
    final index = request.episodeIndex.clamp(0, line.episodes.length - 1);
    final ep = line.episodes[index];

    if (rule.isJs('lazy')) {
      // 未接入 QuickJS 时：直链可直通；非直链必须 lazy，明确报缺引擎。
      if (jsFactory == null) {
        if (CmsJsonSource.isDirectMedia(ep.url)) {
          return PlayCandidate(url: ep.url, needsParse: false);
        }
        throw FetchException(
            '该源 lazy 为 js: 内联代码（${rule.firstJsField ?? 'lazy'}），需要 QuickJS 运行时，当前端未接入');
      }
      final host = await _ensureHost(rule);
      host.currentUrl = ep.url;
      final result = await _runSnippet(host, rule.jsCode('lazy')!, globals: {
        'input': ep.url,
        'MY_URL': ep.url,
      });
      final m = host.resultAsMap(result);
      final url = m?['url']?.toString() ?? '';
      if (url.isEmpty) {
        throw const FetchException('drpy lazy：未返回播放地址');
      }
      final headerMap = <String, String>{};
      final h = m?['header'];
      if (h is Map) {
        for (final e in h.entries) {
          if (e.value != null) headerMap[e.key.toString()] = e.value.toString();
        }
      }
      final parse = m?['parse'];
      final needsParse =
          (parse is num && parse == 1) || parse == true || !CmsJsonSource.isDirectMedia(url);
      return PlayCandidate(url: url, headers: headerMap, needsParse: needsParse);
    }

    return PlayCandidate(url: ep.url, needsParse: !CmsJsonSource.isDirectMedia(ep.url));
  }

  // ---------------- 辅助 ----------------

  /// 执行 js: 片段（host 已就绪；JS 异常/超时/超限统一为 FetchException 熔断）。
  Future<Object?> _runSnippet(
    DrpyHost host,
    String code, {
    Map<String, Object?> globals = const {},
  }) async {
    try {
      return await host.runSnippet(code, globals: globals);
    } on JsEvalException catch (e) {
      throw FetchException('drpy js 片段执行失败（已熔断）', cause: e.message);
    }
  }

  /// class_parse（模板形态）→ class_name/class_url 写回 rule.fields。
  void _applyClassParse(DrpyRule rule, String html) {
    // docs/13 D1：一次解析供后续 pdfaIn 复用
    if (rule.classNames.isNotEmpty && rule.classUrls.isNotEmpty) return;
    final spec = rule.fields['class_parse'];
    if (spec is! String || spec.trimLeft().startsWith('js:')) return;
    final parts = spec.split(';');
    if (parts.length < 3) return;
    final exclude = rule.fields['cate_exclude']?.toString();
    RegExp? excludeRe;
    if (exclude != null && exclude.isNotEmpty) {
      try {
        excludeRe = RegExp(exclude);
      } on FormatException {
        excludeRe = null;
      }
    }
    final names = <String>[];
    final urls = <String>[];
    final classDoc = html_parser.parse(html).documentElement;
    for (final el in PdfhEngine.pdfaIn(classDoc, parts[0])) {
      final name = (_fragPdfh(el, parts[1]) ?? '').trim();
      var href = (_fragPdfh(el, parts[2]) ?? '').trim();
      if (parts.length > 3 && href.isNotEmpty) {
        href = _regexPick(parts[3], href) ?? href;
      }
      if (name.isEmpty || href.isEmpty) continue;
      if (excludeRe != null && excludeRe.hasMatch(name)) continue;
      names.add(name);
      urls.add(href);
    }
    if (names.isNotEmpty) {
      rule.fields['class_name'] = names.join('&');
      rule.fields['class_url'] = urls.join('&');
    }
  }

  /// 第 4 段正则（`/…/` 字面量形态）→ 取捕获组 1（无捕获组取全匹配）。
  String? _regexPick(String spec, String input) {
    var pattern = spec.trim();
    if (pattern.length >= 2 && pattern.startsWith('/') && pattern.endsWith('/')) {
      pattern = pattern.substring(1, pattern.length - 1);
    }
    if (pattern.isEmpty) return null;
    try {
      final m = RegExp(pattern).firstMatch(input);
      if (m == null) return null;
      return m.groupCount >= 1 ? (m.group(1) ?? m.group(0)) : m.group(0);
    } on FormatException {
      return null;
    }
  }

  /// 线路名后处理：tab_remove（包含匹配剔除）→ tab_rename → tab_order 排序。
  List<String> _postTabs(DrpyRule rule, List<String> names) {
    final remove = rule.tabRemove;
    final rename = rule.tabRename;
    final out = [
      for (final n in names)
        if (!remove.any(n.contains)) (rename[n] ?? n),
    ];
    final order = rule.tabOrder;
    if (order.isNotEmpty) {
      out.sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        return (ai < 0 ? order.length : ai).compareTo(bi < 0 ? order.length : bi);
      });
    }
    return out;
  }

  /// 规则尾段是取值后缀（…&&Text/attr）时拆分：返回（选择器规则, 取值后缀）。
  (String, String?) _splitValueTail(String rule) {
    final parts = rule.split('&&');
    if (parts.length > 1) {
      final last = parts.last.trim();
      if (last == 'Text' || last == 'text' || last == 'html') {
        return (parts.sublist(0, parts.length - 1).join('&&'), 'Text');
      }
      if (RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(last)) {
        return (parts.sublist(0, parts.length - 1).join('&&'), last);
      }
    }
    return (rule, null);
  }

  /// 二级字符串形态分段（'js:' 形态返回空表）。
  static List<String> _detailParts(Object? spec) {
    if (spec is! String || spec.trimLeft().startsWith('js:')) return const [];
    return spec.split(';');
  }

  static String? _absoluteHost(String? url, String? base) {
    if (url == null || url.isEmpty) return null;
    return DrpyHost.completeUrl(url, base);
  }

  static String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;

  static String? _stripHtml(String? text) {
    if (text == null || text.isEmpty) return null;
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
