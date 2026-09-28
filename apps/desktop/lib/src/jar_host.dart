import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:star_domain/star_domain.dart';

/// 桌面 JVM Jar 蜘蛛桥：`java -cp bridge.jar:spider.jar StarJarBridge <class>`。
///
/// 原理：CatVod `Spider` 契约是纯反射方法（homeContent/search…），
/// 用 **JVM 子进程** 加载 jar + `StarJarBridge`，stdin/stdout JSON Lines 调用。
/// Context 用动态代理桩；不支持依赖 Dex/安卓组件的蜘蛛（会报 ClassNotFound）。
class DesktopJvmJarHost implements JarSpiderHost {
  DesktopJvmJarHost({this.javaExe, this.bridgeJarPath});

  /// 缺省自动探测 PATH / 常见 JDK 目录。
  final String? javaExe;

  /// `star-spider-bridge.jar` 路径；缺省用可执行文件旁 `bridge/star-spider-bridge.jar`。
  final String? bridgeJarPath;

  Process? _proc;
  final _pending = <Completer<Map<String, dynamic>>>[];
  bool _booted = false;

  static String? findJava() {
    // 1) 捆绑 JRE（开箱即用，优先）
    final exe = Platform.resolvedExecutable;
    final appDir = File(exe).parent.path;
    for (final rel in [
      'jre-min${Platform.pathSeparator}bin${Platform.pathSeparator}java.exe',
      'jre${Platform.pathSeparator}bin${Platform.pathSeparator}java.exe',
      'runtime${Platform.pathSeparator}bin${Platform.pathSeparator}java.exe',
    ]) {
      final p = '$appDir${Platform.pathSeparator}$rel';
      if (File(p).existsSync()) return p;
    }
    // 2) 工程内 jre-min（开发态）
    final dev = File(
        '${Directory.current.path}${Platform.pathSeparator}tools${Platform.pathSeparator}jre-min${Platform.pathSeparator}bin${Platform.pathSeparator}java.exe');
    if (dev.existsSync()) return dev.path;

    // 3) 系统 JDK / PATH
    if (Platform.isWindows) {
      final candidates = <String>[
        'java.exe',
        r'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot\bin\java.exe',
        r'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot\bin\java.exe',
        r'C:\Program Files\Zulu\zulu-11-jre\bin\java.exe',
      ];
      for (final c in candidates) {
        if (c.contains(r'\')) {
          if (File(c).existsSync()) return c;
        } else {
          try {
            final r = Process.runSync('where', [c]);
            if (r.exitCode == 0) return c;
          } on Object {
            // ignore
          }
        }
      }
    } else {
      try {
        final r = Process.runSync('which', ['java']);
        if (r.exitCode == 0) return 'java';
      } on Object {}
    }
    return null;
  }

  String? _findBridgeJar() {
    if (bridgeJarPath != null && File(bridgeJarPath!).existsSync()) {
      return bridgeJarPath;
    }
    final appDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      '$appDir${Platform.pathSeparator}bridge${Platform.pathSeparator}star-spider-bridge.jar',
      '$appDir${Platform.pathSeparator}star-spider-bridge.jar',
      '${Directory.current.path}${Platform.pathSeparator}tools${Platform.pathSeparator}java-bridge${Platform.pathSeparator}star-spider-bridge.jar',
      r'C:\XingYingBuild\tools\java-bridge\star-spider-bridge.jar',
    ];
    for (final p in candidates) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  @override
  bool get available {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return false;
    }
    return findJava() != null && _findBridgeJar() != null;
  }

  Future<void> _ensureProc(String spiderClass, {String? jarPath}) async {
    final java = javaExe ?? findJava();
    final bridge = _findBridgeJar();
    if (java == null || bridge == null) {
      throw const FetchException(
          '桌面 Jar 桥不可用：需要 JDK 与 star-spider-bridge.jar');
    }
    final cp = jarPath == null || jarPath.isEmpty
        ? bridge
        : '$bridge${Platform.pathSeparator}$jarPath';
    _proc ??= await Process.start(
      java,
      ['-Dfile.encoding=UTF-8', '-cp', cp, 'StarJarBridge', spiderClass],
      mode: ProcessStartMode.normal,
    );
    if (!_booted) {
      _booted = true;
      _proc!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final c = _pending.isEmpty ? null : _pending.removeAt(0);
        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic>) {
            c?.complete(decoded);
          } else {
            c?.complete({'ok': false, 'error': 'bad frame'});
          }
        } on Object catch (e) {
          c?.complete({'ok': false, 'error': '$e'});
        }
      });
      _proc!.stderr.transform(utf8.decoder).listen((e) {
        // stderr 仅日志
      });
    }
  }

  Future<Map<String, dynamic>> _rpc(Map<String, dynamic> cmd) async {
    final proc = _proc;
    if (proc == null) throw StateError('bridge not started');
    final c = Completer<Map<String, dynamic>>();
    _pending.add(c);
    proc.stdin.writeln(jsonEncode(cmd));
    await proc.stdin.flush();
    return c.future.timeout(const Duration(seconds: 20));
  }

  @override
  Future<void> load({
    required String jarPath,
    required String className,
    String? md5,
  }) async {
    await dispose();
    _booted = false;
    // className 兼容 csp_Douban / com.github.catvod.spider.Douban / Douban
    var cls = className;
    if (!cls.contains('.')) {
      cls = 'com.github.catvod.spider.$cls';
    }
    if (cls.startsWith('csp_')) {
      cls = 'com.github.catvod.spider.${cls.substring(4)}';
    }
    await _ensureProc(cls, jarPath: jarPath);
    await _rpc({'cmd': 'ping'});
  }

  @override
  Future<String> call(String method, Map<String, Object?> args) async {
    final cmd = <String, dynamic>{'cmd': method, ...args};
    final res = await _rpc(cmd);
    if (res['ok'] != true) {
      throw FetchException('jar 调用失败：${res['error']}');
    }
    final data = res['data'];
    return data == null ? '' : (data is String ? data : jsonEncode(data));
  }

  @override
  Future<void> dispose() async {
    try {
      await _proc?.kill();
    } on Object {}
    _proc = null;
    _booted = false;
    for (final p in _pending) {
      if (!p.isCompleted) {
        p.complete({'ok': false, 'error': 'disposed'});
      }
    }
    _pending.clear();
  }
}
