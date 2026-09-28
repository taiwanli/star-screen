import 'package:flutter/services.dart';
import 'package:star_domain/star_domain.dart';

/// Android/TV：MethodChannel → Kotlin DexClassLoader 桥。
class MethodChannelJarHost implements JarSpiderHost {
  static const _channel = MethodChannel('starscreen/jar');

  @override
  bool get available => _available;

  bool _available = true;
  String? _loaded;

  @override
  Future<void> load({
    required String jarPath,
    required String className,
    String? md5,
  }) async {
    await _channel.invokeMethod<void>('load', {
      'jarPath': jarPath,
      'className': className,
      'md5': md5,
    });
    _loaded = '$jarPath::$className';
  }

  @override
  Future<String> call(String method, Map<String, Object?> args) async {
    final r = await _channel.invokeMethod<String>('call', {
      'method': method,
      'args': args,
    });
    return r ?? '';
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } on Object {
      // 忽略
    }
    _loaded = null;
  }

  String? get loaded => _loaded;

  void markUnavailable() => _available = false;
}
