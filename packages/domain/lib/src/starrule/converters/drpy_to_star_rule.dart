/// drpy 纯模板 rule → StarRule 转译器（docs/17 §13）。
///
/// 只转「纯模板」字段；含 `js:` 内联的字段保留到 `script` 逃生舱并记 issue。
/// 选择器语法与 PdfhEngine 同构，可直接搬。
library;

import 'dart:convert';

import '../../config/parse_report.dart';
import '../star_rule.dart';
import '../star_rule_parser.dart';

/// drpy rule 对象（已由 DrpyRuleParser 解出的 Map）。
class DrpyToStarRule {
  const DrpyToStarRule._();

  /// 从 `var rule = {...}` 源文本转译。
  static StarRuleParseResult convertSource(String drpySource) {
    final map = _extractRuleMap(drpySource);
    return convertMap(map);
  }

  /// 从已解析的 rule Map 转译。
  static StarRuleParseResult convertMap(Map<String, dynamic> r) {
    final issues = <ParseIssue>[];
    final host = _str(r['host']) ?? '';
    if (host.isEmpty) {
      throw const StarRuleParseException('drpy rule 缺 host');
    }
    final title = _str(r['title']) ?? 'drpy转译源';

    // 选择器同构：drpy 一级/搜索 片段 `列表;标题;图片;描述;链接`
    StarItemMap? itemsOf(String? spec, String label) {
      if (spec == null || spec.trim().isEmpty) return null;
      if (spec.trimLeft().startsWith('js:')) {
        issues.add(ParseIssue('$label 含 js: 片段，已放入 script，需 QuickJS'));
        return null;
      }
      final p = spec.split(';');
      if (p.length < 5) {
        issues.add(ParseIssue('$label 片段段数不足（需 列表;标题;图片;描述;链接）'));
        return null;
      }
      return StarItemMap(
        list: StarField(sel: p[0].trim()),
        title: StarField(sel: _withText(p[1])),
        cover: StarField(sel: _withAttr(p[2], 'src')),
        badge: StarField(sel: _withText(p[3])),
        id: StarField(sel: _withAttr(p[4], 'href')),
      );
    }

    final homeItems = itemsOf(_str(r['推荐']) ?? _str(r['一级']), '推荐');
    final catItems = itemsOf(_str(r['一级']), '一级');
    final searchItems = itemsOf(_str(r['搜索']), '搜索');

    // class_name & class_url → manual
    final manual = <String, String>{};
    final names = (_str(r['class_name']) ?? '').split('&');
    final urls = (_str(r['class_url']) ?? '').split('&');
    for (var i = 0; i < names.length && i < urls.length; i++) {
      final n = names[i].trim();
      if (n.isEmpty) continue;
      manual[n] = urls[i].trim();
    }

    // 二级：`*;标题;图片;描述;内容;线路;剧集容器;;集标题;集链接`
    StarDetail detail;
    final secRaw = r['二级'];
    if (secRaw is Map) {
      detail = StarDetail(
        url: _str(r['detailUrl']),
        title: StarField(sel: _withText(secRaw['title']?.toString() ?? '')),
        cover: StarField(sel: _withAttr(secRaw['img']?.toString() ?? '', 'src')),
        desc: StarField(sel: _withText(secRaw['desc']?.toString() ?? '')),
        lines: StarLines(
          list: StarField(sel: _withText(secRaw['tabs']?.toString() ?? '')),
          name: const StarField(sel: 'Text'),
          episodes: StarEpisodes(
            list: StarField(sel: _withAttr(secRaw['lists']?.toString() ?? '', 'href')),
            name: const StarField(sel: 'Text'),
            url: const StarField(sel: 'href'),
          ),
        ),
      );
    } else if (secRaw is String && !secRaw.trimLeft().startsWith('js:')) {
      final p = secRaw.split(';');
      // p: [*, title, img, desc, content, tabs, lists, '', epName, epUrl]
      String at(int i) => i < p.length ? p[i].trim() : '';
      final listsSpec = at(6);
      final epName = at(8).isEmpty ? 'Text' : at(8);
      final epUrl = at(9).isEmpty ? 'href' : at(9);
      detail = StarDetail(
        url: _str(r['detailUrl']),
        title: StarField(sel: _withText(at(1))),
        cover: StarField(sel: _withAttr(at(2), 'src')),
        desc: StarField(sel: _withText(at(4).isEmpty ? at(3) : at(4))),
        lines: StarLines(
          list: StarField(sel: _withText(at(5))),
          name: const StarField(sel: 'Text'),
          episodes: StarEpisodes(
            list: StarField(sel: _withAttr(listsSpec, 'href')),
            name: StarField(sel: _withText(epName)),
            url: StarField(sel: _withAttr(epUrl, 'href')),
          ),
        ),
      );
    } else {
      if (secRaw is String && secRaw.trimLeft().startsWith('js:')) {
        issues.add(const ParseIssue('二级 含 js: 片段，详情需 QuickJS'));
      }
      detail = StarDetail(url: _str(r['detailUrl']));
    }

    // headers
    final headers = <String, String>{};
    final h = r['headers'];
    if (h is Map) {
      h.forEach((k, v) {
        if (v != null) headers[k.toString()] = v.toString();
      });
    }

    // url 模板：fyclass/fypage/** → StarRule 占位
    String mapUrl(String? u) {
      if (u == null) return '';
      return u
          .replaceAll('fyclass', '{cateId}')
          .replaceAll('fypage', '{catePg}')
          .replaceAll('**', '{wd}');
    }

    final script = <String, String>{};
    for (final key in ['预处理', '推荐', '一级', '二级', '搜索', 'lazy']) {
      final code = _jsOf(r[key]);
      if (code != null) {
        script[key == 'lazy' ? 'lazy' : 'preprocess'] = code;
        issues.add(ParseIssue('字段「$key」含 js: 内联代码，已迁入 script'));
      }
    }

    final playParse = r['play_parse'] is! num || r['play_parse'] != 0;

    final ruleMap = <String, dynamic>{
      'starrule': 1,
      'convertedFrom': 'drpy',
      'meta': {
        'id': 'drpy.${_slug(title)}',
        'name': title,
      },
      'sourceType': 'html',
      'site': {
        'host': host.endsWith('/') ? host.substring(0, host.length - 1) : host,
        if (headers.isNotEmpty) 'headers': headers,
        if (_str(r['timeout']) != null) 'timeout': int.tryParse(_str(r['timeout'])!) ?? 15,
      },
      // home：有 homeUrl / 推荐 / 分类表就写
      if (_str(r['homeUrl']) != null || homeItems != null || manual.isNotEmpty)
        'home': {
          'url': mapUrl(_str(r['homeUrl']) ?? '/'),
          if (homeItems != null) 'recommend': _itemJson(homeItems),
          if (manual.isNotEmpty)
            'categories': {
              'mode': 'manual',
              'manual': manual,
            },
        },
      if (catItems != null)
        'category': {
          'url': mapUrl(_str(r['url']) ?? ''),
          ..._itemJson(catItems),
        }
      else if (script.containsKey('一级') || script.containsKey('preprocess'))
        // js 一级：占位 category，执行时走 script
        'category': {
          'url': mapUrl(_str(r['url']) ?? ''),
          'list': 'body',
          'title': 'Text',
          'id': 'href',
        },
      if (searchItems != null)
        'search': {
          'url': mapUrl(_str(r['searchUrl']) ?? ''),
          ..._itemJson(searchItems),
        },
      'detail': _detailJson(detail),
      'play': {
        'url': '{playUrl}',
        'parse': playParse ? '1' : '0',
      },
      if (script.isNotEmpty) 'script': script,
      'caps': {
        if (r['filterable'] == 0) 'filterable': false,
        if (r['searchable'] == 0) 'searchable': false,
        if (r['quickSearch'] == 0) 'quickSearch': false,
      },
    };

    // 用 parser 再校验一遍，保证产出合法
    final parsed = StarRuleParser.parse(jsonEncode(ruleMap));
    return StarRuleParseResult(
      rule: parsed.rule,
      issues: [...issues, ...parsed.issues],
    );
  }

