import 'package:flutter/material.dart';

/// 亮/暗主题（docs/02 §4.6）。避免 main.dart 循环依赖。
class ThemeNotifier extends ValueNotifier<Brightness> {
  ThemeNotifier() : super(Brightness.light);

  void toggle() =>
      value = value == Brightness.dark ? Brightness.light : Brightness.dark;
}

final themeNotifier = ThemeNotifier();
