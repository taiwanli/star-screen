import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  test('粘贴 JSON 原文可导入', () async {
    const json = '{"sites":[{"key":"a","name":"A","type":1,"api":"http://x/api.php","searchable":1,"quickSearch":1,"filterable":1}]}';
    final r = await FeedFetcher().fetchSubscription(json);
    expect(r.body, json);
    final report = TvBoxConfigParser.parse(raw: r.body, baseUrl: r.url);
    expect(report.sources, isNotEmpty);
  });

  test('带引号路径被去引号', () async {
    await expectLater(
      FeedFetcher().fetchSubscription('"https://example.invalid/x.json"'),
      throwsA(isA<FetchException>()),
    );
  });
}
