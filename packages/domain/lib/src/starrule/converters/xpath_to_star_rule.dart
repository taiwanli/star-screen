/// XPath 规则（TVBox csp_XPath* ext）→ StarRule 转译器。
///
/// 字段映射见 docs/17 §7.3。产出规则带 `convertedFrom: tvbox-xpath`。
library;

import 'dart:convert';

import '../../config/parse_report.dart';
import '../star_rule.dart';
import '../star_rule_parser.dart';

class XpathToStarRule {
  const XpathToStarRule._();

  /// 解析 ext 原文（JSON 字符串或对象）并转为 StarRule。
  static StarRuleParseResult convert(String extRaw, {Uri? baseUrl}) {
    final decoded = _decode(extRaw);
    return convertMap(decoded, baseUrl: baseUrl);
  }

  static StarRuleParseResult convertMap(
    Map<String, dynamic> x, {
    Uri? baseUrl,
  }) {
    final host = _hostOf(x['homeUrl']?.toString() ?? '');
    if (host == null) {
      throw const StarRuleParseException('XPath 规则缺 homeUrl，无法确定 host');
    }
    final issues = <ParseIssue>[];

    // cateManual → home.categories.manual
    final manual = <String, String>{};
    final cm = x['cateManual'];
    if (cm is Map) {
      cm.forEach((k, v) => manual[k.toString()] = v.toString());
    }

    // XPath 相对路径（/text() /@href）→ 选择器链后缀
    String field(Object? xpath, {String root = ''}) {
      return _xpathToSel(xpath?.toString(), root: root);
    }

    final cateNode = x['cateVodNode']?.toString() ?? '';
    final homeUrl = x['homeUrl']?.toString() ?? host;
    final ua = x['ua']?.toString();

    final category = StarBlock(
      url: x['cateUrl']?.toString() ?? '',
      items: StarItemMap(
        list: StarField(sel: _xpathToListSel(cateNode)),
        title: StarField(sel: field((x['cateVodName'] ?? x['cateVodNameR'])?.toString())),
        id: StarField(sel: field((x['cateVodId'] ?? x['cateVodIdR'])?.toString())),
        cover: StarField(sel: field((x['cateVodImg'] ?? x['cateVodImgR'])?.toString())),
        badge: StarField(sel: field((x['cateVodMark'] ?? x['cateVodMarkR'])?.toString())),
      ),
    );

    final dtNode = x['dtNode']?.toString() ?? '';
    final lines = StarLines(
      list: StarField(sel: field(x['dtFromNode'], root: dtNode)),
      name: StarField(sel: field(x['dtFromName']?.toString())),
      episodes: StarEpisodes(
        list: StarField(
          sel: _eqLine(_xpathToListSel(x['dtUrlNode']?.toString() ?? '')),
        ),
        name: StarField(sel: field(x['dtUrlName']?.toString())),
        url: StarField(sel: field(x['dtUrlId']?.toString())),
      ),
    );

    final detail = StarDetail(
      url: x['dtUrl']?.toString(),
      title: StarField(sel: field(x['dtName'] ?? x['dtNameR'], root: dtNode)),
      cover: StarField(sel: field(x['dtImg'] ?? x['dtImgR'], root: dtNode)),
      desc: StarField(sel: field(x['dtDesc'] ?? x['dtDescR'], root: dtNode)),
      year: StarField(sel: field(x['dtYear'], root: dtNode)),
      area: StarField(sel: field(x['dtArea'], root: dtNode)),
      type: StarField(sel: field(x['dtCate'], root: dtNode)),
      actor: StarField(sel: field(x['dtActor'], root: dtNode)),
      director: StarField(sel: field(x['dtDirector'], root: dtNode)),
      remarks: StarField(sel: field(x['dtMark'], root: dtNode)),
      lines: lines,
    );

    StarBlock? search;
    final searchUrl = x['searchUrl']?.toString();
    if (searchUrl != null && searchUrl.isNotEmpty) {
      final scNode = x['scVodNode']?.toString() ?? '';
      search = StarBlock(
        url: searchUrl,
        items: StarItemMap(
          list: StarField(sel: _xpathToListSel(scNode)),
          title: StarField(sel: field(x['scVodName']?.toString())),
          id: StarField(sel: field(x['scVodId']?.toString())),
          cover: StarField(sel: field(x['scVodImg']?.toString())),
          badge: StarField(sel: field(x['scVodMark']?.toString())),
        ),
      );
    } else {
      issues.add(const ParseIssue('XPath 规则无 searchUrl，搜索置灰'));
    }

    final playUrl = x['playUrl']?.toString() ?? '';
    final playUa = x['playUa']?.toString();
    final playReferer = x['playReferer']?.toString();
    final play = StarPlay(
      url: playUrl.isEmpty ? '{playUrl}' : playUrl,
      headers: {
        if (playUa != null && playUa.isNotEmpty) 'User-Agent': playUa,
        if (playReferer != null && playReferer.isNotEmpty) 'Referer': playReferer,
      },
    );

    final key = 'xrule.${_slug(host)}';
    final rule = StarRule(
      meta: StarMeta(
        id: key,
        name: x['title']?.toString() ?? 'XPath转译源',
      ),
      site: StarSite(
        host: host,
        homeUrl: homeUrl.startsWith('http') ? Uri.parse(homeUrl).path : homeUrl,
        headers: {
          if (ua != null && ua.isNotEmpty) 'User-Agent': ua,
        },
      ),
      sourceType: StarSourceType.html,
      home: StarHome(
        url: '/',
        categories: StarCategories(mode: 'manual', manual: manual),
      ),
      category: category,
      detail: detail,
      search: search,
      play: play,
      convertedFrom: 'tvbox-xpath',
      raw: x,
    );
    return StarRuleParseResult(rule: rule, issues: issues);
  }

