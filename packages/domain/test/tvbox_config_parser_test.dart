import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final base = Uri.parse('https://cdn.example.com/tv/box.json');

  SourceDef byKey(ParseReport r, String key) =>
      r.sources.firstWhere((s) => s.key == key);

  group('TvBoxConfigParser.parse —— 混合单仓（docs/06 tvbox_mixed 样本）', () {
    late ParseReport report;

    setUp(() {
      final raw = fixture('tvbox_mixed.json').readAsStringSync();
      report = TvBoxConfigParser.parse(raw: raw, baseUrl: base);
    });

    test('按 kind 正确分类', () {
      expect(report.countOf(SourceKind.cmsJson), 3); // t1a / t1b / appys
      expect(report.countOf(SourceKind.cmsXml), 1); // t0a
      expect(report.countOf(SourceKind.xpathRule), 1); // xpathmac
      expect(report.countOf(SourceKind.drpyJs), 2); // drpy / lffam
      expect(report.countOf(SourceKind.alist), 1);
      expect(report.countOf(SourceKind.spiderJar), 2); // douban / sitejar
      expect(report.countOf(SourceKind.unsupported), 2); // py / hipy4
      expect(report.sources.length, 12);
    });

    test('CMS 基地址剥离查询尾巴', () {
      expect(byKey(report, 't1a').endpoint,
          'https://a.example.com/api.php/provide/vod/');
    });

    test('相对路径以订阅 URL 为基准解析（./ 与 ../）', () {
      expect(byKey(report, 't1b').endpoint,
          'https://cdn.example.com/tv/api/cms.php');
      expect(byKey(report, 'drpy').endpoint,
          'https://cdn.example.com/tv/lib/drpy2.min.js');
    });

    test('drpy：api=运行时 + ext=.js 源文件（docs/04 §3.3）', () {
      final drpy = byKey(report, 'drpy');
      expect(drpy.endpoint, 'https://cdn.example.com/tv/lib/drpy2.min.js');
      expect(drpy.sourceUrl, 'https://cdn.example.com/tv/js/drpy.js');
      // ext 为运行时参数（实测 "18+"）：不视为源文件路径
      final lf = byKey(report, 'lffam');
      expect(lf.sourceUrl, isNull);
      expect(lf.extRaw, '18+');
    });

    test('AppYsV2：ext 以 ### 分段取 API 地址，归入 cmsJson 变体', () {
      final appys = byKey(report, 'appys');
      expect(appys.kind, SourceKind.cmsJson);
      expect(appys.cmsVariant, CmsVariant.appysV2);
      expect(appys.endpoint, 'https://appys.example.com/api.php/v1.vod');
    });

    test('XPath 规则源：ext 为 URL 时记录解析地址', () {
      final x = byKey(report, 'xpathmac');
      expect(x.kind, SourceKind.xpathRule);
      expect(x.extUrl, 'https://cdn.example.com/tv/json/duboku.json');
    });

    test('站点级 jar 覆盖全局 spider；缺省回落全局（docs/04 §3.1）', () {
      expect(byKey(report, 'sitejar').jarRef,
          'https://cdn.example.com/tv/jar/custom.jar;md5;abcdef');
      expect(byKey(report, 'douban').jarRef,
          'https://cdn.example.com/tv/jar/global.jar;md5;0123456789abcdef0123456789abcdef');
      expect(report.spiderRef,
          'https://cdn.example.com/tv/jar/global.jar;md5;0123456789abcdef0123456789abcdef');
    });

    test('jar 蜘蛛归入 spiderJar；仍不支持的源给出原因（绝不静默失败）', () {
      final douban = byKey(report, 'douban');
      expect(douban.kind, SourceKind.spiderJar);
      expect(byKey(report, 'hipy4').unsupportedReason, contains('t4'));
      expect(byKey(report, 'pysrc').unsupportedReason, contains('py'));
    });

    test('缺 key 站点进入 issues', () {
      expect(report.issues, isNotEmpty);
      expect(report.issues.first.message, contains('key'));
    });

    test('caps 默认可搜索；站点头与超时落位', () {
      expect(byKey(report, 't1a').caps.searchable, isTrue);
      final t1b = byKey(report, 't1b');
      expect(t1b.headers['User-Agent'], 'StarScreen/0.1');
      expect(t1b.timeoutSec, 10);
    });

    test('lives：相对地址解析 + EPG 模板保留', () {
      expect(report.lives, hasLength(1));
      final live = report.lives.first;
      expect(live.url, 'https://cdn.example.com/tv/live/tv.txt');
      expect(live.epg, contains('{name}'));
    });
  });

  group('TvBoxConfigParser.parse —— 多仓 storeHouse（docs/04 §6.1）', () {
    test('识别为仓库列表并解析相对 sourceUrl', () {
      final raw = fixture('warehouse_multi.json').readAsStringSync();
      final report = TvBoxConfigParser.parse(raw: raw, baseUrl: base);
      expect(report.isWarehouseList, isTrue);
      expect(report.warehouses, hasLength(2));
      expect(report.warehouses.first.name, '仓库一');
      expect(report.warehouses[1].url, 'https://cdn.example.com/tv/wh2.json');
    });
  });

  group('TvBoxConfigParser.parse —— 容错样本（docs/06）', () {
    test('注释行 + 尾随逗号的存活配置可解析', () {
      final raw = fixture('bad_prefix_comment.json').readAsStringSync();
      final report = TvBoxConfigParser.parse(raw: raw, baseUrl: base);
      expect(report.sources, hasLength(1));
      expect(report.sources.first.key, 'ok1');
      expect(report.sources.first.endpoint,
          'https://ok.example.com/api.php/provide/vod');
    });

    test('HTML 落地页抛出可读异常（入口型接口）', () {
      final raw = fixture('landing_page.html').readAsStringSync();
      expect(
        () => TvBoxConfigParser.parse(raw: raw, baseUrl: base),
        throwsA(isA<ConfigParseException>()),
      );
    });
  });
}
