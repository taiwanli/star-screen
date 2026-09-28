import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

import 'helpers.dart';

SourceDef _def(String key, {SourceKind kind = SourceKind.cmsJson, bool enabled = true}) =>
    SourceDef(
      key: key,
      name: key,
      kind: kind,
      endpoint: 'https://x.example.com/$key',
      enabled: enabled,
    );

void main() {
  group('SourceRegistry —— applyReport（docs/05 §3）', () {
    test('新源插入；不支持的源默认禁用且保留原因', () async {
      final registry = SourceRegistry();
      final raw = fixture('tvbox_mixed.json').readAsStringSync();
      final report =
          TvBoxConfigParser.parse(raw: raw, baseUrl: Uri.parse('https://c.example.com/box.json'));
      await registry.applyReport(report);

      final all = await registry.all();
      expect(all, hasLength(12));
      final pysrc = all.firstWhere((d) => d.key == 'pysrc');
      expect(pysrc.enabled, isFalse);
      expect(pysrc.unsupportedReason, isNotNull);
      final t1a = all.firstWhere((d) => d.key == 't1a');
      expect(t1a.enabled, isTrue);
      expect((await registry.enabled()).map((d) => d.key), isNot(contains('pysrc')));
      // jar 蜘蛛现在可启用（需端上执行桥）
      expect(all.firstWhere((d) => d.key == 'douban').kind, SourceKind.spiderJar);
    });

    test('解析器固化：重复导入不覆盖已注册源（含启停状态）', () async {
      final registry = SourceRegistry();
      final raw = fixture('tvbox_mixed.json').readAsStringSync();
      final base = Uri.parse('https://c.example.com/box.json');
      await registry.applyReport(TvBoxConfigParser.parse(raw: raw, baseUrl: base));
      await registry.setEnabled('t1a', false);

      // 修改后的重复导入：t1a 换了地址（应被固化忽略），站点数不变
      final modified = raw.replaceAll(
          'https://a.example.com/api.php/provide/vod/?ac=list',
          'https://changed.example.com/api.php/provide/vod');
      final report = TvBoxConfigParser.parse(raw: modified, baseUrl: base);
      await registry.applyReport(report);

      final t1a = (await registry.all()).firstWhere((d) => d.key == 't1a');
      expect(t1a.endpoint, 'https://a.example.com/api.php/provide/vod/',
          reason: '已注册源不被重复导入覆盖');
      expect(t1a.enabled, isFalse, reason: '启停状态不因重导入丢失');
      expect((await registry.all()).length, 12);
    });
  });

  group('SourceRegistry —— 启停 / 删除 / 排序', () {
    late SourceRegistry registry;

    setUp(() async {
      registry = SourceRegistry();
      await registry.applyReport(ParseReport(
        warehouses: const [],
        lives: const [],
        issues: const [],
        sources: [
          _def('a'),
          _def('b'),
          _def('c', kind: SourceKind.unsupported, enabled: false),
        ],
      ));
    });

    test('enabled() 过滤禁用与不支持', () async {
      final keys = (await registry.enabled()).map((d) => d.key);
      expect(keys, ['a', 'b']);
    });

    test('setEnabled 持久化到 store', () async {
      await registry.setEnabled('a', false);
      expect((await registry.enabled()).map((d) => d.key), ['b']);
    });

    test('remove 生效', () async {
      await registry.remove('b');
      expect((await registry.all()).map((d) => d.key), ['a', 'c']);
    });

    test('reorder 决定 loadAll 顺序', () async {
      await registry.reorder(['b', 'a', 'c']);
      expect((await registry.all()).map((d) => d.key), ['b', 'a', 'c']);
    });
  });
}
