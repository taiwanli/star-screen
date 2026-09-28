import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/config_cleaner.dart';

/// HTTP 获取结果。
class FetchResult {
  final Uri url;
  final int statusCode;
  final String? etag;
  final String body;

  /// 响应头（键为原始大小写，值取首个）—— drpy 注入 API 的 resp.headers 需要。
  final Map<String, String> headers;

  /// 304 Not Modified：订阅未变化，调用方应使用缓存原文。
  final bool notModified;

  const FetchResult({
    required this.url,
    required this.statusCode,
    this.etag,
    required this.body,
    this.headers = const {},
    this.notModified = false,
  });
}

/// 获取失败（网络/状态码/超时），message 为用户可读三段式文案的第一段。
class FetchException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const FetchException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => 'FetchException: $message'
      '${statusCode == null ? '' : ' (HTTP $statusCode)'}'
      '${cause == null ? '' : '（$cause）'}';
}

/// HTTP 获取抽象 —— 适配器/抓取器只依赖此接口（测试注入假实现）。
abstract interface class HttpFetch {
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  });

  /// drpy 注入 API 的 post/req(method=POST) 需要（docs/04 §4.3）。
  Future<FetchResult> post(
    Uri url, {
    String body = '',
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  });
}

/// dart:io 实现（桌面/安卓端通用）。
class IoHttpFetch implements HttpFetch {
  /// 统一 UA：识别为星映客户端（入口型接口按 UA 分流的依据之一）。
  static const userAgent = 'StarScreen/0.1 (content-neutral player)';

  /// 可选代理（如 `PROXY 127.0.0.1:7890`）。dart:io 不读环境变量，
  /// 由宿主/工具按需注入 —— 覆盖 GitHub raw 等需要代理的订阅地址。
  final String? proxy;

  /// 信任自签/过期证书（用户自有源的设置项；docs/11 压测：卧龙/如意等需要）。
  /// docs/13 E2：v0.1 尚未接入「源管理 → 高级」设置入口，产品内默认 false；
  /// 置 true 时全信任证书链（仅限自有源调试，勿用于公共订阅）。
  final bool trustSelfSigned;

  const IoHttpFetch({this.proxy, this.trustSelfSigned = false});

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) =>
      _send(url, method: 'GET', headers: headers, timeout: timeout);

  @override
  Future<FetchResult> post(
    Uri url, {
    String body = '',
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) =>
      _send(url, method: 'POST', headers: headers, timeout: timeout, body: body);

  Future<FetchResult> _send(
    Uri url, {
    required String method,
    required Map<String, String> headers,
    required Duration timeout,
    String body = '',
  }) async {
    final client = HttpClient();
    try {
      if (proxy != null) {
        client.findProxy = (_) => proxy!;
      }
      if (trustSelfSigned) {
        client.badCertificateCallback = (_, _, _) => true;
      }
      client.userAgent = userAgent;
      client.connectionTimeout = timeout;
      final request = switch (method) {
        'POST' => await client.postUrl(url),
        _ => await client.getUrl(url),
      };
      headers.forEach(request.headers.set);
      if (method == 'POST' && body.isNotEmpty) {
        final hasCt = headers.keys.any((k) => k.toLowerCase() == 'content-type');
        if (!hasCt) {
          request.headers.set(
              HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');
        }
        request.add(utf8.encode(body));
      }
      final response = await request.close().timeout(timeout);

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        if (values.isNotEmpty) responseHeaders[name] = values.first;
      });

      if (response.statusCode == HttpStatus.notModified) {
        return FetchResult(
          url: url,
          statusCode: 304,
          etag: response.headers.value(HttpHeaders.etagHeader),
          body: '',
          headers: responseHeaders,
          notModified: true,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FetchException('订阅地址请求失败',
            statusCode: response.statusCode);
      }
      // 字节级智能解码（UTF-16 BOM / UTF-8 BOM / 宽松 UTF-8，docs/11 压测反馈）
      // 响应体读取同样受超时约束 —— 防止“慢滴漏”服务器挂死整个探测（docs/11 实测）
      final bytes = await response
          .fold<List<int>>(<int>[], (acc, c) => acc..addAll(c))
          .timeout(timeout, onTimeout: () => throw TimeoutException('响应体读取超时'));
      final responseBody = ConfigCleaner.decodeBytes(bytes);
      return FetchResult(
        url: url,
        statusCode: response.statusCode,
        etag: response.headers.value(HttpHeaders.etagHeader),
        body: responseBody,
        headers: responseHeaders,
      );
    } on TimeoutException {
      throw FetchException('订阅地址请求超时', cause: 'timeout ${timeout.inMilliseconds}ms');
    } on HandshakeException catch (e) {
      throw FetchException(
        'TLS 证书校验失败 —— 源证书校验失败（可换线路）',
        cause: e.message,
      );
    } on SocketException catch (e) {
      throw FetchException('网络连接失败', cause: e.message);
    } finally {
      client.close(force: true);
    }
  }
}
