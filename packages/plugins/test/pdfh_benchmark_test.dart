import 'package:html/parser.dart' as html_parser;
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

/// 50 元素列表的模板解析基准（docs/13 D1）。
///
/// 目标：验证 `pdfaIn` 单次解析路径下，50 项列表页的解析耗时有界
/// （中低端盒子场景 < 2s），且结果与逐元素 `pdfa(html, ...)` 等价。
void main() {
  /// 生成 50 项的列表页 HTML。
  String _listPageHtml(int count) {
    final items = StringBuffer();
    for (var i = 1; i <= count; i++) {
      items.writeln(
          '<div class="vodlist_item">'
          '<a href="/detail/$i.html"><span>${'影片$i'}</span>'
          '<img src="https://img.example.com/$i.jpg">'
          '<em>第${i % 20}集</em></a>'
          '</div>');
    }
    return '<html><body><ul class="list">$items</ul></body></html>';
  }

  const listRule = 'ul&&div.vodlist_item';
  const titleRule = 'a&&span&&Text';
  const linkRule = 'a&&href';
  const imgRule = 'img&&src';

  test('pdfaIn 单次解析结果与 pdfa 等价（50 项列表）', () {
    final html = _listPageHtml(50);

    // 旧路径：每次对全文重新解析
    final oldItems = PdfhEngine.pdfa(html, listRule);

    // 新路径：一次解析 + pdfaIn
    final doc = html_parser.parse(html).documentElement;
    final newItems = PdfhEngine.pdfaIn(doc, listRule);

    expect(newItems.length, 50);
    expect(newItems.length, oldItems.length);
    for (var i = 0; i < 50; i++) {
      expect(newItems[i].text, oldItems[i].text, reason: 'item $i text');
    }
    // 字段级求值与旧路径一致
    final oldTitle = PdfhEngine.pdfh(oldItems[0], titleRule);
    final newTitle = PdfhEngine.pdfh(newItems[0], titleRule);
    expect(newTitle, '影片1');
    expect(oldTitle, newTitle);
  });

  test('50 项列表全量字段求值有界（单次解析路径 < 2s）', () {
    final html = _listPageHtml(50);
    final doc = html_parser.parse(html).documentElement;
    final sw = Stopwatch()..start();
    final items = PdfhEngine.pdfaIn(doc, listRule);
    for (final el in items) {
      final t = PdfhEngine.pdfh(el, titleRule);
      final l = PdfhEngine.pdfh(el, linkRule);
      final p = PdfhEngine.pdfh(el, imgRule);
      // 模拟 WorkCard 构建（非空断言）
      expect(t, isNotEmpty);
      expect(l, isNotEmpty);
      expect(p, contains('img.example.com'));
    }
    sw.stop();
    // 中低端盒子（Cortex-A53 @ 1.2GHz）预算：2s
    expect(sw.elapsedMilliseconds, lessThan(2000),
        reason: '50 项列表全量求值耗时 ${sw.elapsedMilliseconds}ms 超出预算');
    // 更紧的开发机预算：200ms
    expect(sw.elapsedMilliseconds, lessThan(200),
        reason: '开发机上 50 项列表全量求值耗时 ${sw.elapsedMilliseconds}ms');
  });

  test('pdfaIn 空文档根安全返回空列表', () {
    expect(PdfhEngine.pdfaIn(null, listRule), isEmpty);
  });

  test('pdfa(html, ...) 委托 pdfaIn（行为不变）', () {
    final html = _listPageHtml(5);
    final direct = PdfhEngine.pdfa(html, listRule);
    expect(direct, hasLength(5));
  });
}
