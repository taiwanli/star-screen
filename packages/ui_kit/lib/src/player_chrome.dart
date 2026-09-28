import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_neu.dart';

/// 播放器镀铬 v3 —— 对齐「液态玻璃 + 新拟态」（docs/15 / docs/19）。
///
/// 视频上的 OSD 不用纯黑 Material 条，改为 **悬浮玻璃胶囊**：
/// 白玻璃 + 描边高光 + 新拟态阴影 + 品牌蓝进度，字色用主应用 `ink`。

/// 顶栏：返回 + 标题（玻璃浮层）。
class PlayerTopChrome extends StatelessWidget {
  const PlayerTopChrome({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 0),
      child: Row(
        children: [
          _GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  tooltip: '返回',
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LiquidNeuColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LiquidNeuColors.ink3,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          const Spacer(),
          if (trailing != null && trailing!.isNotEmpty)
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: trailing!),
            ),
        ],
      ),
    );
  }
}

/// 单根进度条（新拟态滑块 + 品牌蓝 + 拖拽时间气泡）。
class PlayerSeekSlider extends StatefulWidget {
  const PlayerSeekSlider({
    super.key,
    required this.positionSec,
    required this.durationSec,
    required this.bufferSec,
    required this.onSeek,
  });

  final int positionSec;
  final int durationSec;
  final int bufferSec;
  final ValueChanged<int> onSeek;

  @override
  State<PlayerSeekSlider> createState() => _PlayerSeekSliderState();
}

class _PlayerSeekSliderState extends State<PlayerSeekSlider> {
  double? _dragSec;

