import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:star_mobile/main.dart';

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

  testWidgets('手机壳渲染：底部 4 标签 + 空库合规引导', (tester) async {
    await tester.pumpWidget(const StarApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 300));

    // 「首页」同时出现在应用栏标题与底部标签栏
    expect(find.text('首页'), findsWidgets);
    expect(find.textContaining('不内置任何内容源'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('搜索'), findsWidgets);
  });
}
