import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

class _FakeHttp implements HttpFetch {
  final Map<String, String> pages;
  final List<Uri> calls = [];
  _FakeHttp(this.pages);

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    calls.add(url);
    final body = pages[url.path] ?? pages[url.toString()] ?? '';
    return FetchResult(
      url: url,
      statusCode: 200,
      body: body,
      headers: const {},
    );
  }

  @override
  Future<FetchResult> post(
    Uri url, {
    String body = '',
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) =>
      get(url);
}

void main() {
  group('detail URL 模板', () {
    test('数字 id 走 {vid} 模板，不被误判为路径', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.tpl", "name": "T" },
        "sourceType": "html",
        "site": { "host": "https://site.example.com" },
        "category": {
          "url": "/c/{cateId}-{catePg}.html",
          "list": "body&&.item",
          "title": "Text",
          "id": "a&&href"
        },
        "detail": {
          "url": "/detail/{vid}.html",
          "title": "h1&&Text",
          "lines": { "flat": true, "episodes": {
            "list": "body&&a", "name": "Text", "url": "href"
          }}
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/detail/123.html':
            '<html><body><h1>片</h1><a href="https://c/1.m3u8">1</a></body></html>',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http);
      final d = await src.detail('123');
      expect(d.card.title, '片');
      expect(http.calls.single.path, '/detail/123.html');
    });

    test('模板自带扩展名时剥离 id 尾缀，避免叠拼', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.ext", "name": "T" },
        "sourceType": "html",
        "site": { "host": "https://site.example.com" },
        "category": {
          "url": "/c/{cateId}-{catePg}.html",
          "list": "body&&.item",
          "title": "Text",
          "id": "a&&href"
        },
        "detail": {
          "url": "/detail/{vid}.html",
          "title": "h1&&Text",
          "lines": { "flat": true, "episodes": {
            "list": "body&&a", "name": "Text", "url": "href"
          }}
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/detail/123.html':
            '<html><body><h1>片</h1><a href="u">1</a></body></html>',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http);
      await src.detail('123.html');
      expect(http.calls.single.path, '/detail/123.html');
    });

    test('以 / 开头的 workId 直接请求', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.path", "name": "T" },
        "sourceType": "html",
        "site": { "host": "https://site.example.com" },
        "category": {
          "url": "/c/{cateId}-{catePg}.html",
          "list": "body&&.item",
          "title": "Text",
          "id": "a&&href"
        },
        "detail": {
          "url": "/detail/{vid}.html",
          "title": "h1&&Text",
          "lines": { "flat": true, "episodes": {
            "list": "body&&a", "name": "Text", "url": "href"
          }}
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/detail/9.html':
            '<html><body><h1>片</h1><a href="u">1</a></body></html>',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http);
      await src.detail('/detail/9.html');
      expect(http.calls.single.path, '/detail/9.html');
    });
  });

  group('分页 hasMore', () {
    test('模板无 {catePg} 时 pageCount=1，不再续页', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.nopg", "name": "T" },
        "sourceType": "html",
        "site": { "host": "https://site.example.com" },
        "category": {
          "url": "/list.html",
          "list": "body&&.item",
          "title": "Text",
          "id": "a&&href",
          "hasMore": "auto"
        },
        "detail": {
          "url": "/d/{vid}.html",
          "title": "h1&&Text",
          "lines": { "flat": true, "episodes": {
            "list": "body&&a", "name": "Text", "url": "href"
          }}
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/list.html':
            '<html><body><div class="item">x</div></body></html>',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http);
      final page = await src.category(const CategoryQuery(typeId: '1', page: 1));
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
      expect(page.pageCount, 1);
    });

    test('hasMore=none 单页', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.none", "name": "T" },
        "sourceType": "html",
        "site": { "host": "https://site.example.com" },
        "category": {
          "url": "/c/{catePg}.html",
          "list": "body&&.item",
          "title": "Text",
          "id": "a&&href",
          "hasMore": "none"
        },
        "detail": {
          "url": "/d/{vid}.html",
          "title": "h1&&Text",
          "lines": { "flat": true, "episodes": {
            "list": "body&&a", "name": "Text", "url": "href"
          }}
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/c/1.html': '<html><body><div class="item">x</div></body></html>',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http);
      final page = await src.category(const CategoryQuery(page: 1));
      expect(page.hasMore, isFalse);
    });
  });

  group('字段后处理', () {
    test(r'regex + replace 模板 $1', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.re", "name": "T" },
        "sourceType": "html",
        "site": { "host": "https://site.example.com" },
        "category": {
          "url": "/c/{cateId}-{catePg}.html",
          "list": "body&&.item",
          "title": { "sel": "Text", "regex": "^(.+?)\\s*更新", "replace": "$1" },
          "id": "a&&href"
        },
        "detail": {
          "url": "/d/{vid}.html",
          "title": "h1&&Text",
          "lines": { "flat": true, "episodes": {
            "list": "body&&a", "name": "Text", "url": "href"
          }}
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/c/1-1.html':
            '<html><body><div class="item"><a href="x">片名 更新至3集</a></div></body></html>',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http);
      final page = await src.category(const CategoryQuery(typeId: '1', page: 1));
      expect(page.items.single.title, '片名');
    });
  });

  group('CMS 线路分隔', () {
    test(r'$$$ 分线路，# 分集，$ 分集名地址', () async {
      const ruleJson = r'''
      {
        "starrule": 1,
        "meta": { "id": "t.cms", "name": "T" },
        "sourceType": "json",
        "site": { "host": "https://api.example.com" },
        "category": {
          "url": "/list?pg={catePg}",
          "list": "json:data.list",
          "title": "json:name",
          "id": "json:id"
        },
        "detail": {
          "url": "/detail?id={vid}",
          "title": "json:data.name",
          "lines": {
            "fromField": "json:data.play_from",
            "urlField": "json:data.play_url"
          }
        }
      }
      ''';
      final rule = StarRuleParser.parse(ruleJson).rule;
      final def = StarRuleImporter.toSourceDef(rule);
      final http = _FakeHttp({
        '/detail': // path without query; map lookup uses path
            '',
      });
      // use full URL keys
      final http2 = _FakeHttp({
        '/detail':
            r'{"code":1,"data":{"name":"片","play_from":"线路A$$$线路B","play_url":"第1集$https://c/a.m3u8#第2集$https://c/b.m3u8$$$B1$https://c/c.m3u8"}}',
      });
      final src = StarRuleSource(def: def, rule: rule, http: http2);
      // detail url expands to /detail?id=1 — path is /detail
      final d = await src.detail('1');
      expect(d.lines, hasLength(2));
      expect(d.lines[0].name, '线路A');
      expect(d.lines[0].episodes, hasLength(2));
      expect(d.lines[0].episodes[0].name, '第1集');
      expect(d.lines[0].episodes[0].url, 'https://c/a.m3u8');
      expect(d.lines[1].episodes.single.url, 'https://c/c.m3u8');
    });
  });
}
