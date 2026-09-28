import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:star_desktop/main.dart';

/// flutter test 不加载 sqlite3 native assets（docs/08 §1）。
/// 预加载仓库内 sqlite3.dll，进程查找回退才能解析 sqlite3_initialize。
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
      if (!file.existsSync()) continue;
      DynamicLibrary.open(file.absolute.path);
      return;
    }
  }
}

void main() {
  setUpAll(_prepareSqlite3);

  testWidgets('桌面壳渲染：顶栏/导航/空库合规引导', (tester) async {
    await tester.pumpWidget(const StarApp());
    // 服务装配（内存库）+ 首页空态，逐帧推进异步链
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('星映'), findsWidgets);
    expect(find.textContaining('不内置任何内容源'), findsOneWidget);
    expect(find.text('源管理'), findsOneWidget);
    expect(find.text('去添加源'), findsWidgets);
  });
}
