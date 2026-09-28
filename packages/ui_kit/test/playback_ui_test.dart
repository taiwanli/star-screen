import 'package:flutter_test/flutter_test.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

void main() {
  group('ChannelNumberBuffer —— 数字键换台（M3-2）', () {
    test('拼接数字并在 debounce 后提交', () async {
      final buf = ChannelNumberBuffer(
          debounce: const Duration(milliseconds: 20));
      String? got;
      buf.press('1', onCommitNow: (v) => got = v);
      buf.press('2', onCommitNow: (v) => got = v);
      expect(buf.digits, '12');
      expect(got, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(got, '12');
      expect(buf.digits, isEmpty);
      buf.dispose();
    });

    test('超过 4 位自动清空重开', () {
      final buf = ChannelNumberBuffer(
          debounce: const Duration(seconds: 5));
      for (final d in ['1', '2', '3', '4', '5']) {
        buf.press(d, onCommitNow: (_) {});
      }
      expect(buf.digits, '5');
      buf.dispose();
    });
  });

  group('ImportWizardResult', () {
    test('默认空列表', () {
      const r = ImportWizardResult(configs: 1, sites: 2, unsupported: 0);
      expect(r.sources, isEmpty);
      expect(r.failedWarehouses, isEmpty);
    });
  });
}