  static Map<String, dynamic> _itemJson(StarItemMap m) {
    return {
      'list': m.list.sel,
      'title': m.title.sel,
      'id': m.id.sel,
      if (m.cover != null) 'cover': m.cover!.sel,
      if (m.badge != null) 'badge': m.badge!.sel,
    };
  }

  static Map<String, dynamic> _detailJson(StarDetail d) {
    return {
      if (d.url != null) 'url': d.url,
      if (d.title != null) 'title': d.title!.sel,
      if (d.cover != null) 'cover': d.cover!.sel,
      if (d.desc != null) 'desc': d.desc!.sel,
      if (d.lines != null)
        'lines': {
          if (d.lines!.list != null) 'list': d.lines!.list!.sel,
          if (d.lines!.name != null) 'name': d.lines!.name!.sel,
          if (d.lines!.episodes != null)
            'episodes': {
              'list': d.lines!.episodes!.list.sel,
              'name': d.lines!.episodes!.name.sel,
              'url': d.lines!.episodes!.url.sel,
            },
        },
    };
  }

  /// 取值片段补后缀：空→Text；已有 && 则原样；纯选择器补 Text。
  static String _withText(String rule) {
    final s = rule.trim();
    if (s.isEmpty) return 'Text';
    if (s.contains('&&') || s == 'Text' || s == 'html') return s;
    if (s.startsWith('@')) return s.substring(1);
    return '$s&&Text';
  }

