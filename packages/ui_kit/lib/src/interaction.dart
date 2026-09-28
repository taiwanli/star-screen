import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

/// 交互 Token（docs/2.0 §4）：三端统一的动效/反馈参数。
class Ix {
  const Ix._();

  static const double scaleHover = 1.03;
  static const double scalePress = 0.96;
  static const double scaleFocus = 1.03;

  static const Duration micro = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// 全局反馈：音效默认开（设置可关）+ 触感（移动端）。
class StarFeedback {
  StarFeedback._();

  static bool soundEnabled = true;
  static bool reduceMotion = false;
  static bool hapticEnabled = true;

  static final AudioPlayer _player = AudioPlayer(playerId: 'star-feedback');
  static bool _busy = false;

  static Future<void> _play(String asset) async {
    if (!soundEnabled || _busy) return;
    _busy = true;
    try {
      await _player.stop();
      await _player.play(
        AssetSource('packages/star_ui_kit/assets/$asset'),
        volume: 0.55,
      );
    } on Object {
      // 无音频设备/资源缺失时静默
    } finally {
      _busy = false;
    }
  }

  /// 选中刻度（选集/Chip/Tab）。
  static Future<void> selection() async {
    await _play('tick.wav');
    if (hapticEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } on Object {}
    }
  }

  /// 按钮确认。
  static Future<void> tap() async {
    await _play('tick.wav');
    if (hapticEnabled) {
      try {
        await HapticFeedback.lightImpact();
      } on Object {}
    }
  }

  /// 成功。
  static Future<void> success() async {
    await _play('success.wav');
    if (hapticEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } on Object {}
    }
  }

  /// 错误。
  static Future<void> error() async {
    await _play('error.wav');
    if (hapticEnabled) {
      try {
        await HapticFeedback.heavyImpact();
      } on Object {}
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
