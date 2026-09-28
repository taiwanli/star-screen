import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  group('XpathToStarRule 选择器根节点', () {
    test('绝对路径忽略 root，不拼非法选择器', () {
      const ext = r'''
      {
        "homeUrl": "https://site.example.com",
        "cateManual": { "电影": "1" },
        "cateUrl": "/type/{cateId}-{catePg}.html",
        "cateVodNode": "body&&.item",
        "cateVodName": ".title&&Text",
        "cateVodId": "a&&href",
        "dtUrl": "/detail/{vid}.html",
        "dtNode": "//div[@class='detail']",
        "dtName": "//h1/text()",
        "dtFromNode": "//div[@class='tabs']/span",
        "dtFromName": "/text()",
        "dtUrlNode": "//div[@class='playlist']",
        "dtUrlId": "/@href",
        "dtUrlName": "/text()"
      }
      ''';
      final r = XpathToStarRule.convert(ext);
      // 绝对路径：不含原始 xpath 根
      expect(r.rule.detail!.title!.sel, 'h1&&Text');
      expect(r.rule.detail!.title!.sel, isNot(contains('detail')));
      expect(r.rule.detail!.lines!.list!.sel, 'div.tabs&&span');
    });

    test('相对路径用 root 转 CSS 前缀', () {
      const ext = r'''
      {
        "homeUrl": "https://site.example.com",
        "cateManual": { "电影": "1" },
        "cateUrl": "/c/{cateId}-{catePg}.html",
        "cateVodNode": "body&&.item",
        "cateVodName": "Text",
        "cateVodId": "a&&href",
        "dtUrl": "/d/{vid}.html",
        "dtNode": "//div[@class='detail']",
        "dtName": "/text()",
        "dtFromNode": ".tabs&&span",
        "dtFromName": "Text",
        "dtUrlNode": ".playlist",
        "dtUrlId": "a&&href",
        "dtUrlName": "Text"
      }
      ''';
      final r = XpathToStarRule.convert(ext);
      // /text() + dtNode → div.detail&&Text
      expect(r.rule.detail!.title!.sel, 'div.detail&&Text');
    });

    test('列表 id 为 href，详情模板可展开', () {
      const ext = r'''
      {
        "homeUrl": "https://site.example.com",
        "cateManual": { "电影": "1" },
        "cateUrl": "/c/{cateId}-{catePg}.html",
        "cateVodNode": "body&&.item",
        "cateVodName": "Text",
        "cateVodId": "a&&href",
        "dtUrl": "/d/{vid}.html",
        "dtName": "h1&&Text",
        "dtFromNode": "s",
        "dtFromName": "Text",
        "dtUrlNode": "p",
        "dtUrlId": "a&&href",
        "dtUrlName": "Text"
      }
      ''';
      final r = XpathToStarRule.convert(ext);
      expect(r.rule.detail!.url, '/d/{vid}.html');
      expect(r.rule.category!.items.id.sel, 'a&&href');
    });
  });

  group('StarRule 导入保留 key/分组', () {
    test('tryConvert 后 key 不变，kind 变 starRule', () {
      const ext = r'''
      {
        "homeUrl": "https://x.example.com",
        "cateManual": { "A": "1" },
        "cateUrl": "/c/{cateId}-{catePg}.html",
        "cateVodNode": "body&&.i",
        "cateVodName": "Text",
        "cateVodId": "a&&href",
        "dtUrl": "/d/{vid}.html",
        "dtName": "Text",
        "dtFromNode": "s",
        "dtFromName": "Text",
        "dtUrlNode": "p",
        "dtUrlId": "a&&href",
        "dtUrlName": "Text",
        "searchUrl": "/s/{wd}.html",
        "scVodNode": "body&&.i",
        "scVodName": "Text",
        "scVodId": "a&&href"
      }
      ''';
      final def = SourceDef(
        key: 'keep-me',
        name: '旧名',
        kind: SourceKind.xpathRule,
        extRaw: ext,
        groupId: '仓A',
        headers: const {'X-Extra': '1'},
      );
      final out = tryConvertXpathToStarRule(def)!;
      expect(out.key, 'keep-me');
      expect(out.name, '旧名');
      expect(out.kind, SourceKind.starRule);
      expect(out.groupId, '仓A');
      expect(out.headers['X-Extra'], '1');
      expect(out.extRaw, contains('"starrule"'));
    });
  });
}
