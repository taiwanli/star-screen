import 'dart:async';

import 'package:flutter_js/flutter_js.dart';
import 'package:star_plugins/star_plugins.dart';

/// flutter_js（QuickJS）后端 —— Windows/Android 通用（docs/09 M3-4）。
///
/// 桥接要点（flutter_js 0.8.7 QuickJsRuntime2）：
/// - Dart 闭包经 `setToGlobalObject` 注入 JS 全局，JS 侧同步调用、返回值回传；
///   闭包返回 Future 时自动桥接为 JS Promise（drpy2 片段可 `await req(...)`）；
/// - JS Promise 返回 Dart 侧为 Future —— 由 [_pump] 周期执行
///   `executePendingJob` 驱动事件循环直至落定；
/// - 闭包形参固定 4 个可选位：QuickJS→Dart 的实参按位置对齐，
///   drpy 注入 API 的最大元数为 3（pd(html, rule, base)）。
class FlutterJsRuntime implements JsRuntime {
  late final JavascriptRuntime _rt = getJavascriptRuntime(xhr: false);

  /// 向全局对象安装属性的 JS 可调用对象（保持引用防 GC）。
  late final JSInvokable _setter =
      _rt.evaluate('(key, val) => { this[key] = val; }').rawResult as JSInvokable;

  bool _disposed = false;

  @override
  void installFunction(String name, Future<Object?> Function(List<Object?> args) fn) {
    _checkAlive();
    _setter.invoke([
      name,
      ([Object? a, Object? b, Object? c, Object? d]) async => fn([a, b, c, d]),
    ]);
  }

  @override
  Object? evalSync(String code) {
    _checkAlive();
    final res = _rt.evaluate(code);
    if (res.isError) throw JsEvalException(res.stringResult);
    return res.rawResult;
  }

  @override
  Future<Object?> evalAsync(String code, {Duration timeout = const Duration(seconds: 15)}) async {
    _checkAlive();
    final res = _rt.evaluate(code);
    if (res.isError) throw JsEvalException(res.stringResult);
    final raw = res.rawResult;
    if (raw is Future) return _pump(raw, timeout);
    return raw;
  }

  /// 泵 QuickJS 事件循环（微任务/已注册的 Promise 反应）直至 [raw] 落定。
  ///
  /// docs/13 A5：flutter_js 0.8.7 的 QuickJS 运行时没有 Promise 完成事件可订阅
  /// （`executePendingJob` 同步执行一次微任务队列即返回，无回调/流 API），
  /// 故 10ms 周期泵是当前的最小可行驱动方式；若上游提供事件化 API 可改事件驱动。
  Future<Object?> _pump(Future<dynamic> raw, Duration timeout) async {
    var stop = false;
    final timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (!stop) _rt.executePendingJob();
    });
    try {
      return await raw.timeout(
        timeout,
        onTimeout: () => throw const JsEvalException('JS 执行超时（已熔断）'),
      );
    } on JSError catch (e) {
      throw JsEvalException(e.message);
    } finally {
      stop = true;
      timer.cancel();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _rt.dispose();
  }

  void _checkAlive() {
    if (_disposed) throw const JsEvalException('JS 运行时已释放');
  }
}