  static Map<String, dynamic> _decode(String raw) {
    final s = raw.trim();
    final Object? doc;
    try {
      doc = jsonDecode(s);
    } on FormatException {
      throw const StarRuleParseException('XPath ext 不是合法 JSON');
    }
    if (doc is! Map<String, dynamic>) {
      throw const StarRuleParseException('XPath ext 顶层必须是对象');
    }
    return doc;
  }

  static String? _hostOf(String url) {
    if (url.isEmpty) return null;
    try {
      final u = Uri.parse(url);
      if (u.host.isEmpty) return null;
      return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
    } on FormatException {
      return null;
    }
  }

  static String _slug(String host) {
    return host
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// XPath 相对取值（`/text()` `/@href` `//img/@src`）→ pdfh 选择器后缀。
  /// [root] 为 XPath 详情根节点：仅在**相对**路径时转成 CSS 前缀；
  /// 绝对路径（`//...`）忽略 root，避免拼出非法选择器。
  static String _xpathToSel(String? xpath, {String root = ''}) {
    if (xpath == null || xpath.trim().isEmpty) return 'Text';
    var p = xpath.trim();
    final isAbsolute = p.startsWith('//');

    if (isAbsolute) {
      p = p.substring(2);
    } else if (p.startsWith('/')) {
      p = p.substring(1);
    }

    String withRoot(String chain) {
      if (root.trim().isEmpty || isAbsolute) return chain;
      final rootCss = _xpathToListSel(root);
      if (rootCss.isEmpty || rootCss == 'body') return chain;
      return '$rootCss&&$chain';
    }

    if (p == 'text()' || p == 'Text') return withRoot('Text');
    if (p == 'html()') return withRoot('html');
    if (p.startsWith('@')) {
      return withRoot(p.substring(1));
    }
    final attrMatch = RegExp(r'^(.+)/@([a-zA-Z0-9_-]+)$').firstMatch(p);
    if (attrMatch != null) {
      final node = attrMatch.group(1)!;
      final attr = attrMatch.group(2)!;
      return withRoot('$node&&$attr');
    }
    final textMatch = RegExp(r'^(.+)/text\(\)$').firstMatch(p);
    if (textMatch != null) {
      return withRoot('${textMatch.group(1)}&&Text');
    }
    final segs = p
        .split('/')
        .where((e) => e.isNotEmpty && e != '.' && e != '..')
        .map(_segToCss)
        .join('&&');
    if (segs.isEmpty) return withRoot('Text');
    return withRoot(segs);
  }

  /// 列表 XPath（`//div[@class='list']//a`）→ pdfa 列表选择器。
  static String _xpathToListSel(String xpath) {
    if (xpath.trim().isEmpty) return 'body';
    var p = xpath.trim();
    if (p.startsWith('json:')) {
      // 搜索列表可能是 json:data>list —— 保留 json: 形态
      return p.replaceFirst('json:', 'json:');
    }
    if (p.startsWith('//')) p = p.substring(2);
    else if (p.startsWith('/')) p = p.substring(1);
    final segs = p
        .split('/')
        .where((e) => e.isNotEmpty && e != '.' && e != '..')
        .map(_segToCss)
        .join('&&');
    return segs.isEmpty ? 'body' : segs;
  }

  /// 选集列表挂到线路下标：`.eq(#line)` 由执行器展开。
  static String _eqLine(String listSel) {
    if (listSel.contains('#line') || listSel.contains('eq(#')) return listSel;
    // 在最后一段挂 eq(#line)——执行器把 #line 换成线路下标
    final parts = listSel.split('&&');
    if (parts.isEmpty) return listSel;
    final last = parts.last;
    if (last.contains(':eq(')) return listSel;
    parts[parts.length - 1] = '$last:eq(#line)';
    return parts.join('&&');
  }

  static String _segToCss(String seg) {
    // //div[@class='list'] → div.list（近似；多 class 取第一个）
    final tagClass = RegExp(r'''^([a-zA-Z0-9]+)\[@class=['"]([^'"]+)['"]\]$''')
        .firstMatch(seg);
    if (tagClass != null) {
      final tag = tagClass.group(1)!;
      final cls = tagClass.group(2)!.split(RegExp(r'\s+')).first;
      return '$tag.$cls';
    }
    // //div[@id='x'] → div#x
    final tagId =
        RegExp(r'''^([a-zA-Z0-9]+)\[@id=['"]([^'"]+)['"]\]$''').firstMatch(seg);
    if (tagId != null) {
      return '${tagId.group(1)}#${tagId.group(2)}';
    }
    // //a → a
    return seg;
  }
}
