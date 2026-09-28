import 'dart:convert';

/// drpy 源规则解析器（docs/04 §4.3 rule 模板；docs/09 M3-4 第一块地基）。
///
/// drpy 源文件形如 `var rule = { ... }`（JS 对象字面量：键可不加引号、
/// 单引号字符串、尾随逗号、`//` 注释、字符串内含 `js:` 代码段）。
/// 本解析器把它容错转换为 Dart Map：
/// - 值全部为字面量（字符串/数字/布尔/数组/对象）→ 完整解析（**纯模板源**，
///   可由原生模板执行器直接运行，无需 JS 引擎）；
/// - 含 `js:` 前缀的内联代码（值前缀）→ 保留原文，标记 [result.isTemplateOnly] = false，
///   等待 M3-4 QuickJS 运行时。
class DrpyRuleParser {
  const DrpyRuleParser._();

  /// 从 JS 源文本中提取 `rule` 对象并解析；失败返回 null（调用方给出提示）。
  static DrpyRule? parse(String source) {
    final marker = RegExp(r'''(?:var|let|const)\s+rule\s*=\s*''');
    final match = marker.firstMatch(source);
    if (match == null) return null;
    final literal = _balancedBraces(source, match.end);
    if (literal == null) return null;
    final decoded = jsonDecode(_toStrictJson(literal));
    if (decoded is! Map<String, dynamic>) return null;
    return DrpyRule._(decoded);
  }
}

class DrpyRule {
  final Map<String, dynamic> fields;

  const DrpyRule._(this.fields);

  String? _str(String key) => fields[key] is String ? fields[key] as String : null;

  String? get title => _str('title');
  String? get host => _str('host');
  String? get homeUrl => _str('homeUrl');
  String? get url => _str('url');
  String? get searchUrl => _str('searchUrl');
  String? get detailUrl => _str('detailUrl');

  bool get searchable => fields['searchable'] is! num || fields['searchable'] != 0;
  bool get quickSearch => fields['quickSearch'] is! num || fields['quickSearch'] != 0;
  bool get filterable => fields['filterable'] is! num || fields['filterable'] != 0;

  /// play_parse：播放地址需 lazy/嗅探再解析（docs/04 §4.3）。
  bool get playParse => fields['play_parse'] is! num || fields['play_parse'] != 0;

  /// double 模式（线路/选集交错解析）—— v0.1 不支持，运行期明确提示。
  /// 与 searchable 等「缺省为开」相反：缺省关闭，仅显式 1/true 开启。
  bool get double {
    final v = fields['double'];
    return v == 1 || v == true || v == '1' || v == 'true';
  }

  /// 分类名（class_name，`&` 分隔）与分类 URL 段（class_url，同序）。
  List<String> get classNames => _ampList(fields['class_name']);
  List<String> get classUrls => _ampList(fields['class_url']);

  static List<String> _ampList(Object? v) =>
      (v as String?)?.split('&').where((e) => e.trim().isNotEmpty).toList() ?? const [];

  /// 读取字段原文（js: 片段/模板串/对象）。
  Object? field(String key) => fields[key];

  /// 字段是否 js: 内联代码。
  bool isJs(String key) => field(key) is String && (field(key) as String).trimLeft().startsWith('js:');

  /// 取 js: 片段代码（剥去 `js:` 前缀）；非 js 字段返回 null。
  String? jsCode(String key) {
    final v = field(key);
    if (v is! String) return null;
    final t = v.trimLeft();
    return t.startsWith('js:') ? t.substring(3) : null;
  }