  static String fmt(int sec) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.durationSec > 0 ? widget.durationSec : 1;
    final max = dur.toDouble();
    final value = (_dragSec ?? widget.positionSec.toDouble())
        .clamp(0.0, max);
    final buffer = widget.bufferSec.clamp(0, dur).toDouble();
    final bubbleSec = (_dragSec ?? widget.positionSec.toDouble()).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackW = constraints.maxWidth - 24;
        final x = (value / max) * trackW + 12;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FractionallySizedBox(
                widthFactor: buffer / max,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: LiquidNeuColors.brandSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: LiquidNeuColors.brand,
                inactiveTrackColor: LiquidNeuColors.line,
                thumbColor: Colors.white,
                overlayColor: LiquidNeuColors.brandSoft,
              ),
              child: Slider(
                value: value,
                max: max,
                onChangeStart: (_) =>
                    setState(() => _dragSec = widget.positionSec.toDouble()),
                onChanged: (v) => setState(() => _dragSec = v),
                onChangeEnd: (v) {
                  setState(() => _dragSec = null);
                  widget.onSeek(v.round());
                },
              ),
            ),
            if (_dragSec != null)
              Positioned(
                left: (x - 36).clamp(0, constraints.maxWidth - 72),
                top: -34,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: LiquidNeuColors.glassStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    fmt(bubbleSec),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LiquidNeuColors.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 底栏：玻璃浮层（进度 + 主控一行）。
class PlayerBottomChrome extends StatelessWidget {
  const PlayerBottomChrome({
    super.key,
    required this.playing,
    required this.positionSec,
    required this.durationSec,
    required this.bufferSec,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onPrev,
    required this.onNext,
    required this.volume,
    required this.onVolume,
    required this.onMute,
    required this.isMuted,
    required this.onOpenSettings,
    required this.onFullscreen,
    required this.isFullscreen,
    this.rate,
    this.onSkipIntro,
    this.onSkipOutro,
  });

  final bool playing;
  final int positionSec;
  final int durationSec;
  final int bufferSec;
  final ValueChanged<int> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final double volume;
  final ValueChanged<double> onVolume;
  final VoidCallback onMute;
  final bool isMuted;
  final VoidCallback onOpenSettings;
  final VoidCallback onFullscreen;
  final bool isFullscreen;
  final double? rate;
  final VoidCallback? onSkipIntro;
  final VoidCallback? onSkipOutro;

  String _fmt(int sec) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    // 报告示意：底部悬浮玻璃胶囊（居中、限宽），与顶栏同基因
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: _GlassPill(
        radius: 24,
        blur: 28,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerSeekSlider(
              positionSec: positionSec,
              durationSec: durationSec,
              bufferSec: bufferSec,
              onSeek: onSeek,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                _PlayBtn(onTap: onTogglePlay, playing: playing),
                if (onPrev != null) ...[
                  const SizedBox(width: 4),
                  _IconBtn(
                    icon: Icons.skip_previous_rounded,
                    onTap: () => onPrev!(),
                    tooltip: '上一集',
                  ),
                ],
                if (onNext != null) ...[
                  const SizedBox(width: 2),
                  _IconBtn(
                    icon: Icons.skip_next_rounded,
                    onTap: () => onNext!(),
                    tooltip: '下一集',
                  ),
                ],
                const SizedBox(width: 8),
                _IconBtn(
                  icon: isMuted || volume <= 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  onTap: onMute,
                  tooltip: '静音',
                  size: 20,
                ),
                SizedBox(
                  width: 72,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: LiquidNeuColors.brand,
                      inactiveTrackColor: LiquidNeuColors.line,
                      thumbColor: Colors.white,
                      overlayColor: LiquidNeuColors.brandSoft,
                    ),
                    child: Slider(
                      value: volume.clamp(0, 1),
                      onChanged: onVolume,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_fmt(positionSec)} / ${_fmt(durationSec)}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 12,
                    color: LiquidNeuColors.ink2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (rate != null && rate != 1.0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LiquidNeuColors.brandSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${rate!.toStringAsFixed(2).replaceAll(RegExp(r'\\.?0+$'), '')}x',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LiquidNeuColors.brand,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (onSkipIntro != null)
                  _ChipBtn(label: '跳过片头', onTap: () => onSkipIntro!()),
                if (onSkipOutro != null) ...[
                  const SizedBox(width: 6),
                  _ChipBtn(label: '跳过片尾', onTap: () => onSkipOutro!()),
                ],
                const SizedBox(width: 6),
                _IconBtn(
                  icon: Icons.tune_rounded,
                  onTap: onOpenSettings,
                  tooltip: '设置',
                  size: 20,
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  onTap: onFullscreen,
                  tooltip: '全屏',
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }
}

/// 玻璃浮层（与主应用 LiquidGlass 同基因，视频场景略加深 tint 保对比）。
class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.child,
    this.radius = 20,
    this.blur = 22,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // 视频上用略高不透明度白玻璃，字色 ink 与全站一致
            color: LiquidNeuColors.glassStrong,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
              BoxShadow(
                color: LiquidNeuColors.neuLight.withValues(alpha: 0.35),
                offset: const Offset(-2, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlayBtn extends StatelessWidget {
  const _PlayBtn({required this.onTap, required this.playing});

  final VoidCallback onTap;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return _IconBtn(
      icon: playing
          ? Icons.pause_rounded
          : Icons.play_arrow_rounded,
      onTap: onTap,
      size: 28,
      primary: true,
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.tooltip,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: primary ? LiquidNeuColors.brand : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: size,
            color: primary ? Colors.white : LiquidNeuColors.ink,
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LiquidNeuColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: LiquidNeuColors.ink2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 控制层自动隐藏。
class PlayerChromeVisibility extends StatefulWidget {
  const PlayerChromeVisibility({
    super.key,
    required this.idle,
    required this.builder,
  });

  final Duration idle;
  final Widget Function(BuildContext context, bool visible, void Function() poke)
      builder;

  @override
  State<PlayerChromeVisibility> createState() => _PlayerChromeVisibilityState();
}

class _PlayerChromeVisibilityState extends State<PlayerChromeVisibility> {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.idle, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _poke() {
    if (!_visible && mounted) setState(() => _visible = true);
    _arm();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _visible, _poke);
}

/// 键盘快捷键。
class PlayerKeyboardHandler extends StatelessWidget {
  const PlayerKeyboardHandler({
    super.key,
    required this.onTogglePlay,
    required this.onSeekRelative,
    required this.onFullscreen,
    required this.onMute,
    required this.onVolumeDelta,
    required this.child,
  });

  final VoidCallback onTogglePlay;
  final ValueChanged<int> onSeekRelative;
  final VoidCallback onFullscreen;
  final VoidCallback onMute;
  final ValueChanged<double> onVolumeDelta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): onTogglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            () => onSeekRelative(-10),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            () => onSeekRelative(10),
        const SingleActivator(LogicalKeyboardKey.keyF): onFullscreen,
        const SingleActivator(LogicalKeyboardKey.keyM): onMute,
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            () => onVolumeDelta(0.05),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            () => onVolumeDelta(-0.05),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
