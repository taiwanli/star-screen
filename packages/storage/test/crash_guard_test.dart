import 'dart:io';

import 'package:star_storage/star_storage.dart';
import 'package:test/test.dart';

void main() {
  test('CrashGuard 落盘', () {
    final dir = Directory.systemTemp.createTempSync('stars-crash');
    final g = CrashGuard.install(baseDir: dir.path);
    g.record('test', 'boom', stack: 'stack');
    final logDir = Directory('${dir.path}${Platform.pathSeparator}logs');
    expect(logDir.existsSync(), isTrue);
    final files = logDir.listSync().whereType<File>().toList();
    expect(files, isNotEmpty);
    expect(files.first.readAsStringSync(), contains('boom'));
  });
}
