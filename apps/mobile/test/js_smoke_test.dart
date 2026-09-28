import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';

/// QuickJS spike（docs/09 M3-4）：验证 flutter_js 在 Android 测试环境（手机）能否
/// 加载并执行 JS。原生库不可用时自动跳过（不阻塞 CI）。
bool _quickJsAvailable() {
  try {
    final runtime = getJavascriptRuntime();
    final result = runtime.evaluate('1 + 1');
    runtime.dispose();
    return result.stringResult == '2';
  } on Object {
    return false;
  }
}

void main() {
  final available = _quickJsAvailable();

  test('QuickJS 冒烟：求值与跨语言数据交换', () async {
    final runtime = getJavascriptRuntime();
    try {
      final json = await runtime
          .evaluateAsync('JSON.stringify({a: 1, b: "x"})');
      expect(json.stringResult, '{"a":1,"b":"x"}');

      runtime.evaluate('globalThis.answer = 41 + 1;');
      final answer = runtime.evaluate('globalThis.answer');
      expect(answer.stringResult, '42');
    } finally {
      runtime.dispose();
    }
  }, skip: available ? false : '本机 QuickJS 原生库不可用（docs/08 §1）');
}
