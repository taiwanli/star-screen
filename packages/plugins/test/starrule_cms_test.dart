import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

class _FakeHttp implements HttpFetch {
  final Map<String, String> byQuery;
  final List<String> urls = [];
  _FakeHttp(this.byQuery);

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    urls.add(url.toString());
    final key = url.queryParameters['ac'] ?? '';
    final body = byQuery[key] ?? byQuery[url.toString()] ?? '{}';
    return FetchResult(
        url: url, statusCode: 200, body: body, headers: const {});
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
  const ruleJson = r'''
  {
    "starrule": 1,
    "meta": { "id": "cms.t", "name": "T" },
    "sourceType": "cms",
    "site": { "host": "https://api.example.com/api.php/provide/vod" }
  }
  ''';

  StarRuleSource source(_FakeHttp http) {
    final rule = StarRuleParser.parse(ruleJson).rule;
    final def = StarRuleImporter.toSourceDef(rule);
    return StarRuleSource(def: def, rule: rule, http: http);
  }

  test('CMS home 走 ac=list', () async {
    final http = _FakeHttp({
      'list': r'{"code":1,"list":[{"vod_id":1,"vod_name":"片A","vod_pic":"p"}]}',
    });
    final s = source(http);
    final feed = await s.home();
    expect(feed.recommend, hasLength(1));
    expect(feed.recommend.first.title, '片A');
    expect(http.urls.single, contains('ac=list'));
  });

  test('CMS search/detail/线路', () async {
    final http = _FakeHttp({
      'detail': r'''{"code":1,"list":[{
        "vod_id":9,"vod_name":"片B",
        "vod_play_from":"线路1$$$线路2",
        "vod_play_url":"E1$https://c/1.m3u8#E2$https://c/2.m3u8$$$F1$https://c/3.m3u8"
      }]}''',
    });
    final s = source(http);
    final page = await s.search('片');
    expect(page.items.single.workId, '9');
    final d = await s.detail('9');
    expect(d.card.title, '片B');
    expect(d.lines, hasLength(2));
    expect(d.lines[0].episodes, hasLength(2));
    expect(d.lines[1].episodes.single.url, 'https://c/3.m3u8');
  });
}
