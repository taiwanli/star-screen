import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

/// drpy pdfh/pdfa 规则求值器（子集，docs/04 §4.3 注入 API 的原生实现）。
///
/// 语法：段用 `&&` 连接（层级下钻）；段 = tag / .cls / tag.cls / #id / 组合；
/// 支持模板生态高频的 `:eq(n)` 下标（`.module-play-list:eq(#id)` 解析二级时
/// 由执行器先把 `#id` 替换为数字下标）；末段取值后缀：`Text`（文本）/
/// `html`（内HTML）/ 属性名（href、src、data-src…）。
/// 例：`body&&.module-item`（列表）、`a&&href`、`.module-play-list:eq(0)&&a&&Text`。
///
/// 依赖 package:html 的 querySelectorAll（标准 CSS 选择器子集）——
/// 零 JS 引擎、三端可用；给「纯模板 drpy 源」「js: 片段的 pdfh 注入」共用。
abstract final class PdfhEngine {
  static final _eqSeg = RegExp(r'^(.+?):eq\((-?\d+)\)(.*)$');

  /// pdfa：列表规则 → 命中的元素列表。
  static List<Element> pdfa(String html, String rule) {
    final doc = parser.parse(html);
    return pdfaIn(doc.documentElement, rule);
  }

  /// 在已解析文档上求值列表规则（docs/13 D1：避免逐元素重复全文解析）。
  static List<Element> pdfaIn(Element? root, String rule) {
    if (root == null) return const [];
    var current = <Element>[root];
    for (final seg in rule.split('&&')) {
      current = _applySegment(current, seg.trim());
      if (current.isEmpty) return const [];
    }
    return current;
  }

  /// pdfh：字段规则 → 单值（取首个命中）。
  /// 整条规则仅为取值后缀（`Text`/`html`/属性名）时，对 [root] 自身取值
  /// —— tabs 拆分后的后缀回填依赖该语义。
  static String? pdfh(Element root, String rule) {
    final parts = rule.split('&&').map((e) => e.trim()).toList();
    if (parts.length == 1) {
      final only = _valueSpec(parts[0]);
      if (only != null) return _valueOf(root, only);
    }
    final valueSpec = parts.length > 1 ? _valueSpec(parts.last) : null;
    final selectors = valueSpec == null ? parts : parts.sublist(0, parts.length - 1);
    Element? current = root;
    for (final seg in selectors) {
      if (seg.isEmpty) continue;
      final hits = _applySegment([current!], seg);
      if (hits.isEmpty) return null;
      current = hits.first;
    }
    if (current == null) return null;
    return valueSpec == null ? current.text.trim() : _valueOf(current, valueSpec);
  }

  static String? _valueOf(Element el, String valueSpec) {
    return switch (valueSpec.toLowerCase()) {
      'text' => el.text.trim(),
      'html' => el.innerHtml,
      _ => el.attributes[valueSpec],
    };
  }

  /// 单段求值：含 `:eq(n)` 时先取全集再按下标挑选（package:html 不支持 :eq）。
  static List<Element> _applySegment(List<Element> current, String seg) {
    if (seg.isEmpty) return current;
    final eq = _eqSeg.firstMatch(seg);
    if (eq == null) {
      final next = <Element>[];
      for (final el in current) {
        next.addAll(el.querySelectorAll(seg));
      }
      return next;
    }
    final matched = <Element>[];
    for (final el in current) {
      matched.addAll(el.querySelectorAll(eq.group(1)!));
    }
    final index = int.parse(eq.group(2)!);
    final picked = <Element>[];
    if (index >= 0 && index < matched.length) picked.add(matched[index]);
    final rest = (eq.group(3) ?? '').trim();
    if (rest.isEmpty || picked.isEmpty) return picked;
    return [for (final el in picked) ...el.querySelectorAll(rest)];
  }

  /// 末段是取值后缀（Text/html/属性名）时返回后缀名，否则 null。
  static String? _valueSpec(String part) {
    if (part.isEmpty) return null;
    if (part == 'Text' || part == 'text') return 'Text';
    if (part == 'html') return 'html';
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(part)) return part;
    return null;
  }
}
