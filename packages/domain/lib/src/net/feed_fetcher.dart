import 'http_fetch.dart';
import 'local_feed_policy.dart';

/// 订阅获取器（docs/05 §5 管线第一站 / docs/09 M0-5）。
///
/// 通道：远程 URL（带 ETag 协商）+ **本地文件策略**（[LocalFeedPolicy]）。
/// 粘贴文本由调用方直接交给 [TvBoxConfigParser]，不经过本类。
class FeedFetcher {
  final HttpFetch http;

  FeedFetcher({HttpFetch? http}) : http = http ?? const IoHttpFetch();

  /// 获取订阅原文。
  ///
  /// [ref]：http(s) 地址、本地路径、file:// URI，或直接粘贴的 JSON 原文。
  /// 本地路径统一走 [LocalFeedPolicy]（引号剥离、file://、缺扩展名、
  /// 大小/空文件校验、编码解码）。
  ///
  /// ETag 协商（docs/13 B2）：[etag] 非空时请求携带 `if-none-match`，服务端
  /// 返回 304 则 [FetchResult.notModified] 为 true、[FetchResult.body] 为空；
  /// 调用方应回退使用已缓存的订阅原文。
  Future<FetchResult> fetchSubscription(
    String ref, {
    String? etag,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    var input = ref.trim();
    if (input.length >= 2 &&
        ((input.startsWith('"') && input.endsWith('"')) ||
            (input.startsWith("'") && input.endsWith("'")))) {
      input = input.substring(1, input.length - 1).trim();
    }

    // 粘贴 JSON 原文
    if (LocalFeedPolicy.isPastedJson(input)) {
      return FetchResult(
        url: Uri.parse('pasted:tvbox-config'),
        statusCode: 200,
        body: input,
      );
    }

    final isRemote = input.startsWith('http://') || input.startsWith('https://');
    if (!isRemote) {
      try {
        final read = LocalFeedPolicy.readFile(input);
        return FetchResult(
          url: read.uri,
          statusCode: 200,
          body: read.body,
          headers: {'x-local-kind': read.kind.name, 'x-local-path': read.path},
        );
      } on LocalFeedException catch (e) {
        throw FetchException(e.message);
      }
    }

    return http.get(
      Uri.parse(input),
      headers: {
        if (etag != null && etag.isNotEmpty) 'if-none-match': etag,
        ...headers,
      },
      timeout: timeout,
    );
  }

  /// 目录批量读取（本地策略：扩展名过滤、数量上限、坏文件跳过）。
  LocalDirReadResult fetchDirectory(String ref) =>
      LocalFeedPolicy.readDirectory(ref);
}
