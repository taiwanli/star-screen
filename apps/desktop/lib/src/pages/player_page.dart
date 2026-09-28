import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_lan/star_lan.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';
import 'package:window_manager/window_manager.dart';

/// 播放页 v2（docs/19）：黑场可读镀铬 + 单进度条 + 真全屏 + 自动隐藏 + 快捷键。
class PlayerPage extends StatefulWidget {
  final MediaKitPlayerController controller;
  final PlaybackSession session;
  final String title;
  final String? lineId;
  final String? nextEpisodeTitle;
  final VoidCallback? onPlayNext;
  final String? posterHeroTag;
  final String? posterUrl;

  const PlayerPage({
    super.key,
    required this.controller,
    required this.session,
    required this.title,
    this.lineId,
    this.nextEpisodeTitle,
    this.onPlayNext,
    this.posterHeroTag,
    this.posterUrl,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WindowListener {
  late final VideoController _video = VideoController(widget.controller.player);
  StreamSubscription<String>? _failureSub;
  StreamSubscription<PlayerEvent>? _eventSub;
  bool _completed = false;
  DlnaCastClient? _cast;
  List<DlnaDevice> _castDevices = const [];
  bool _castScanning = false;

  bool _isFullscreen = false;
  double _volume = 1.0;
  bool _muted = false;
  int _bufferSec = 0;

  void _onStyleChanged(SubtitleStyle style) {
    widget.controller.subtitleStyle = style;
    setState(() {});
  }

  Future<void> _toggleFullscreen() async {
    final next = !_isFullscreen;
    setState(() => _isFullscreen = next);
    try {
      if (next) {
        await windowManager.setFullScreen(true);
      } else {
        await windowManager.setFullScreen(false);
      }
    } on Object {
      // 无窗口管理器时忽略（如测试）
    }
  }

  Future<void> _openCast() async {
    _cast ??= DlnaCastClient();
    setState(() => _castScanning = true);
    final devices = await _cast!.discover();
    if (!mounted) return;
    setState(() {
      _castDevices = devices;
      _castScanning = false;
    });
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: StarColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CastDeviceList(
            devices: [
              for (final d in _castDevices)
                CastDeviceVm(id: d.location, name: d.name),
            ],
            scanning: _castScanning,
            onScan: () {
              Navigator.of(context).pop();
              _openCast();
            },
            onCast: (vm) async {
              final device = _castDevices
                  .where((e) => e.location == vm.id)
                  .firstOrNull;
              if (device == null) return;
              final messenger = ScaffoldMessenger.of(context);
              final mediaUrl = widget.session.candidate?.url;
              if (mediaUrl == null || widget.session.candidate!.needsParse) {
                Navigator.of(context).pop();
                messenger.showSnackBar(SnackBar(
                  backgroundColor: StarColors.raised,
                  content: const Text('当前线路不可投屏 —— 请换直链线路',
                      style: TextStyle(color: StarColors.ink)),
                ));
                return;
              }
              final ok = await _cast!.play(device, mediaUrl, title: widget.title);
              if (!mounted) return;
              Navigator.of(context).pop();
              if (!ok) {
                messenger.showSnackBar(SnackBar(
                  backgroundColor: StarColors.raised,
                  content: const Text('投屏失败',
                      style: TextStyle(color: StarColors.ink)),
                ));
                return;
              }
              messenger.showSnackBar(SnackBar(
                backgroundColor: StarColors.raised,
                content: Text('已推送到 ${device.name}',
                    style: const TextStyle(color: StarColors.ink)),
              ));
              await showDialog<void>(
                context: context,
                builder: (_) => _DlnaControlDialog(
                  device: device,
                  cast: _cast!,
                  title: widget.title,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    final style = widget.controller.subtitleStyle;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StarColors.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: _SettingsSheet(
          controller: widget.controller,
          style: style,
          onStyleChanged: _onStyleChanged,
          onCast: _openCast,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _failureSub = widget.session.failures.listen((reason) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text(
            playErrorWithEngineHint(reason,
                engineName: widget.controller.engineName),
            style: const TextStyle(color: StarColors.bad),
          ),
        ));
      }
    });
    _eventSub = widget.controller.events.listen((e) {
      if (e is PlayerCompleted && widget.onPlayNext != null && mounted) {
        setState(() => _completed = true);
      }
      if (e is PlayerPosition && mounted) {
        final buf = widget.controller.player.state.buffer;
        final b = buf.inSeconds;
        if (b != _bufferSec) setState(() => _bufferSec = b);
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _failureSub?.cancel();
    _eventSub?.cancel();
    if (_isFullscreen) {
      windowManager.setFullScreen(false);
    }
    widget.session.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void onWindowMaximize() {}
  @override
  void onWindowUnmaximize() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PlayerKeyboardHandler(
        onTogglePlay: () async {
          final p = widget.controller.player;
          if (p.state.playing) {
            await widget.controller.pause();
          } else {
            await widget.controller.play();
          }
          setState(() {});
        },
        onSeekRelative: (d) {
          final pos = widget.controller.player.state.position.inSeconds + d;
          widget.controller.seek(pos < 0 ? 0 : pos);
          setState(() {});
        },
        onFullscreen: _toggleFullscreen,
        onMute: () => setState(() {
          _muted = !_muted;
          widget.controller.player.setVolume(_muted ? 0 : _volume * 100);
        }),
        onVolumeDelta: (d) {
          setState(() {
            _volume = (_volume + d).clamp(0, 1);
            _muted = _volume <= 0;
            widget.controller.player.setVolume(_volume * 100);
          });
        },
        child: PlayerChromeVisibility(
          idle: const Duration(seconds: 3),
          builder: (context, visible, poke) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: poke,
              onDoubleTap: _toggleFullscreen,
              onPanUpdate: (_) => poke(),
              child: MouseRegion(
                onHover: (_) => poke(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Video(
                        controller: _video,
                        subtitleViewConfiguration:
                            const SubtitleViewConfiguration(visible: false),
                      ),
                    ),
                    if (widget.posterHeroTag != null && widget.posterUrl != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Hero(
                            tag: widget.posterHeroTag!,
                            child: _PosterMorph(url: widget.posterUrl!),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: StarSubtitleOverlay(
                        textStream: widget.controller.player.stream.subtitle,
                        style: SubtitleUiStyle(
                          fontSize: widget.controller.subtitleStyle.fontSize,
                          backgroundOpacity:
                              widget.controller.subtitleStyle.backgroundOpacity,
                          delayMs: widget.controller.subtitleStyle.delayMs,
                        ),
                      ),
                    ),
                    // 顶栏（必须 Positioned，否则 Stack 高度塌缩到顶栏）
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          ignoring: !visible,
                          child: PlayerTopChrome(
                            title: widget.title,
                            subtitle: widget.lineId,
                            onBack: () async {
                              if (_isFullscreen) {
                                await _toggleFullscreen();
                                return;
                              }
                              if (context.mounted) {
                                Navigator.of(context).maybePop();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    // 底栏
                    if (visible)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Builder(
                          builder: (context) {
                            final st = widget.controller.player.state;
                            final position = st.position.inSeconds;
                            final duration = st.duration.inSeconds;
                            return PlayerBottomChrome(
                              playing: st.playing,
                              positionSec: position,
                              durationSec: duration,
                              bufferSec: _bufferSec,
                              onSeek: (v) {
                                widget.controller.seek(v);
                                poke();
                                setState(() {});
                              },
                              onTogglePlay: () async {
                                final p = widget.controller.player;
                                if (p.state.playing) {
                                  await widget.controller.pause();
                                } else {
                                  await widget.controller.play();
                                }
                                poke();
                                setState(() {});
                              },
                              onPrev: null,
                              onNext: widget.onPlayNext == null
                                  ? null
                                  : () {
                                      setState(() => _completed = false);
                                      widget.onPlayNext!();
                                      poke();
                                    },
                              volume: _muted ? 0 : _volume,
                              onVolume: (v) {
                                setState(() {
                                  _volume = v;
                                  _muted = v <= 0;
                                  widget.controller.player.setVolume(v * 100);
                                });
                                poke();
                              },
                              onMute: () {
                                setState(() {
                                  _muted = !_muted;
                                  widget.controller.player
                                      .setVolume(_muted ? 0 : _volume * 100);
                                });
                                poke();
                              },
                              isMuted: _muted,
                              onOpenSettings: () {
                                poke();
                                _openSettings();
                              },
                              onFullscreen: () {
                                poke();
                                _toggleFullscreen();
                              },
                              isFullscreen: _isFullscreen,
                              rate: widget.controller.rate == 0
                                  ? 1.0
                                  : widget.controller.rate,
                              onSkipIntro: () {
                                widget.controller.seek(position + 85);
                                poke();
                                setState(() {});
                              },
                              onSkipOutro: duration > 0
                                  ? () {
                                      widget.controller.seek(duration - 30);
                                      poke();
                                      setState(() {});
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                    if (_completed && widget.onPlayNext != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 110),
                          child: NextEpisodeBanner(
                            title:
                                '即将播放：${widget.nextEpisodeTitle ?? '下一集'}',
                            onPlayNext: () {
                              setState(() => _completed = false);
                              widget.onPlayNext!();
                            },
                            onCancel: () =>
                                setState(() => _completed = false),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 设置面板：倍速 / 音轨 / 字幕 / 投屏（次要功能不占常驻栏）。
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({
    required this.controller,
    required this.style,
    required this.onStyleChanged,
    required this.onCast,
  });

  final MediaKitPlayerController controller;
  final SubtitleStyle style;
  final void Function(SubtitleStyle style) onStyleChanged;
  final VoidCallback onCast;

  static const rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];

  @override
  Widget build(BuildContext context) {
    final rate = controller.rate == 0 ? 1.0 : controller.rate;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final r in rates)
          ChoiceChip(
            label: Text('${r}x'),
            selected: (rate - r).abs() < 0.01,
            onSelected: (_) {
              controller.setRate(r);
              (context as Element).markNeedsBuild();
            },
          ),
        for (final t in controller.audioTracks())
          ActionChip(
            label: Text('音轨 ${t.title}'),
            onPressed: () => controller.selectAudioTrack(t),
          ),
        ActionChip(
          label: const Text('字幕'),
          onPressed: () {
            Navigator.of(context).pop();
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: StarColors.surface,
                title: const Text('字幕'),
                content: Text(
                  '字号 ${style.fontSize.toStringAsFixed(0)} · 延迟 ${style.delayMs}ms',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      onStyleChanged(SubtitleStyle(
                        fontSize: style.fontSize + 2,
                        backgroundOpacity: style.backgroundOpacity,
                        delayMs: style.delayMs,
                      ));
                      Navigator.of(context).pop();
                    },
                    child: const Text('字号 +'),
                  ),
                  TextButton(
                    onPressed: () {
                      onStyleChanged(SubtitleStyle(
                        fontSize: (style.fontSize - 2).clamp(12, 48),
                        backgroundOpacity: style.backgroundOpacity,
                        delayMs: style.delayMs,
                      ));
                      Navigator.of(context).pop();
                    },
                    child: const Text('字号 -'),
                  ),
                ],
              ),
            );
          },
        ),
        ActionChip(label: const Text('投屏'), onPressed: onCast),
      ],
    );
  }
}

class _DlnaControlDialog extends StatelessWidget {
  const _DlnaControlDialog({
    required this.device,
    required this.cast,
    required this.title,
  });

  final DlnaDevice device;
  final DlnaCastClient cast;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StarColors.surface,
      title: Text(device.name),
      content: Text(title),
      actions: [
        TextButton(
          onPressed: () => cast.pause(device),
          child: const Text('暂停'),
        ),
        TextButton(
          onPressed: () => cast.stop(device),
          child: const Text('停止'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}


/// 海报共享元素：入场后淡出，露出视频（morph 过渡）。
class _PosterMorph extends StatefulWidget {
  const _PosterMorph({required this.url});
  final String url;

  @override
  State<_PosterMorph> createState() => _PosterMorphState();
}

class _PosterMorphState extends State<_PosterMorph> {
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _opacity = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: StarNetworkImage(
        url: widget.url,
        fit: BoxFit.cover,
        fallback: const ColoredBox(color: Colors.black),
      ),
    );
  }
}
