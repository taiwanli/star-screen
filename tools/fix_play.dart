import 'dart:io';

void main() {
  // 1) MediaKit.ensureInitialized in all mains
  for (final app in ['desktop', 'mobile', 'tv']) {
    final f = File(r'C:\Users\Administrator\Desktop\星映 - 副本\apps\' + app + r'\lib\main.dart');
    var t = f.readAsStringSync();
    if (!t.contains('MediaKit.ensureInitialized')) {
      if (!t.contains('package:media_kit/media_kit.dart')) {
        t = t.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:media_kit/media_kit.dart';");
      }
      t = t.replaceFirst('WidgetsFlutterBinding.ensureInitialized();', 'WidgetsFlutterBinding.ensureInitialized();\n    MediaKit.ensureInitialized(); // 视频内核（缺失会导致无法播放）');
    }
    f.writeAsStringSync(t);
    print('mediakit $app');
  }
}
