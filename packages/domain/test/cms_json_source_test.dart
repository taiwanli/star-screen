import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

import 'helpers.dart';

SourceDef _def() => const SourceDef(
      key: 'demo',
      name: '演示CMS',
      kind: SourceKind.cmsJson,
      endpoint: 'https://demo.example.com/api.php/provide/vod',
      headers: {'User-Agent': 'StarScreen/Test'},
    );

void main() {
  group('CmsJsonSource —— 分类与分页（maccms_list 样本）', () {
    late FakeHttpFetch http;
    late CmsJsonSource source;

    setUp(() {
      final body = fixture('maccms_list.json').readAsStringSync();
      http = FakeHttpFetch((url) => FetchResult(url: url, statusCode: 200, body: body));
      source = CmsJsonSource(def: _def(), http: http);
    });

    test('category：t/pg 参数正确，分页字段与卡片归一', () async {
      final result = await source.category(
          const CategoryQuery(typeId: '38', page: 2, filters: {'year': '2026'}));

      expect(http.requested.single.queryParameters['t'], '38');
      expect(http.requested.single.queryParameters['pg'], '2');
      expect(http.requested.single.queryParameters['year'], '2026');
      expect(http.requested.single.queryParameters['ac'], 'list');

      // 请求带 pg=2；fixture 响应体是静态样本（page=1）
      expect(result.page, 1);
      expect(result.pageCount, 8018);
      expect(result.total, 160358);
      expect(result.hasMore, isTrue);
      expect(result.items, hasLength(2));
      expect(result.items.first.title, '乌鸦俱乐部');
      expect(result.items.first.remarks, '更新至第2集');
      expect(result.items.first.sourceKey, 'demo');
      expect(result.items.first.workKey, 'demo::163403');
    });

    test('home：ac=list 首页推荐流', () async {
      final feed = await source.home();
      expect(feed.recommend, hasLength(2));
      expect(http.requested.single.queryParameters['pg'], '1');
    });

    test('code!=1 抛 FetchException', () async {
      final bad = CmsJsonSource(
        def: _def(),
        http: FakeHttpFetch((url) => FetchResult(
            url: url, statusCode: 200, body: '{"code":0,"msg":"error"}')),
      );
      await expectLater(bad.home(), throwsA(isA<FetchException>()));
    });
  });

  group('CmsJsonSource —— 搜索（total 缺失容错）', () {
    test('缺 total 字段时按 items 判断 hasMore', () async {
      final source = CmsJsonSource(
        def: _def(),
        http: FakeHttpFetch((url) => FetchResult(
              url: url,
              statusCode: 200,
              // 实测 suoni：搜索响应无 total
              body: '{"code":1,"page":1,"pagecount":9,'
                  '"list":[{"vod_id":1,"vod_name":"光阴之外","type_id":6}]}',
            )),
      );
      final result = await source.search('光阴之外');
      expect(result.total, isNull);
      expect(result.pageCount, 9);
      expect(result.hasMore, isTrue);
      expect(result.items.first.title, '光阴之外');
      expect(result.items.first.genre, isNull);
    });
  });

  group('CmsJsonSource —— 详情与播放地址解析（M1-2）', () {
    late FakeHttpFetch http;
    late CmsJsonSource source;

    setUp(() {
      final body = fixture('maccms_detail.json').readAsStringSync();
      http = FakeHttpFetch((url) => FetchResult(url: url, statusCode: 200, body: body));
      source = CmsJsonSource(def: _def(), http: http);
    });

    test(r'detail：$$$ 双线路归一，# 与 $ 解析选集', () async {
      final workDetail = await source.detail('163403');

      expect(http.requested.single.queryParameters['ids'], '163403');
      expect(workDetail.lines, hasLength(2));
      expect(workDetail.lines[0].name, '暴风m3u8');
      expect(workDetail.lines[1].name, '最大m3u8');
      expect(workDetail.lines[0].episodes, hasLength(2));
      expect(workDetail.lines[0].episodes[0].name, '第1集');
      expect(workDetail.lines[0].episodes[0].url,
          'https://cdn.example.com/v/ep1/index.m3u8');
      expect(workDetail.lines[1].episodes.single.name, '正片');
      expect(workDetail.card.score, '7.8');
      expect(workDetail.actor, '甲,乙,丙');
    });

    test('resolve：直连 m3u8 → needsParse=false', () async {
      final candidate =
          await source.resolve(const PlayRequest(workId: '163403', episodeIndex: 1));
      expect(candidate.url, 'https://cdn.example.com/v/ep2/index.m3u8');
      expect(candidate.needsParse, isFalse);
    });

    test('resolve：网页地址 → needsParse=true（合规默认过滤标记）', () async {
      final webSource = CmsJsonSource(
        def: _def(),
        http: FakeHttpFetch((url) => FetchResult(
              url: url,
              statusCode: 200,
              body: '{"code":1,"list":[{"vod_id":9,"vod_name":"网页源",'
                  '"vod_play_from":"youku",'
                  '"vod_play_url":"正片\$https://v.example.com/play/9.html"}]}',
            )),
      );
      final candidate = await webSource.resolve(const PlayRequest(workId: '9', episodeIndex: 0));
      expect(candidate.needsParse, isTrue);
    });

    test('parseLines：list 模式 , 分隔的兼容分支', () {
      final lines = CmsJsonSource.parseLines(
        from: 'bfzym3u8,snm3u8',
        urls: '第1集\$https://a/1.m3u8#第2集\$https://a/2.m3u8,第1集\$https://b/1.m3u8',
      );
      expect(lines, hasLength(2));
      expect(lines[0].episodes, hasLength(2));
      expect(lines[1].episodes.single.url, 'https://b/1.m3u8');
    });

    test('parseLines：空名选集回退「第N集」', () {
      final lines = CmsJsonSource.parseLines(
        from: 'm3u8',
        urls: '\$https://a/1.m3u8#\$https://a/2.m3u8',
      );
      expect(lines.single.episodes.map((e) => e.name), ['第1集', '第2集']);
    });
  });

  group('CmsJsonSource —— AppYsV2 变体', () {
    test('列表位于 data.list', () async {
      final def = const SourceDef(
        key: 'appys',
        name: 'AppYs',
        kind: SourceKind.cmsJson,
        cmsVariant: CmsVariant.appysV2,
        endpoint: 'https://appys.example.com/api.php/v1.vod',
      );
      final source = CmsJsonSource(
        def: def,
        http: FakeHttpFetch((url) => FetchResult(
              url: url,
              statusCode: 200,
              body: '{"code":1,"data":{"list":'
                  '[{"vod_id":7,"vod_name":"AppYs影片","type_name":"剧情"}]}}',
            )),
      );
      final result = await source.category(const CategoryQuery());
      expect(result.items.single.title, 'AppYs影片');
    });
  });
}
