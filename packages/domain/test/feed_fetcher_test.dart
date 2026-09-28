import 'dart:io';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FeedFetcher —— 远程订阅（进程内 HttpServer）', () {
    late HttpServer server;
    late Uri url;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (request.uri.path == '/missing.json') {
          request.response.statusCode = 404;
          await request.response.close();
          return;
        }
        // ETag 协商：命中 If-None-Match 返回 304
        if (request.headers.value(HttpHeaders.ifNoneMatchHeader) == 'W/"v1"') {
          request.response.statusCode = 304;
          await request.response.close();
          return;
        }
        request.response.headers.set(HttpHeaders.etagHeader, 'W/"v1"');
        request.response.write('{"sites":[]}');
        await request.response.close();
      });
      url = Uri.parse('http://127.0.0.1:${server.port}/box.json');
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('首次获取：200 + ETag + 原文', () async {
      final result = await FeedFetcher().fetchSubscription(url.toString());
      expect(result.statusCode, 200);
      expect(result.etag, 'W/"v1"');
      expect(result.body, '{"sites":[]}');
      expect(result.notModified, isFalse);
    });

    test('携带 ETag 二次获取：304 Not Modified', () async {
      final fetcher = FeedFetcher();
      final first = await fetcher.fetchSubscription(url.toString());
      final second =
          await fetcher.fetchSubscription(url.toString(), etag: first.etag);
      expect(second.notModified, isTrue);
      expect(second.body, isEmpty);
    });


    test('404 抛 FetchException（带状态码）', () async {
      final fetcher = FeedFetcher();
      await expectLater(
        fetcher.fetchSubscription('http://127.0.0.1:${server.port}/missing.json'),
        throwsA(isA<FetchException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('默认 UA 标识星映客户端', () async {
      String? ua;
      final probe = const IoHttpFetch();
      final probeServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      probeServer.listen((request) async {
        ua = request.headers.value(HttpHeaders.userAgentHeader);
        await request.response.close();
      });
      try {
        await probe.get(Uri.parse('http://127.0.0.1:${probeServer.port}/'));
      } on Object {
        // 响应未写 body 即关闭，忽略
      } finally {
        await probeServer.close(force: true);
      }
      expect(ua, contains('StarScreen'));
    });
  });

  group('FeedFetcher —— 本地文件', () {
    test('读取存在的本地文件', () async {
      final tmp = File(
          '${Directory.systemTemp.path}/star_feed_${DateTime.now().microsecondsSinceEpoch}.json');
      tmp.writeAsStringSync('{"storeHouse":[]}');
      addTearDown(tmp.deleteSync);

      final result = await FeedFetcher().fetchSubscription(tmp.path);
      expect(result.body, '{"storeHouse":[]}');
    });

    test('文件不存在抛 FetchException', () async {
      await expectLater(
        FeedFetcher().fetchSubscription('Z:/not/exist/box.json'),
        throwsA(isA<FetchException>()),
      );
    });
  });
}