  /// 对象形态字段（`二级:{title,img,…}` / `headers`）。
  Map<String, dynamic>? mapField(String key) {
    final v = fields[key];
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      final s = v.trim();
      if (s.startsWith('{') && s.endsWith('}')) {
        try {
          final decoded = jsonDecode(_toStrictJson(s));
          if (decoded is Map<String, dynamic>) return decoded;
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }

  /// tab_remove：线路名黑名单（`|` 分隔，按包含匹配）。
  List<String> get tabRemove => _pipeList(fields['tab_remove']);

  /// tab_order：线路排序白名单（按此顺序前置，未列出的保持原序）。
  List<String> get tabOrder => _pipeList(fields['tab_order']);

  /// tab_rename：改名映射（`旧&新#旧&新`）。
  Map<String, String> get tabRename {
    final raw = _str('tab_rename');
    if (raw == null || raw.trim().isEmpty) return const {};
    final out = <String, String>{};
    for (final pair in raw.split('#')) {
      final parts = pair.split('&');
      if (parts.length == 2 && parts[0].isNotEmpty) {
        out[parts[0].trim()] = parts[1].trim();
      }
    }
    return out;
  }

  static List<String> _pipeList(Object? v) =>
      (v as String?)?.split('|').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList() ?? const [];

  /// 是否纯模板源：任一关键字段含 `js:` 内联代码即为否。
  /// 纯模板源可由原生模板执行器运行；否则需 QuickJS（docs/09 M3-4 决策）。
  bool get isTemplateOnly {
    const jsKeys = ['预处理', '推荐', '一级', '二级', '搜索', 'lazy', 'class_parse', 'proxy_rule', 'play_parse_js'];
    for (final key in jsKeys) {
      if (isJs(key)) return false;
    }
    return true;
  }

  /// 需要执行的关键 js 字段（诊断文案用）。
  String? get firstJsField {
    const jsKeys = ['预处理', '推荐', '一级', '二级', '搜索', 'lazy', 'class_parse'];
    for (final key in jsKeys) {
      if (isJs(key)) return key;
    }
    return null;
  }
}

/// 提取从 [start] 开始的第一个配平大括号块（忽略字符串字面量内的花括号）。
String? _balancedBraces(String text, int start) {
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

/// JS 对象字面量 → 严格 JSON：
/// 1) 去注释（字符串内的 `//` 不受影响，如 `https://` 链接）；
/// 2) 裸键加双引号；3) 单引号字符串转双引号；4) 反引号模板字面量转双引号；
/// 5) 去尾随逗号。
String _toStrictJson(String literal) {
  var text = _stripComments(literal);
  text = _quoteBareKeys(text);
  text = _singleToDoubleQuotes(text);
  text = _backtickToDoubleQuotes(text);
  text = _escapeControlCharsInStrings(text);
  text = text.replaceAllMapped(RegExp(r',\s*([}\]])'), (m) => m.group(1)!);
  return text;
}

String _stripComments(String text) {
  final out = StringBuffer();
  var inString = false;
  var stringChar = '';
  var escaped = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      out.write(ch);
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
      out.write(ch);
      continue;
    }
    if (ch == '/' && i + 1 < text.length && text[i + 1] == '/') {
      while (i < text.length && text[i] != '\n') {
        i++;
      }
      out.write('\n');
      i--;
      continue;
    }
    out.write(ch);
  }
  return out.toString();
}

final _bareKey = RegExp(r'''(?<=[{,\n])(\s*)([A-Za-z_\u4e00-\u9fff][\w\u4e00-\u9fff]*)\s*:''');

/// 在 JSON 字符串值内转义原始控制字符（U+0000-U+001F），保证 jsonDecode 合法。
String _escapeControlCharsInStrings(String text) {
  final out = StringBuffer();
  var inString = false;
  var stringChar = '';
  var escaped = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      if (escaped) {
        escaped = false;
        out.write(ch);
      } else if (ch == r'\') {
        escaped = true;
        out.write(ch);
      } else if (ch == stringChar) {
        inString = false;
        out.write(ch);
      } else {
        final code = ch.codeUnitAt(0);
        if (code < 32) {
          switch (code) {
            case 10: out.write(r'\n'); break;
            case 13: out.write(r'\r'); break;
            case 9:  out.write(r'\t'); break;
            default: out.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
          }
        } else {
          out.write(ch);
        }
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
      stringChar = ch;
      out.write(ch);
      continue;
    }
    out.write(ch);
  }
  return out.toString();
}

String _quoteBareKeys(String text) =>
    text.replaceAllMapped(_bareKey, (m) => '${m.group(1)}"${m.group(2)}":');

/// 单引号字符串 → 双引号（转义内部双引号与反斜杠）。
String _singleToDoubleQuotes(String text) {
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (ch == "'") {
      out.write('"');
      i++;
      var closed = false;
      while (i < text.length && !closed) {
        final c = text[i];
        if (c == r'\') {
          out.write(r'\\');
          out.write(text[i + 1]);
          i += 2;
          continue;
        }
        if (c == '"') {
          out.write(r'\"');
          i++;
          continue;
        }
        if (c == "'") {
          out.write('"');
          closed = true;
          i++;
          continue;
        }
        out.write(c);
        i++;
      }
      continue;
    }
    out.write(ch);
    i++;
  }
  return out.toString();
}

/// 反引号模板字符串 → 双引号（JS 模板字面量，drpy 源常用 js: 前缀值）。
String _backtickToDoubleQuotes(String text) {
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (ch == '`') {
      out.write('"');
      i++;
      var closed = false;
      while (i < text.length && !closed) {
        final c = text[i];
        if (c == r'\') {
          out.write(r'\\');
          if (i + 1 < text.length) {
            out.write(text[i + 1]);
            i += 2;
          } else {
            i++;
          }
          continue;
        }
        if (c == '"') {
          out.write(r'\"');
          i++;
          continue;
        }
        if (c == '`') {
          out.write('"');
          closed = true;
          i++;
          continue;
        }
        out.write(c);
        i++;
      }
      continue;
    }
    out.write(ch);
    i++;
  }
  return out.toString();
}
