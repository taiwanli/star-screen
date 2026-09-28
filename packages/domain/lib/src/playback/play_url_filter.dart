/// 播放地址广告过滤与错误文案（对照 FongMi/TV ads / ExoErrorMessageProvider）。
class PlayUrlFilter {
  /// 全局广告过滤串（导入配置后由注册层写入；FongMi/TV 同构 ads）。
  static List<String> globalAds = const [];

  /// 播放 flag 白名单（TVBox `flags`，命中则线路可用）；空 = 不过滤。
  static List<String> globalFlags = const [];

  /// 线路名是否允许（flags 过滤，docs/14）。
  static bool lineAllowed(String lineId) {
    if (globalFlags.isEmpty) return true;
    final id = lineId.toLowerCase();
    return globalFlags.any((f) => id.contains(f.toLowerCase()));
  }

  /// [adPatterns] 额外规则；命中则视为广告不播。
  static bool isAd(String url, Iterable<String> adPatterns) {
    final u = url.toLowerCase();
    for (final p in [...globalAds, ...adPatterns]) {
      final s = p.toLowerCase().trim();
      if (s.isEmpty) continue;
      if (u.contains(s)) return true;
    }
    return false;
  }

  /// 从候选列表去掉广告。
  static List<T> stripAds<T>(
    List<T> items,
    Iterable<String> adPatterns,
    String Function(T) urlOf,
  ) {
    return [
      for (final e in items)
        if (!isAd(urlOf(e), adPatterns)) e,
    ];
  }
}

/// 播放失败 → 用户可读原因（换线路/换源指引）。
String playErrorText(Object error) {
  final s = error.toString();
  if (s.contains('403') || s.contains('Forbidden')) {
    return '播放被拒绝（403）—— 换线路或换源';
  }
  if (s.contains('404') || s.contains('Not Found')) {
    return '播放地址不存在（404）—— 换线路';
  }
  if (s.contains('timeout') || s.contains('Timeout')) {
    return '播放超时 —— 检查网络或换线路';
  }
  if (s.contains('Failed host lookup') || s.contains('SocketException')) {
    return '网络无法访问播放服务器 —— 检查网络';
  }
  if (s.contains('Handshake') || s.contains('CERTIFICATE') || s.contains('TLS')) {
    return '播放服务器证书异常 —— 换线路';
  }
  if (s.contains('needsParse') || s.contains('网页解析')) {
    return '该线路需要网页解析，星映默认不播放 —— 请换线路';
  }
  return '播放失败：$s —— 可换线路/换源';
}

/// 是否建议切换播放引擎（内核级失败）。
bool shouldSuggestEngineSwitch(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('mpv') ||
      s.contains('libmpv') ||
      s.contains('failed to open') ||
      s.contains('unrecognized') ||
      s.contains('codec');
}

/// 播放失败完整文案（含引擎建议）。
String playErrorWithEngineHint(Object error, {required String engineName}) {
  final base = playErrorText(error);
  if (!shouldSuggestEngineSwitch(error)) return base;
  return '$base；可尝试切换播放引擎（当前 $engineName）';
}
