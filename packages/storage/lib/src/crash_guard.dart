import 'dart:async';
import 'dart:io';

/// 崩溃与未捕获异常落盘（docs/02 §7 性能与崩溃治理）。
/// 日志目录：`[base]/StarScreen/logs/crash-yyyyMMdd.log`，按天追加。
class CrashGuard {
  CrashGuard(this.logDir);

  final Directory logDir;

  /// 安装错误钩子（Flutter 侧需再接 `FlutterError.onError`）。
  static CrashGuard install({required String baseDir}) {
    final dir = Directory('$baseDir${Platform.pathSeparator}logs')
      ..createSync(recursive: true);
    return CrashGuard(dir);
  }

  /// 包一层 `runZonedGuarded`。
  static T run<T>(T Function() body, {required String baseDir}) {
    final guard = install(baseDir: baseDir);
    T? result;
    Object? err;
    runZonedGuarded(() {
      result = body();
    }, (error, stack) {
      err = error;
      guard.record('zone', error.toString(), stack: stack.toString());
    });
    if (err != null) throw err!;
    return result as T;
  }

  void record(String channel, String message, {String? stack}) {
    try {
      final now = DateTime.now();
      final pad = (int v) => v.toString().padLeft(2, '0');
      final file = File(
          '${logDir.path}${Platform.pathSeparator}crash-${now.year}${pad(now.month)}${pad(now.day)}.log');
      final buf = StringBuffer()
        ..writeln('[$channel] ${now.toIso8601String()}')
        ..writeln(message);
      if (stack != null && stack.isNotEmpty) {
        buf
          ..writeln(stack)
          ..writeln('---');
      }
      file.writeAsStringSync(buf.toString(), mode: FileMode.append);
    } on Object {
      // 日志失败不得二次崩溃
    }
  }

  /// 性能采样：超时标签落盘。
  void span(String label, int elapsedMs) {
    if (elapsedMs >= 3000) {
      record('perf', '$label took ${elapsedMs}ms');
    }
  }
}
