import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  const sampleHtml = r'''
{
  "starrule": 1,
  "meta": { "id": "demo.html.movies", "name": "示例HTML站", "version": "1.0.0" },
  "sourceType": "html",
  "site": {
    "host": "https://site.example.com",
    "headers": { "User-Agent": "Mozilla/5.0" },
    "timeout": 15
  },
  "home": {
    "url": "/",
    "recommend": {
      "list": "body&&.module-item",
      "title": ".title&&Text",
      "id": "a&&href",
      "cover": "img&&data-src",
      "badge": ".note&&Text"
    },
    "categories": {
      "mode": "manual",
      "manual": { "电影": "1", "剧集": "2" }
    }
  },
  "category": {
    "url": "/type/{cateId}-{catePg}.html",
    "list": "body&&.module-item",
    "title": ".title&&Text",
    "id": "a&&href",
    "cover": "img&&data-src",
    "hasMore": "auto"
  },
  "detail": {
    "url": "/detail/{vid}.html",
    "title": "h1&&Text",
    "cover": ".poster&&img&&src",
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
    "id": "a&&href",
    "cover": "img&&data-src"
  },
  "play": {
    "url": "{playUrl}",
    "headers": { "Referer": "{host}" },
    "parse": "auto"
  }
}
''';

  group('StarRuleParser', () {
    test('识别 StarRule 原文', () {
      expect(StarRuleParser.looksLikeStarRule(sampleHtml), isTrue);
      expect(StarRuleParser.looksLikeStarRule('{"sites":[]}'), isFalse);
      expect(StarRuleParser.looksLikeStarRule('<html></html>'), isFalse);
    });

    test('解析合法 HTML 模板站', () {
      final r = StarRuleParser.parse(sampleHtml);
      expect(r.rule.version, 1);
      expect(r.rule.meta.id, 'demo.html.movies');
      expect(r.rule.sourceType, StarSourceType.html);
      expect(r.rule.site.host, 'https://site.example.com');
      expect(r.rule.category, isNotNull);
      expect(r.rule.detail?.lines?.episodes, isNotNull);
      expect(r.rule.search, isNotNull);
    });

    test('meta.id 非法拒绝', () {
      final bad = sampleHtml.replaceFirst('demo.html.movies', 'Bad_ID!');
      expect(
        () => StarRuleParser.parse(bad),
        throwsA(isA<StarRuleParseException>()),
      );
    });

    test('缺 detail 拒绝（非 cms）', () {
      final noDetail = sampleHtml.replaceFirst(
        RegExp(r'"detail"\s*:\s*\{[\s\S]*?\n  \},'),
        '',
      );
      // 若正则未命中则跳过（结构保护）
      if (noDetail == sampleHtml) return;
      expect(
        () => StarRuleParser.parse(noDetail),
        throwsA(isA<StarRuleParseException>()),
      );
    });

    test('缺 search 给警告但不拒绝', () {
      final noSearch = sampleHtml.replaceFirst(
        RegExp(r'"search"\s*:\s*\{[\s\S]*?\n  \},'),
        '',
      );
      if (noSearch == sampleHtml) return;
      final r = StarRuleParser.parse(noSearch);
      expect(r.issues, isNotEmpty);
      expect(r.rule.search, isNull);
    });

    test('规则包 parsePack', () {
      final pack = '''
      {
        "starrule": 1,
        "pack": { "id": "demo.pack", "name": "示例包" },
        "sites": [ $sampleHtml ]
      }
      ''';
      final r = StarRuleParser.parsePack(pack);
      expect(r.packName, '示例包');
      expect(r.rules, hasLength(1));
      expect(r.rules.first.meta.id, 'demo.html.movies');
    });
  });

  group('StarRuleImporter', () {
    test('toSourceDef 产出 starRule 源', () {
      final r = StarRuleParser.parse(sampleHtml);
      final def = StarRuleImporter.toSourceDef(r.rule, groupId: 'demo');
      expect(def.kind, SourceKind.starRule);
      expect(def.key, 'demo.html.movies');
      expect(def.groupId, 'demo');
      expect(def.enabled, isTrue);
      expect(def.caps.searchable, isTrue);
      expect(def.extRaw, contains('"starrule"'));
      expect(def.kind.hasAdapter, isTrue);
    });

    test('toParseReport 可喂给注册表', () {
      final report = StarRuleImporter.toParseReport(sampleHtml);
      expect(report.sources, hasLength(1));
      expect(report.countOf(SourceKind.starRule), 1);
    });
  });

  group('XpathToStarRule', () {
    test('从 XPath ext 转译', () {
      const xpathExt = r'''
      {
        "homeUrl": "https://site.example.com",
        "ua": "Mozilla/5.0",
        "cateManual": { "电影": "1", "剧集": "2" },
        "cateUrl": "https://site.example.com/type/{cateId}-{catePg}.html",
        "cateVodNode": "//div[@class='list']//a",
        "cateVodName": "/@title",
        "cateVodId": "/@href",
        "cateVodImg": "//img/@data-src",
        "dtUrl": "https://site.example.com/detail/{vid}.html",
        "dtNode": "//div[@class='detail']",
        "dtName": "//h1/text()",
        "dtFromNode": "//div[@class='tabs']/span",
        "dtFromName": "/text()",
        "dtUrlNode": "//div[@class='playlist']",
        "dtUrlSubNode": "//a",
        "dtUrlId": "/@href",
        "dtUrlName": "/text()",
        "searchUrl": "https://site.example.com/search/{wd}.html",
        "scVodNode": "body&&.item",
        "scVodName": ".title&&Text",
        "scVodId": "a&&href",
        "scVodImg": "img&&src"
      }
      ''';
      final r = XpathToStarRule.convert(xpathExt);
      expect(r.rule.convertedFrom, 'tvbox-xpath');
      expect(r.rule.site.host, 'https://site.example.com');
      expect(r.rule.category, isNotNull);
      expect(r.rule.category!.url, contains('{cateId}'));
      expect(r.rule.detail, isNotNull);
      expect(r.rule.search, isNotNull);
      // 转译结果可被 StarRule 适配器消费
      final def = StarRuleImporter.toSourceDef(r.rule);
      expect(def.kind, SourceKind.starRule);
    });
  });

  group('三端一致性契约', () {
    test('starRule.hasAdapter 为 true（手机/桌面/TV 共用）', () {
      expect(SourceKind.starRule.hasAdapter, isTrue);
      expect(SourceKind.starRule.isSupported, isTrue);
      // jar 仍仅安卓桥，但 kind 有适配器（运行时 host 决定可用性）
      expect(SourceKind.spiderJar.hasAdapter, isTrue);
    });

    test('无 script 的规则 isDeclarative', () {
      final r = StarRuleParser.parse(sampleHtml);
      expect(r.rule.isDeclarative, isTrue);
    });
  });
}
