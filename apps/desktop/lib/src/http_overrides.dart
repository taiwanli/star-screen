import 'dart:io';

/// 全局 HTTP：放宽证书校验 + 常用 UA。
/// 解决部分图床/播放站证书异常导致图片与视频无法加载。
class StarHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) StarScreen/0.1';
    return client;
  }
}

void installStarHttpOverrides() {
  HttpOverrides.global = StarHttpOverrides();
}
