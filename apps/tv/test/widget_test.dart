import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:star_tv/main.dart';

void _prepareSqlite3() {
  final roots = [
    Directory.current.path,
    '${Directory.current.path}/..',
    '${Directory.current.path}/../..',
  ];
  for (final root in roots) {
    for (final rel in [
      '.dart_tool/lib/sqlite3.dll',
      'build/native_assets/windows/sqlite3.dll',
    ]) {
      final file = File('$root${Platform.pathSeparator}$rel');
      if (file.existsSync()) {
        DynamicLibrary.open(file.absolute.path);
        return;
      }
    }
  }
}

void main() {
  setUpAll(_prepareSqlite3);

  testWidgets('TV 壳渲染：顶部栏目 + 空库合规引导', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const StarApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('首页'), findsWidgets);
    expect(find.textContaining('还没有内容源'), findsOneWidget);
    expect(find.text('设置'), findsWidgets);
  });
}
