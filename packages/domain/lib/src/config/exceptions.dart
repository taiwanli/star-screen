/// 订阅解析异常 —— 携带用户可读原因（三段式文案的“发生了什么”，docs/07 §6）。
class ConfigParseException implements Exception {
  final String message;
  final Object? cause;

  const ConfigParseException(this.message, [this.cause]);

  @override
  String toString() =>
      'ConfigParseException: $message${cause == null ? '' : '（$cause）'}';
}
