import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

class _FakeHttp implements HttpFetch {
  final Map<String, String> pages;
  _FakeHttp(this.pages);

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
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

const _ruleJson = r'''
{
  "starrule": 1,
  "meta": { "id": "demo.html.movies", "name": "示例HTML站" },
  "sourceType": "html",
  "site": { "host": "https://site.example.com" },
  "home": {
    "url": "/",
    "recommend": {
      "list": "body&&.module-item",
      "title": ".title&&Text",
      "id": "a&&href",
      "cover": "img&&data-src"
    },
    "categories": { "mode": "manual", "manual": { "电影": "1" } }
  },
  "category": {
    "url": "/type/{cateId}-{catePg}.html",
    "list": "body&&.module-item",
    "title": ".title&&Text",
    "id": "a&&href",
    "cover": "img&&data-src"
  },
  "detail": {
    "url": "/detail/{vid}.html",
    "title": "h1&&Text",
    "desc": ".intro&&Text",
    "lines": {
      "list": ".tabs&&span",
      "name": "Text",
      "episodes": {
        "list": ".playlist:eq(#line)&&a",
        "name": "Text",
        "url": "href"
      }
    }
  },
  "search": {
    "url": "/search/{wd}.html",
    "list": "body&&.module-item",
    "title": ".title&&Text",
    "id": "a&&href"
  }
}
''';

const _homeHtml = '''
<html><body>
  <div class="module-item">
    <a href="/detail/1.html"><img data-src="/p/1.jpg"/></a>
    <div class="title">片名一</div>
    <div class="note">更新至2集</div>
  </div>
  <div class="module-item">
    <a href="/detail/2.html"><img data-src="/p/2.jpg"/></a>
    <div class="title">片名二</div>
    <div class="note">HD</div>
  </div>
</body></html>
''';

const _detailHtml = '''
<html><body>
  <h1>片名一</h1>
  <div class="intro">简介文字</div>
  <div class="tabs"><span>线路A</span><span>线路B</span></div>
  <div class="playlist">
    <a href="https://cdn.example.com/1.m3u8">第1集</a>
    <a href="https://cdn.example.com/2.m3u8">第2集</a>
  </div>
  <div class="playlist">
    <a href="https://cdn.example.com/b1.m3u8">B第1集</a>
  </div>
</body></html>
''';

void main() {
  final parsed = StarRuleParser.parse(_ruleJson);
  final rule = parsed.rule;
  final def = StarRuleImporter.toSourceDef(rule);

  StarRuleSource source(Map<String, String> pages) =>
      StarRuleSource(def: def, rule: rule, http: _FakeHttp(pages));

  test('home 解析推荐流', () async {
    final s = source({'/': _homeHtml});
    final feed = await s.home();
    expect(feed.recommend, hasLength(2));
    expect(feed.recommend.first.title, '片名一');
    expect(feed.recommend.first.workId, '/detail/1.html');
    expect(feed.recommend.first.posterUrl, contains('/p/1.jpg'));
  });

  test('category 按模板取片单', () async {
    final s = source({'/type/1-1.html': _homeHtml});
    final page = await s.category(const CategoryQuery(typeId: '1', page: 1));
    expect(page.items, hasLength(2));
  });

  test('detail 取标题/简介/双线路', () async {
    final s = source({'/detail/1.html': _detailHtml});
    // workId 与 home 抽出的 href 一致（相对路径）
    final d = await s.detail('/detail/1.html');
    expect(d.card.title, '片名一');
    expect(d.content, '简介文字');
    expect(d.lines, hasLength(2));
    expect(d.lines[0].name, '线路A');
    expect(d.lines[0].episodes, hasLength(2));
    expect(d.lines[1].episodes, hasLength(1));
  });

  test('resolve 直链 needsParse=false', () async {
    final s = source({'/detail/1.html': _detailHtml});
    final cand = await s.resolve(
      const PlayRequest(workId: '/detail/1.html', episodeIndex: 0),
    );
    expect(cand.url, 'https://cdn.example.com/1.m3u8');
    expect(cand.needsParse, isFalse);
  });

  test('search 解析', () async {
    // search.url 模板 `/search/{wd}.html`，占位符已 URL 编码
    final s = source({'/search/%E7%88%B1.html': _homeHtml});
    final page = await s.search('爱');
    expect(page.items, hasLength(2));
  });
}
