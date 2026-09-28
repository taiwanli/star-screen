import 'dart:async';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class _FakeSource implements VideoSource {
  _FakeSource({
    required this.key,
    this.homeItems = const [],
    this.searchItems = const [],
    this.presetDetail,
    this.playUrl = 'https://cdn.example.com/a.m3u8',
    this.failDetail = false,
    this.failPlay = false,
  });

  final String key;
  final List<WorkCard> homeItems;
  final List<WorkCard> searchItems;
  final WorkDetail? presetDetail;
  final String playUrl;
  final bool failDetail;
  final bool failPlay;

  @override
  SourceDef get def =>
      SourceDef(key: key, name: key, kind: SourceKind.cmsJson);

  @override
  Future<HomeFeed> home() async => HomeFeed(recommend: homeItems);

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async =>
      PageResult(items: searchItems, page: page);

  @override
  Future<WorkDetail> detail(String workId) async {
    if (failDetail) throw StateError('parse 失败');
    return presetDetail ??
        WorkDetail(
          card: WorkCard(sourceKey: key, workId: workId, title: '片'),
          lines: [
            PlayLine(
              lineId: 'L0',
              name: '线',
              episodes: [const Episode(index: 0, name: '1', url: 'u')],
            ),
          ],
        );
  }

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    if (failPlay) throw StateError('播放地址为空');
    return PlayCandidate(url: playUrl);
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async =>
      const PageResult(items: [], page: 1);
}

WorkCard _card(String id) => WorkCard(sourceKey: 's', workId: id, title: '片$id');

void main() {
  group('SourceChecker 四链路（docs/18 §6）', () {
    test('L2 首页有推荐 → 通过（depth=home）', () async {
      final c = SourceChecker(depth: CheckLevel.home);
      final r = await c.check(_FakeSource(
        key: 'a',
        homeItems: [_card('1')],
      ));
      expect(r.ok, isTrue);
      expect(r.code, CheckFailCode.none);
    });

    test('首页空但搜索有结果 → depth=search 通过', () async {
      final c = SourceChecker(depth: CheckLevel.search);
      final r = await c.check(_FakeSource(
        key: 'b',
        searchItems: [_card('2')],
      ));
      expect(r.ok, isTrue);
    });

    test('首页与搜索均空 → empty', () async {
      final c = SourceChecker(depth: CheckLevel.search);
      final r = await c.check(_FakeSource(key: 'c'));
      expect(r.ok, isFalse);
      expect(r.code, CheckFailCode.empty);
      expect(r.reason, contains('无结果'));
    });

    test('depth=detailPlay：详情+播放全通 → ok', () async {
      final c = SourceChecker(depth: CheckLevel.detailPlay);
      final r = await c.check(_FakeSource(
        key: 'd',
        homeItems: [_card('1')],
      ));
      expect(r.ok, isTrue);
    });

    test('depth=detailPlay：播放失败 → 按原因报错', () async {
      final c = SourceChecker(depth: CheckLevel.detailPlay);
      final r = await c.check(_FakeSource(
        key: 'e',
        homeItems: [_card('1')],
        failPlay: true,
      ));
      expect(r.ok, isFalse);
      expect(r.code, CheckFailCode.empty);
    });

    test('超时 → timeout 代码', () async {
      final c = SourceChecker(
        depth: CheckLevel.home,
        timeout: const Duration(milliseconds: 30),
      );
      final slow = _SlowSource();
      final r = await c.check(slow);
      expect(r.ok, isFalse);
      expect(r.code, CheckFailCode.timeout);
    });
  });

  group('tryConvertXpathToStarRule', () {
    test('xpathRule 内联 ext 转为 starRule', () {
      const ext = r'''
      {
        "homeUrl": "https://site.example.com",
        "cateManual": { "电影": "1" },
        "cateUrl": "/type/{cateId}-{catePg}.html",
        "cateVodNode": "body&&.item",
        "cateVodName": ".title&&Text",
        "cateVodId": "a&&href",
        "dtUrl": "/detail/{vid}.html",
        "dtNode": "body",
        "dtName": "h1&&Text",
        "dtFromNode": ".tabs&&span",
        "dtFromName": "Text",
        "dtUrlNode": ".playlist",
        "dtUrlId": "a&&href",
        "dtUrlName": "Text",
        "searchUrl": "/search/{wd}.html",
        "scVodNode": "body&&.item",
        "scVodName": ".title&&Text",
        "scVodId": "a&&href"
      }
      ''';
      final def = SourceDef(
        key: 'xy',
        name: 'XPath站',
        kind: SourceKind.xpathRule,
        extRaw: ext,
        groupId: 'g1',
      );
      final out = tryConvertXpathToStarRule(def);
      expect(out, isNotNull);
      expect(out!.kind, SourceKind.starRule);
      expect(out.key, 'xy'); // 保留原 key
      expect(out.groupId, 'g1');
      expect(out.extRaw, contains('starrule'));
    });

    test('非法 ext 返回 null（保持 xpathRule）', () {
      final def = SourceDef(
        key: 'bad',
        name: '坏',
        kind: SourceKind.xpathRule,
        extRaw: '{not json',
      );
      expect(tryConvertXpathToStarRule(def), isNull);
    });

    test('convertXpathDefs 批量', () {
      const ext = r'''{"homeUrl":"https://x.example.com","cateManual":{"A":"1"},
        "cateUrl":"/c/{cateId}-{catePg}.html","cateVodNode":"body&&.i",
        "cateVodName":"Text","cateVodId":"a&&href","dtUrl":"/d/{vid}.html",
        "dtName":"Text","dtFromNode":"s","dtFromName":"Text",
        "dtUrlNode":"p","dtUrlId":"a&&href","dtUrlName":"Text"}''';
      final (defs, n) = convertXpathDefs([
        SourceDef(key: 'x1', name: 'x', kind: SourceKind.xpathRule, extRaw: ext),
        SourceDef(key: 'c1', name: 'c', kind: SourceKind.cmsJson),
      ]);
      expect(n, 1);
      expect(defs[0].kind, SourceKind.starRule);
      expect(defs[1].kind, SourceKind.cmsJson);
    });
  });

  group('StarRuleDeepLink', () {
    test('识别与解析 starrule://import?url=', () {
      final link = StarRuleDeepLink.build('https://a.com/p.json');
      expect(StarRuleDeepLink.isImportLink(link), isTrue);
      final r = StarRuleDeepLink.parse(link);
      expect(r.url, 'https://a.com/p.json');
    });

    test('src 别名', () {
      final r = StarRuleDeepLink
          .parse('starrule://import?src=https%3A%2F%2Fb.com%2Fx.json');
      expect(r.url, 'https://b.com/x.json');
    });

    test('inline 规则原文', () {
      final r = StarRuleDeepLink.parse('starrule://import?inline={"starrule":1}');
      expect(r.inline, '{"starrule":1}');
    });

    test('非深链返回空', () {
      final r = StarRuleDeepLink.parse('https://example.com/a.json');
      expect(r.url, isNull);
      expect(r.inline, isNull);
    });
  });
}

class _SlowSource implements VideoSource {
  @override
  SourceDef get def => const SourceDef(key: 'slow', name: 'slow', kind: SourceKind.cmsJson);

  @override
  Future<HomeFeed> home() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const HomeFeed(recommend: []);
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async =>
      const PageResult(items: [], page: 1);

  @override
  Future<WorkDetail> detail(String workId) async => throw UnimplementedError();

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async =>
      throw UnimplementedError();

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async =>
      const PageResult(items: [], page: 1);
}
