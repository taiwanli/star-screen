import 'dart:convert';
import 'dart:io';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  final packFile = File('''
../../sources/星映-全部源-50源.star.json'''.trim());

  test('真实规则包：parsePack 50 站全过', () {
    if (!packFile.existsSync()) {
      // 测试目录外文件缺失时跳过（CI）
      return;
    }
    final raw = packFile.readAsStringSync();
    final pack = StarRuleParser.parsePack(raw);
    expect(pack.rules, hasLength(50));

    var cms = 0, json = 0, enabled = 0, searchable = 0;
    for (final r in pack.rules) {
      if (r.sourceType == StarSourceType.cms) cms++;
      if (r.sourceType == StarSourceType.json) json++;
      final def = StarRuleImporter.toSourceDef(r, groupId: pack.packName);
      expect(def.kind, SourceKind.starRule);
      expect(def.enabled, isTrue);
      expect(def.endpoint, startsWith('http'));
      if (def.enabled) enabled++;
      if (def.caps.searchable) searchable++;
    }
    expect(cms, 40);
    expect(json, 10);
    expect(enabled, 50);
    // CMS 与 json 检索源都应可搜
    expect(searchable, greaterThanOrEqualTo(50));
  });

  test('sourceType:cms 判定为可搜索（协议内建）', () {
    const ruleJson = r'''
    {
      "starrule": 1,
      "meta": { "id": "cms.t", "name": "T" },
      "sourceType": "cms",
      "site": { "host": "https://api.example.com/api.php/provide/vod" }
    }
    ''';
    final r = StarRuleParser.parse(ruleJson);
    expect(r.issues, isEmpty); // 不再误报缺 search
    final def = StarRuleImporter.toSourceDef(r.rule);
    expect(def.caps.searchable, isTrue);
    expect(def.enabled, isTrue);
    expect(def.endpoint, 'https://api.example.com/api.php/provide/vod');
  });
}
