import 'package:flutter/material.dart';

import 'interaction.dart';

/// P2 装饰组件：按钮按压、图标 morph、空态 pulse、指示器滑动。
class IxPress extends StatefulWidget {
  const IxPress({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = Ix.scalePress,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<IxPress> createState() => _IxPressState();
}

class _IxPressState extends State<IxPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        StarFeedback.tap();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: StarFeedback.reduceMotion
            ? 1
            : (_down ? widget.scale : 1.0),
        duration: Ix.micro,
        curve: Ix.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 播放/暂停图标 morph（圆形填充内 icon 交叉淡入）。
class IxPlayPause extends StatelessWidget {
  const IxPlayPause({
    super.key,
    required this.playing,
    required this.onToggle,
  });

  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IxPress(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: Ix.micro,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2F7FD1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F7FD1).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: Ix.micro,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(playing),
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// 空状态：插画区 + 按钮一次性 pulse。
class IxEmptyPulse extends StatefulWidget {
  const IxEmptyPulse({super.key, required this.child});
  final Widget child;

  @override
  State<IxEmptyPulse> createState() => _IxEmptyPulseState();
}

class _IxEmptyPulseState extends State<IxEmptyPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Ix.spring))
            .animate(_c),
        child: widget.child,
      ),
    );
  }
}

/// 底部滑动指示器（分类 Chip / Tab）。
class IxSlidingIndicator extends StatelessWidget {
  const IxSlidingIndicator({
    super.key,
    required this.count,
    required this.index,
    required this.width,
  });

  final int count;
  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    final w = width / count;
    return SizedBox(
      height: 3,
      width: width,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AnimatedAlign(
            duration: Ix.base,
            curve: Ix.spring,
            alignment: Alignment(
              count <= 1
                  ? 0
                  : -1 + 2.0 * (index.clamp(0, count - 1) / (count - 1)),
              0,
            ),
            child: Container(
              width: w * 0.6,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF2F7FD1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 详情文字 stagger 入场。
class IxStaggerColumn extends StatelessWidget {
  const IxStaggerColumn({
    super.key,
    required this.children,
    this.step = 40,
  });

  final List<Widget> children;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 280 + i * step),
            curve: Ix.easeOut,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - v)),
                child: child,
              ),
            ),
            child: children[i],
          ),
      ],
    );
  }
}

/// 搜索结果条目 stagger。
class IxStaggerList extends StatelessWidget {
  const IxStaggerList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 240 + (i % 8) * 30),
          curve: Ix.easeOut,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - v)),
              child: child,
            ),
          ),
          child: itemBuilder(context, i),
        );
      },
    );
  }
}
