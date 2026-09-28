import 'package:flutter/material.dart';

/// 颜色令牌（sys-color-*）。品牌与语义色 = 规范锁死值，三端零色差。
/// 默认：液态玻璃 + 新拟态浅色（docs/15）。
class StarColors {
  static const page = Color(0xFFE8EEF5); // 浅色主底
  static const surface = Color(0xFFF4F7FB); // 面板
  static const raised = Color(0xFFFFFFFF); // 浮起/玻璃
  static const line = Color(0x1A152033);
  static const lineStrong = Color(0x33152033);
  static const ink = Color(0xFF152033);
  static const ink2 = Color(0xFF3F4A5C);
  static const ink3 = Color(0xFF6B7789);
  static const ink4 = Color(0xFF8B96A8);
  static const brand = Color(0xFF2F7FD1); // 品牌（锁死蓝系）
  static const brandHi = Color(0xFF5AA0E8);
  static const brandLo = Color(0xFF1F6FB4);
  static const ok = Color(0xFF1F8A4C);
  static const warn = Color(0xFFB26A00);
  static const bad = Color(0xFFC0322B);

  static const brandSoft = Color(0x292F7FD1);
  static const scrim = Color(0xB3E8EEF5);

  // 液态玻璃 / 新拟态
  static const glass = Color(0x9EFFFFFF);
  static const glassStrong = Color(0xB8FFFFFF);
  static const neuLight = Color(0xFFFFFFFF);
  static const neuDark = Color(0xFFA8B7C8);
}
