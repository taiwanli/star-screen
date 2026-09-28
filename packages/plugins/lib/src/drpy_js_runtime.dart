import 'dart:async';

import 'package:star_domain/star_domain.dart';

/// JS 引擎抽象（docs/09 M3-4「QuickJS 绑定」的包内边界）。
///
/// star_plugins 零 Flutter 依赖：QuickJS 实现由端上注入（桌面/安卓 flutter_js，
/// 见 apps/*/lib/src/flutter_js_runtime.dart）。`flutter test` 环境原生库不可
/// 加载（docs/08 §1），单测一律注入假实现；真机行为由端上冒烟测试兜底
/// （skip 保护，与 apps/desktop/test/js_smoke_test.dart 同一模式）。
abstract interface class JsRuntime {
  /// 向 JS 全局安装宿主函数。[fn] 可返回 Future（实现须桥接为 JS Promise，
  /// 支撑 drpy2 片段内 `await req(...)`）。
  void installFunction(String name, Future<Object?> Function(List<Object?> args) fn);

  /// 同步求值（注入全局变量、装载源文件）。JS 异常 → [JsEvalException]。
  Object? evalSync(String code);

  /// 异步求值：返回值为 Promise 时等待其落定（含事件泵）；超时 → [JsEvalException]。
  Future<Object?> evalAsync(String code, {Duration timeout});

  void dispose();
}

/// 每端创建 [JsRuntime] 的工厂（端上装配处传入，源实例惰性调用）。
typedef JsRuntimeFactory = JsRuntime Function();

/// JS 求值失败（语法错误/运行时异常/超时）。message 为用户可读文案。
class JsEvalException implements Exception {
  final String message;

  const JsEvalException(this.message);

  @override
  String toString() => 'JsEvalException: $message';
}

/// drpy 单次操作（home/category/search/detail/play）的执行限额。
///
/// 超限即熔断（docs/05 §6.2「违反任何一项即熔断置熔」）：抛 [FetchException]，
/// 绝不让宿主崩溃；计数器每次操作重置（[reset]）。
class DrpyBudget {
  /// 单次操作允许的 HTTP 请求次数（页面 + 分页嗅探余量）。
  final int maxRequests;

  /// 单次操作总墙钟上限（含 JS 执行与全部请求）。
  final Duration maxWallTime;

  /// setResult 载荷的字符总量上限（防无界字符串堆积）。
  final int maxOutputChars;

  int requests = 0;
  int outputChars = 0;
  DateTime _start = DateTime.now();

  DrpyBudget({
    this.maxRequests = 24,
    this.maxWallTime = const Duration(seconds: 20),
    this.maxOutputChars = 2 * 1024 * 1024,
  });

  Duration get elapsed => DateTime.now().difference(_start);

  /// 剩余墙钟（下限 2s，保证单请求至少可用）。
  Duration get remaining {
    final r = maxWallTime - elapsed;
    return r < const Duration(seconds: 2) ? const Duration(seconds: 2) : r;
  }

  bool get expired => elapsed >= maxWallTime;

  /// 开始一次新操作（重置计数与计时）。
  void reset() {
    requests = 0;
    outputChars = 0;
    _start = DateTime.now();
  }

  void chargeRequest() {
    if (++requests > maxRequests) {
      throw FetchException('已熔断：该源单次请求数超过 $maxRequests（疑似死循环）');
    }
    if (expired) {
      throw FetchException('已熔断：该源执行超过 ${maxWallTime.inSeconds}s');
    }
  }

  void chargeOutput(int chars) {
    outputChars += chars;
    if (outputChars > maxOutputChars) {
      throw FetchException('已熔断：该源返回数据量超过 ${maxOutputChars ~/ 1024}KB');
    }
  }
}
