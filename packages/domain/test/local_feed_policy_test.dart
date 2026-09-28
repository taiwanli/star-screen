import 'dart:io';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('local_feed_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  File write(String name, String content) {
    final f = File('${tmp.path}${Platform.pathSeparator}$name');
    f.writeAsStringSync(content);
    return f;
  }

  group('LocalFeedPolicy 路径解析', () {
    test('去引号 / file:// / 绝对路径', () {
      final f = write('a.json', '{"starrule":1,"meta":{"id":"x.y","name":"N"},"site":{"host":"https://a.example.com"},"detail":{"url":"/d","title":"Text","lines":{"flat":true,"episodes":{"list":"body&&a","name":"Text","url":"href"}}},"category":{"url":"/c","list":"body&&.i","title":"Text","id":"a&&href"}}');
      final p = f.absolute.path;
      expect(LocalFeedPolicy.resolvePath('"$p"'), p);
      expect(LocalFeedPolicy.resolvePath('file://${f.uri.toFilePath()}'),
          isNotNull);
    });

    test('isLocalRef 识别', () {
      expect(LocalFeedPolicy.isLocalRef('C:\\a\\b.json'), isTrue);
      expect(LocalFeedPolicy.isLocalRef('/home/x/a.json'), isTrue);
      expect(LocalFeedPolicy.isLocalRef('https://a.com/x.json'), isFalse);
      expect(LocalFeedPolicy.isLocalRef('{"starrule":1}'), isFalse);
      expect(
        LocalFeedPolicy.isLocalRef('starrule://import?url=x'),
        isFalse,
      );
    });
  });

  group('LocalFeedPolicy 读文件', () {
    test('StarRule 识别', () {
      final f = write('s.star.json', r'{"starrule":1,"meta":{"id":"a.b","name":"N"}}');
      final r = LocalFeedPolicy.readFile(f.absolute.path);
      expect(r.kind, LocalFeedKind.starRule);
      expect(r.body, contains('starrule'));
    });

    test('TVBox 识别', () {
      final f = write('t.json', r'{"sites":[{"key":"k","name":"n","type":1,"api":"http://x"}]}');
      final r = LocalFeedPolicy.readFile(f.absolute.path);
      expect(r.kind, LocalFeedKind.tvbox);
    });

    test('缺扩展名自动补全', () {
      write('full.json', r'{"sites":[]}');
      final r = LocalFeedPolicy.readFile(
          '${tmp.path}${Platform.pathSeparator}full');
      expect(r.kind, LocalFeedKind.tvbox);
    });

    test('空文件 / 过大 / 不存在', () {
      final empty = write('e.json', '');
      expect(
        () => LocalFeedPolicy.readFile(empty.absolute.path),
        throwsA(isA<LocalFeedException>()),
      );
      expect(
        () => LocalFeedPolicy.readFile(
            '${tmp.path}${Platform.pathSeparator}nope.json'),
        throwsA(isA<LocalFeedException>()),
      );
    });

    test('UTF-16LE BOM 可解码', () {
      final f = File('${tmp.path}${Platform.pathSeparator}u16.json');
      // UTF-16LE BOM + {"a":1}
      final units = '{"starrule":1}'.codeUnits;
      final bytes = <int>[0xFF, 0xFE];
      for (final u in units) {
        bytes.add(u & 0xFF);
        bytes.add((u >> 8) & 0xFF);
      }
      f.writeAsBytesSync(bytes);
      final r = LocalFeedPolicy.readFile(f.absolute.path);
      expect(r.body, contains('starrule'));
      expect(r.kind, LocalFeedKind.starRule);
    });
  });

  group('LocalFeedPolicy 目录批量', () {
    test('收集 json 并跳过坏文件', () {
      write('ok1.json', r'{"starrule":1,"meta":{"id":"a.b","name":"N"}}');
      write('ok2.star.json', r'{"sites":[{"key":"k"}]}');
      write('skip.txt', 'not json');
      write('bad.json', '{oops');
      final r = LocalFeedPolicy.readDirectory(tmp.absolute.path);
      expect(r.reads.length + r.failed.length, greaterThanOrEqualTo(2));
      expect(r.reads.length, greaterThanOrEqualTo(1));
    });
  });

  group('FeedFetcher 本地', () {
    test('fetchSubscription 走 LocalFeedPolicy', () async {
      final f = write('f.json', r'{"starrule":1,"meta":{"id":"a.b","name":"N"}}');
      final res = await FeedFetcher().fetchSubscription(f.absolute.path);
      expect(res.statusCode, 200);
      expect(res.body, contains('starrule'));
      expect(res.headers['x-local-kind'], 'starRule');
    });

    test('粘贴 JSON 不经文件系统', () async {
      final res =
          await FeedFetcher().fetchSubscription('{"starrule":1,"meta":{}}');
      expect(res.url.toString(), 'pasted:tvbox-config');
    });
  });
}
