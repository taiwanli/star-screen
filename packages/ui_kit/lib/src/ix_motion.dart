import 'package:flutter/material.dart';

import 'interaction.dart';

/// M2 流转动效（docs/2.0 §3）：导航转场、错误抖动、收藏 pop、骨架屏、count-up。
class IxMotion {
  const IxMotion._();

  /// 页面转场：淡入 + 轻微上移。
  static PageRouteBuilder<T> page<T>(Widget child, {String? heroTag}) {
    return PageRouteBuilder<T>(
      transitionDuration: Ix.base,
      reverseTransitionDuration: Ix.micro * 2,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Ix.easeOut);
        if (StarFeedback.reduceMotion) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// 共享元素转场（海报 → 播放）。
  static PageRouteBuilder<T> sharedAxis<T>({
    required Widget child,
    required String tag,
    required Widget placeholder,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (context, anim, secondary, child) {
        final curved = CurvedAnimation(parent: anim, curve: Ix.easeOut);
        return FadeTransition(
          opacity: curved,
          child: child,
        );
      },
    );
  }
}

/// 错误提示条：滑入 + 图标微抖 + 可选动作。
class IxErrorBar {
  static void show(
    BuildContext context,
    String message, {
    String actionLabel = '换源',
    VoidCallback? onAction,
  }) {
    StarFeedback.error();
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const _ShakeIcon(
              child: Icon(Icons.error_outline, color: Color(0xFFC0322B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Color(0xFF152033))),
            ),
            if (onAction != null)
              TextButton(
                onPressed: () {
                  m.hideCurrentSnackBar();
                  onAction();
                },
                child: Text(actionLabel,
                    style: const TextStyle(color: Color(0xFF2F7FD1))),
              ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    StarFeedback.success();
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF1F8A4C)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Color(0xFF152033))),
            ),
          ],
        ),
      ),
    );
  }
}

/// 收藏 pop：心形 1.2→1.0 + 音效。
class IxFavoritePulse extends StatefulWidget {
  const IxFavoritePulse({
    super.key,
    required this.onTap,
    required this.active,
  });

  final VoidCallback onTap;
  final bool active;

  @override
  State<IxFavoritePulse> createState() => _IxFavoritePulseState();
}

class _IxFavoritePulseState extends State<IxFavoritePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Ix.micro,
    reverseDuration: Ix.micro,
  );
  late final Animation<double> _s = Tween(begin: 1.0, end: 1.25)
      .chain(CurveTween(curve: Ix.spring))
      .animate(_c);

  Future<void> _pulse() async {
    await _c.forward(from: 0);
    await _c.reverse();
    await StarFeedback.success();
    widget.onTap();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _s,
      child: IconButton(
        onPressed: _pulse,
        icon: Icon(
          widget.active ? Icons.favorite : Icons.favorite_border,
          color: widget.active ? const Color(0xFFC0322B) : const Color(0xFF6B7789),
        ),
      ),
    );
  }
}

/// 图标微抖（错误）。
class _ShakeIcon extends StatefulWidget {
  const _ShakeIcon({required this.child});
  final Widget child;

  @override
  State<_ShakeIcon> createState() => _ShakeIconState();
}

class _ShakeIconState extends State<_ShakeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void initState() {
    super.initState();
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        final dx = 3 * (1 - t) * ((t * 8) % 2 == 0 ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// 骨架屏 shimmer（M3 加载）。
class IxSkeleton extends StatefulWidget {
  const IxSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<IxSkeleton> createState() => _IxSkeletonState();
}

class _IxSkeletonState extends State<IxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * v, 0),
              end: Alignment(1 + 2 * v, 0),
              colors: const [
                Color(0xFFE8EEF5),
                Color(0xFFF7FAFD),
                Color(0xFFE8EEF5),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 数字 count-up（导入统计等）。
class IxCountUp extends StatelessWidget {
  const IxCountUp({
    super.key,
    required this.value,
    this.duration = Ix.base,
    this.style,
  });

  final int value;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Ix.easeOut,
      builder: (_, v, __) => Text('$v', style: style),
    );
  }
}
