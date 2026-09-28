import 'dart:ui';
import 'package:flutter/material.dart';

/// 液态玻璃 + 新拟态设计令牌（浅色默认，docs/15）。
class LiquidNeuColors {
  static const page = Color(0xFFE8EEF5);
  static const glass = Color(0x9EFFFFFF); // 62% white
  static const glassStrong = Color(0xB8FFFFFF);
  static const surface = Color(0xFFF4F7FB);
  static const ink = Color(0xFF152033);
  static const ink2 = Color(0xFF3F4A5C);
  static const ink3 = Color(0xFF6B7789);
  static const brand = Color(0xFF2F7FD1);
  static const brandSoft = Color(0x332F7FD1);
  static const neuLight = Color(0xFFFFFFFF);
  static const neuDark = Color(0xFFA8B7C8);
  static const line = Color(0x1A152033);
  static const ok = Color(0xFF1F8A4C);
  static const warn = Color(0xFFB26A00);
  static const bad = Color(0xFFC0322B);
}

/// 新拟态阴影。
BoxDecoration neuDecoration({
  double radius = 20,
  bool pressed = false,
  Color? color,
}) {
  final base = color ?? LiquidNeuColors.page;
  return BoxDecoration(
    color: base,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: pressed
        ? [
            BoxShadow(
              color: LiquidNeuColors.neuDark.withValues(alpha: 0.45),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: LiquidNeuColors.neuLight.withValues(alpha: 0.9),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
          ]
        : [
            BoxShadow(
              color: LiquidNeuColors.neuDark.withValues(alpha: 0.5),
              offset: const Offset(6, 6),
              blurRadius: 14,
            ),
            BoxShadow(
              color: LiquidNeuColors.neuLight.withValues(alpha: 0.95),
              offset: const Offset(-6, -6),
              blurRadius: 14,
            ),
          ],
  );
}

/// 液态玻璃面板。
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final Color? tint;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 22,
    this.padding = const EdgeInsets.all(16),
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? LiquidNeuColors.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 新拟态按钮。
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double radius;

  const NeuButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.radius = 16,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: neuDecoration(radius: widget.radius, pressed: _down),
        child: widget.child,
      ),
    );
  }
}

/// 浅色液态玻璃主题（docs/15）。
ThemeData liquidGlassLightTheme({StarFormFactorLike? form}) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: LiquidNeuColors.page,
    colorScheme: const ColorScheme.light(
      primary: LiquidNeuColors.brand,
      onPrimary: Colors.white,
      secondary: LiquidNeuColors.brand,
      surface: LiquidNeuColors.surface,
      onSurface: LiquidNeuColors.ink,
      error: LiquidNeuColors.bad,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: LiquidNeuColors.ink),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: LiquidNeuColors.ink),
      bodySmall: TextStyle(fontSize: 12, color: LiquidNeuColors.ink3),
    ),
    dividerColor: LiquidNeuColors.line,
  );
}

/// 端形态占位（避免 ui_kit 循环依赖）。
abstract class StarFormFactorLike {}