  /// 属性取值：空→默认 attr；`img&&src` 原样；纯选择器补 attr。
  static String _withAttr(String rule, String attr) {
    final s = rule.trim();
    if (s.isEmpty) return attr;
    if (s.contains('&&') || s == 'Text' || s == 'html') return s;
    return '$s&&$attr';
  }

  static String? _str(Object? v) => v is String ? v : v?.toString();

  static String? _jsOf(Object? v) {
    if (v is! String) return null;
    final t = v.trimLeft();
    return t.startsWith('js:') ? t.substring(3) : null;
  }

  static String _slug(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// 从 drpy 源文本抽出 rule 对象 Map（复用容错花括号配平）。
  static Map<String, dynamic> _extractRuleMap(String source) {
    final marker = RegExp(r'''(?:var|let|const)\s+rule\s*=\s*''');
    final match = marker.firstMatch(source);
    if (match == null) {
      throw const StarRuleParseException('未找到 rule 对象');
    }
    final literal = _balancedBraces(source, match.end);
    if (literal == null) {
      throw const StarRuleParseException('rule 对象花括号不配平');
    }
    final decoded = jsonDecode(_toStrictJson(literal));
    if (decoded is! Map<String, dynamic>) {
      throw const StarRuleParseException('rule 不是对象');
    }
    return decoded;
  }

  static String? _balancedBraces(String text, int start) {
    var i = start;
    while (i < text.length && text[i] != '{') {
      i++;
    }
    if (i >= text.length) return null;
    var depth = 0;
    var inString = false;
    var stringChar = '';
    var escaped = false;
    for (; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == stringChar) {
          inString = false;
        }
        continue;
      }
      if (ch == '"' || ch == "'") {
        inString = true;
        stringChar = ch;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }

  static final _bareKey =
      RegExp(r'''(?<=[{,\n])(\s*)([A-Za-z_一-鿿][\w一-鿿]*)\s*:''');

  static String _toStrictJson(String jsLiteral) {
    var s = jsLiteral;
    // 裸键加引号（title: → "title":）
    s = s.replaceAllMapped(_bareKey, (m) => '${m.group(1)}"${m.group(2)}":');
    // 单引号字符串 → 双引号
    s = s.replaceAllMapped(
        RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'"), (m) => '"${m.group(1)}"');
    // 反引号 → 双引号
    s = s.replaceAllMapped(
        RegExp(r'`([^`\\]*(?:\\.[^`\\]*)*)`'), (m) => '"${m.group(1)}"');
    // 尾逗号
    s = s.replaceAllMapped(RegExp(r',\s*([}\]])'), (m) => m.group(1)!);
    return s;
  }
}
