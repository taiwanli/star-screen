import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';

/// 可编程 HttpFetch 假实现：记录 (method, url, body, headers)，按 handler 返回。
typedef RecordedCall = (String method, Uri url, String body, Map<String, String> headers);

class FakeHttpFetch implements HttpFetch {
  final FetchResult Function(Uri url, String method, String body, Map<String, String> headers)
      handler;
  final List<RecordedCall> calls = [];

  FakeHttpFetch(this.handler);

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    calls.add(('GET', url, '', headers));
    return handler(url, 'GET', '', headers);
  }

  @override
  Future<FetchResult> post(
    Uri url, {
    String body = '',
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    calls.add(('POST', url, body, headers));
    return handler(url, 'POST', body, headers);
  }
}

/// JS 引擎假实现：记录求值代码、捕获宿主函数、脚本化返回值。
/// （QuickJS 原生库在 flutter test/dart test 环境不可加载 —— docs/08 §1）
class FakeJsRuntime implements JsRuntime {
  final functions = <String, Future<Object?> Function(List<Object?>)>{};
  final syncCodes = <String>[];
  final asyncCodes = <String>[];

  /// evalSync 的脚本化返回（按完整代码匹配）。
  final Map<String, Object?> syncScripts = {};

  /// evalAsync 的脚本化返回；返回 null 且需走 setResult 捕获路径时，
  /// 在此回调内自行调用 functions['setResult']。
  Future<Object?> Function(String code)? onEvalAsync;

  @override
  void installFunction(String name, Future<Object?> Function(List<Object?> args) fn) {
    functions[name] = fn;
  }

  @override
  Object? evalSync(String code) {
    syncCodes.add(code);
    return syncScripts[code];
  }

  @override
  Future<Object?> evalAsync(String code, {Duration timeout = const Duration(seconds: 15)}) async {
    asyncCodes.add(code);
    return onEvalAsync?.call(code);
  }

  @override
  void dispose() {}
}

/// 用源码文本解析 DrpyRule（fields 私有构造的绕行）。
DrpyRule parseRule(String js) => DrpyRuleParser.parse(js)!;
