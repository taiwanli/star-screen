import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

const _drpySrc = r'''
var rule = {
    title: '豆瓣',
    host: 'https://movie.example.com',
    url: '/list/fyclass/fypage.html',
    searchUrl: '/search/**/fypage.html',
    detailUrl: '/detail/fyid.html',
    searchable: 1,
    quickSearch: 0,
    filterable: 1,
    class_name: '电影&剧集',
    class_url: '1&2',
    headers: { 'User-Agent': 'okhttp/4.0' },
    一级: '.module-item;.module-title&&Text;img&&data-src;.module-note&&Text;a&&href',
    二级: '*;h1&&Text;.poster&&img&&src;.intro&&Text;.intro&&Text;.tabs&&span;.playlist:eq(#id)&&a;;a&&Text;a&&href',
    搜索: '.module-item;.module-title&&Text;img&&data-src;.module-note&&Text;a&&href',
}
''';

void main() {
  group('DrpyToStarRule', () {
    test('纯模板源可全自动转译', () {
      final r = DrpyToStarRule.convertSource(_drpySrc);
      expect(r.rule.convertedFrom, 'drpy');
      expect(r.rule.meta.name, '豆瓣');
      expect(r.rule.site.host, 'https://movie.example.com');

      // url 模板占位符
      expect(r.rule.category!.url, contains('{cateId}'));
      expect(r.rule.category!.url, contains('{catePg}'));
      expect(r.rule.search!.url, contains('{wd}'));

      // class_name & class_url
      final manual = r.rule.home!.categories!.manual;
      expect(manual['电影'], '1');
      expect(manual['剧集'], '2');

      // 一级 片段 → category items
      expect(r.rule.category!.items.list.sel, '.module-item');
      expect(r.rule.category!.items.title.sel, '.module-title&&Text');
      expect(r.rule.category!.items.id.sel, 'a&&href');

      // headers
      expect(r.rule.site.headers['User-Agent'], 'okhttp/4.0');
    });

    test('转译结果可被 StarRuleImporter 消费', () {
      final r = DrpyToStarRule.convertSource(_drpySrc);
      final def = StarRuleImporter.toSourceDef(r.rule);
      expect(def.kind, SourceKind.starRule);
      expect(def.caps.searchable, isTrue);
      expect(def.caps.quickSearch, isFalse);
    });

    test('含 js: 字段记 issue 并进 script', () {
      const withJs = r'''
      var rule = {
        title: 'js源',
        host: 'https://x.example.com',
        url: '/list/fyclass/fypage.html',
        一级: 'js:let a=1',
        二级: '*',
      }
      ''';
      final r = DrpyToStarRule.convertSource(withJs);
      expect(r.rule.convertedFrom, 'drpy');
      expect(r.issues, isNotEmpty);
      expect(r.rule.raw['script'], isNotNull);
    });
  });
}
