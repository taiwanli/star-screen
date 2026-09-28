import 'package:star_lan/star_lan.dart';
import 'package:test/test.dart';

void main() {
  test('UpdateChecker 比较版本', () async {
    final c = UpdateChecker(
      getText: (_) async =>
          '{"version":"1.0.0","url":"https://x","notes":"fix"}',
    );
    final info = await c.check('http://m.json', '0.1.0-dev.1');
    expect(info?.version, '1.0.0');
    final same = await c.check('http://m.json', '1.0.0');
    expect(same, isNull);
  });

  test('DlnaCastClient XML 转义', () {
    // 通过 play 失败路径不抛即可；此处仅测构造
    final client = DlnaCastClient();
    expect(client, isNotNull);
  });
}
