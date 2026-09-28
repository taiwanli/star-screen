import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

void main() {
  group('DrpyRuleParser —— rule 对象字面量（docs/09 M3-4 地基）', () {
    test('模板源：裸键/单引号/尾逗号/注释 全部容错', () {
      const source = '''
// 一个模板源
var rule = {
    title:'模板演示',
    host:'https://demo.example.com',
    homeUrl:'',
    url:'/fyclass/fypage.html',
    searchable:1,
    quickSearch:1,
    filterable:1,
    class_name:'电影&剧集',   // 行内注释
    class_url:'1&2',
    一级:'.module-item;.module-item-title&&Text;img&&data-src;.module-item-note&&Text;a&&href',
    二级:'',
    搜索:'',
}
''';
      final rule = DrpyRuleParser.parse(source);
      expect(rule, isNotNull);
      expect(rule!.title, '模板演示');
      expect(rule.host, 'https://demo.example.com');
      expect(rule.url, '/fyclass/fypage.html');
      expect(rule.searchable, isTrue);
      expect(rule.classNames, ['电影', '剧集']);
      expect(rule.classUrls, ['1', '2']);
      expect(rule.isTemplateOnly, isTrue);
    });

    test('js: 内联代码 → 非模板源（需 QuickJS，docs/09 M3-4）', () {
      const source = '''
var rule = {
    title:'js源',
    host:'https://frodo.douban.com',
    一级:'js:let d=[];miniapp_request("/x",{});setResult2(res);',
    二级:'*',
}
''';
      final rule = DrpyRuleParser.parse(source);
      expect(rule, isNotNull);
      expect(rule!.isTemplateOnly, isFalse);
    });

    test('嵌套对象（filter）与双引号字符串', () {
      const source = """
var rule = {
    title:'带筛选',
    host:'https://x.example.com',
    filter:{"类型":[{"n":"全部","v":""}]},
    searchable:0,
}
""";
      final rule = DrpyRuleParser.parse(source);
      expect(rule, isNotNull);
      expect(rule!.searchable, isFalse);
      expect(rule.fields['filter'], isA<Map<String,dynamic>>());
    });

    test('无 rule 声明返回 null', () {
      expect(DrpyRuleParser.parse('console.log(1)'), isNull);
    });

    test('字符串内的花括号与引号不破坏配平', () {
      const source = '''
var rule = {
    title:'含 { } 与 " 引号',
    host:"https://y.example.com",
    二级:"*",
}
''';
      final rule = DrpyRuleParser.parse(source);
      expect(rule, isNotNull);
      expect(rule!.title, '含 { } 与 " 引号');
    });
  });
}
