import 'dart:async';

import 'package:flutter/material.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';
import 'package:video_player/video_player.dart' as vp;

/// 多内核播放页（Exo / 外部播放器）：简洁玻璃顶栏 + 内核视频面。
/// libmpv 走完整 [PlayerPage]；本页覆盖另外两个内核。
class MultiEnginePlayerPage extends StatefulWidget {
  const MultiEnginePlayerPage({
    super.key,
    required this.controller,
    required this.title,
    required this.engineLabel,
  });

  final PlayerController controller;
  final String title;
  final String engineLabel;

  @override
  State<MultiEnginePlayerPage> createState() => _MultiEnginePlayerPageState();
}

class _MultiEnginePlayerPageState extends State<MultiEnginePlayerPage> {
  StreamSubscription<PlayerEvent>? _sub;
  bool _playing = true;
  int _pos = 0;
  int _dur = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.events.listen((e) {
      if (!mounted) return;
      if (e is PlayerPosition) {
        setState(() {
          _pos = e.positionSec;
          _dur = e.durationSec;
        });
      } else if (e is PlayerFailed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text(e.reason, style: const TextStyle(color: StarColors.bad)),
        ));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.controller.dispose();
    super.dispose();
  }

  String _fmt(int sec) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (c is ExoVideoPlayerController)
            Builder(builder: (_) {
              final v = c.video;
              return v == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white54))
                  : vp.VideoPlayer(v);
            })
          else if (c is ExternalPlayerController)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_new,
                      color: Colors.white70, size: 52),
                  const SizedBox(height: 14),
                  Text('已启动外部播放器 · ${widget.engineLabel}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('请在系统弹出的窗口中观看',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55))),
                ],
              ),
            )
          else
            const ColoredBox(color: Colors.black),
          // 顶栏
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: StarColors.glassStrong,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: StarColors.ink),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(widget.title,
                            style: const TextStyle(
                                color: StarColors.ink,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: StarColors.brandSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(widget.engineLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: StarColors.brand,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: StarColors.glassStrong,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: StarColors.ink,
                          ),
                          onPressed: () async {
                            if (_playing) {
                              await widget.controller.pause();
                            } else {
                              await widget.controller.play();
                            }
                            setState(() => _playing = !_playing);
                          },
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3.5,
                              activeTrackColor: StarColors.brand,
                              inactiveTrackColor: StarColors.line,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: (_dur == 0
                                      ? 0
                                      : (_pos.clamp(0, _dur) / _dur))
                                  .toDouble(),
                              onChanged: (v) {
                                final sec =
                                    (_dur * v).round();
                                widget.controller.seek(sec);
                                setState(() => _pos = sec);
                              },
                            ),
                          ),
                        ),
                        Text('${_fmt(_pos)} / ${_fmt(_dur)}',
                            style: const TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: 12,
                                color: StarColors.ink2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
