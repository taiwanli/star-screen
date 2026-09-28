import 'dart:io';

import 'package:star_domain/star_domain.dart';

/// 定位 test/fixtures 目录：兼容「包目录内 dart test」与
/// 「workspace 根 dart test packages/domain」两种执行方式（CI 用后者）。
Directory fixturesDir() {
  Directory dir = Directory.current;
  while (true) {
    for (final rel in ['test/fixtures', 'packages/domain/test/fixtures']) {
      final candidate = Directory('${dir.path}/$rel');
      if (candidate.existsSync()) return candidate;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('未找到 test/fixtures（请从仓库根或包目录运行）');
    }
    dir = parent;
  }
}

File fixture(String name) => File('${fixturesDir().path}/$name');

/// 可编程的 HttpFetch 假实现：记录请求并按 handler 返回。
class FakeHttpFetch implements HttpFetch {
  final FetchResult Function(Uri url) handler;
  final List<Uri> requested = [];

  FakeHttpFetch(this.handler);

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    requested.add(url);
    return handler(url);
  }

  @override
  Future<FetchResult> post(
    Uri url, {
    String body = '',
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async {
    requested.add(url);
    return handler(url);
  }
}
