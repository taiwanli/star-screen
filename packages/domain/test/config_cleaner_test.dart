import 'dart:convert';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigCleaner', () {
    test('剥离 // 注释行后可解析（实测：liucn/pastebin 配置）', () {
      const raw = '''
// 第一行注释
{
  // 行内独占注释
  "sites": []
}
''';
      final doc = ConfigCleaner.decode(raw);
      expect(doc, isA<Map<String, dynamic>>());
      expect((doc as Map)['sites'], isEmpty);
    });

    test('剥离 BOM 后可解析', () {
      const raw = '﻿{"sites":[]}';
      final doc = ConfigCleaner.decode(raw);
      expect(doc, isA<Map<String, dynamic>>());
    });

    test('尾随逗号宽松重试（实测容错项）', () {
      const raw = '{"sites":[{"key":"a","type":1,},],}';
      final doc = ConfigCleaner.decode(raw) as Map;
      final sites = doc['sites'] as List;
      expect((sites.first as Map)['key'], 'a');
    });

    test('非法输入抛 ConfigParseException', () {
      expect(
        () => ConfigCleaner.decode('<html>not json</html>'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('clean 输出可直接 jsonDecode', () {
      const raw = '// c\n{"a":1}';
      expect(jsonDecode(ConfigCleaner.clean(raw)), {'a': 1});
    });
  });
}
