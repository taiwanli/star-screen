import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import 'helpers.dart';

SourceDef _def() => const SourceDef(
      key: 'xmlsrc',
      name: '演示XML源',
      kind: SourceKind.cmsXml,
      endpoint: 'https://xml.example.com/api.php/provide/vod/at/xml',
    );

void main() {
  group('CmsXmlSource —— rss 5.1 结构（maccms_list.xml 样本）', () {
    late FakeHttpFetch http;
    late CmsXmlSource source;

    setUp(() {
      final body = fixture('maccms_list.xml').readAsStringSync();
      http = FakeHttpFetch((url) => FetchResult(url: url, statusCode: 200, body: body));
      source = CmsXmlSource(def: _def(), http: http);
    });

    test('home：ac=list&at=xml，卡片归一（CDATA/备注）', () async {
      final feed = await source.home();

      expect(http.requested.single.queryParameters['ac'], 'list');
      expect(http.requested.single.queryParameters['at'], 'xml');
      expect(feed.recommend, hasLength(2));
      expect(feed.recommend.first.title, '乌鸦俱乐部');
      expect(feed.recommend.first.remarks, '更新至第2集');
      expect(feed.recommend.first.workKey, 'xmlsrc::163403');
    });

    test('category：t/pg 参数与 list 属性分页', () async {
      final result = await source.category(const CategoryQuery(typeId: '38', page: 3));

      expect(http.requested.single.queryParameters['t'], '38');
      expect(http.requested.single.queryParameters['pg'], '3');
      expect(result.page, 1); // fixture 静态属性 page="1"
      expect(result.pageCount, 8018);
      expect(result.total, 160358);
      expect(result.items, hasLength(2));
    });

    test('search：wd 参数走 videolist 全量', () async {
      final result = await source.search('乌鸦');
      expect(http.requested.single.queryParameters['ac'], 'videolist');
      expect(http.requested.single.queryParameters['wd'], '乌鸦');
      expect(result.items, hasLength(2));
    });

    test('detail：dl/dd → 线路树，flag → 线路名对照', () async {
      final workDetail = await source.detail('163403');

      expect(http.requested.single.queryParameters['ids'], '163403');
      expect(workDetail.lines, hasLength(1));
      expect(workDetail.lines.single.name, '暴风m3u8');
      expect(workDetail.lines.single.episodes, hasLength(2));
      expect(workDetail.lines.single.episodes[1].url,
          'https://cdn.example.com/v/ep2/index.m3u8');
      expect(workDetail.actor, '甲,乙');
    });

    test('resolve：直连 m3u8 → needsParse=false', () async {
      final candidate =
          await source.resolve(const PlayRequest(workId: '163403', episodeIndex: 1));
      expect(candidate.url, 'https://cdn.example.com/v/ep2/index.m3u8');
      expect(candidate.needsParse, isFalse);
    });

    test('classOf：分类树供筛选', () {
      final doc =
          XmlDocument.parse(fixture('maccms_list.xml').readAsStringSync());
      final classes = CmsXmlSource.classOf(doc);
      expect(classes, {'6': '子类1', '38': '剧情'});
    });

    test('V8/MaxCMS 遗留：from 属性 + | 分集（老式兼容，docs/04 §5.3）', () async {
      const legacy = '<?xml version="1.0" encoding="utf-8"?>'
          '<rss version="5.0"><list page="1" pagecount="1" pagesize="20" recordcount="1">'
          '<video><id>66</id><name><![CDATA[老站影片]]></name>'
          '<dl><dd from="m3u8"><![CDATA[a\$https://o.example.com/1.m3u8|b\$https://o.example.com/2.m3u8]]></dd></dl>'
          '</video></list></rss>';
      final source = CmsXmlSource(
        def: _def(),
        http: FakeHttpFetch((url) => FetchResult(url: url, statusCode: 200, body: legacy)),
      );
      final workDetail = await source.detail('66');
      expect(workDetail.lines.single.name, 'm3u8');
      expect(workDetail.lines.single.episodes.map((e) => e.name), ['a', 'b']);
    });
  });
}
