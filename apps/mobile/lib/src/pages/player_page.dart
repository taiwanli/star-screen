import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

/// 手机播放页：横屏全屏 + 最小控制层（docs/07 §4.4）。
/// 连播：[onPlayNext] 非空时播完弹 10s 倒计时（docs/09 M3-2）。
class PlayerPage extends StatefulWidget {
  final MediaKitPlayerController controller;
  final PlaybackSession session;
  final String title;
  final String? nextEpisodeTitle;
  final VoidCallback? onPlayNext;

  const PlayerPage({
    super.key,
    required this.controller,
    required this.session,
    required this.title,
    this.nextEpisodeTitle,
    this.onPlayNext,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final VideoController _video = VideoController(widget.controller.player);
  StreamSubscription<String>? _failureSub;
  StreamSubscription<PlayerEvent>? _eventSub;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _failureSub = widget.session.failures.listen((reason) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text(playErrorWithEngineHint(reason, engineName: widget.controller.engineName),
              style: const TextStyle(color: StarColors.bad)),
        ));
      }
    });
    _eventSub = widget.controller.events.listen((e) {
      if (e is PlayerCompleted && widget.onPlayNext != null && mounted) {
        setState(() => _completed = true);
      }
    });
  }

  @override
  void dispose() {
    _failureSub?.cancel();
    _eventSub?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // 退出播放：强制落盘最后进度（下次进入自动续播）
    widget.session.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.controller.subtitleStyle;
    return Scaffold(
      backgroundColor: Colors.black,
      body: PlayerScope(
        controller: widget.controller,
        child: Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: _video,
                subtitleViewConfiguration:
                    const SubtitleViewConfiguration(visible: false),
              ),
            ),
            Positioned.fill(
              child: StarSubtitleOverlay(
                textStream: widget.controller.player.stream.subtitle,
                style: SubtitleUiStyle(
                  fontSize: style.fontSize,
                  backgroundOpacity: style.backgroundOpacity,
                  delayMs: style.delayMs,
                ),
              ),
            ),
            _TopBar(title: widget.title),
            if (_completed && widget.onPlayNext != null)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 72),
                  child: NextEpisodeBanner(
                    title: '即将播放：${widget.nextEpisodeTitle ?? '下一集'}',
                    onPlayNext: () {
                      setState(() => _completed = false);
                      widget.onPlayNext!();
                    },
                    onCancel: () => setState(() => _completed = false),
                  ),
                ),
              ),
            _BottomControls(onStyleChanged: _onStyleChanged),
          ],
        ),
      ),
    );
  }

  void _onStyleChanged(SubtitleStyle style) {
    widget.controller.subtitleStyle = style;
    setState(() {});
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [StarColors.glass, Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            BackButton(
                color: StarColors.ink,
                onPressed: () => Navigator.of(context).pop()),
            Expanded(
              child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: StarColors.ink, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 控制层常驻（v0.1）；进度条两端内缩 ≥24dp、热区 ≥44dp（规范 6.4）。
class _BottomControls extends StatelessWidget {
  final void Function(SubtitleStyle style) onStyleChanged;
  const _BottomControls({required this.onStyleChanged});

  @override
  Widget build(BuildContext context) {
    final controller = PlayerScope.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [StarColors.glass, Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(40, 24, 40, 14),
        child: StreamBuilder<DomainPlayerEvent>(
          stream: controller.asDomain().events,
          builder: (context, snap) {
            final st = controller.player.state;
            final position = st.position.inSeconds;
            final duration = st.duration.inSeconds;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                  ),
                  child: Slider(
                    activeColor: StarColors.brandHi,
                    inactiveColor: const Color(0x38FFFFFF),
                    max: duration > 0 ? duration.toDouble() : 1,
                    value:
                        position.clamp(0, duration > 0 ? duration : 1).toDouble(),
                    onChanged: (v) => controller.seek(v.round()),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => controller.pause(),
                      icon: const Icon(Icons.pause_outlined, color: StarColors.ink),
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    Text(
                      '${_fmt(position)} / ${_fmt(duration)}',
                      style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 13,
                          color: StarColors.ink2),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '字幕',
                      onPressed: () => _openSubtitleSheet(context, controller, onStyleChanged),
                      icon: const Icon(Icons.subtitles_outlined,
                          color: StarColors.ink),
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    const Text('libmpv',
                        style: TextStyle(fontSize: 12, color: StarColors.ink4)),
                  ],
                ),
                PlayerExtrasBar(
                  rate: controller.rate == 0 ? 1.0 : controller.rate,
                  onRateChanged: (r) {
                    controller.setRate(r);
                    if (context.mounted) (context as Element).markNeedsBuild();
                  },
                  onQualityChanged: (_) {},
                  audioTracks: [
                    for (final t in controller.audioTracks())
                      TrackOption(id: t.id, title: t.title),
                  ],
                  audioTrackId: controller.currentAudioTrack()?.id,
                  onAudioChanged: (id) {
                    final t = controller
                        .audioTracks()
                        .where((e) => e.id == id)
                        .firstOrNull;
                    controller.selectAudioTrack(t);
                  },
                  onSkipIntro: () => controller.seek(position + 85),
                  onSkipOutro: duration > 0
                      ? () => controller.seek(duration - 30)
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmt(int sec) {
    String two(int v) => v.toString().padLeft(2, '0');
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${two(m)}:${two(s)}';
  }
}

void _openSubtitleSheet(
  BuildContext context,
  MediaKitPlayerController controller,
  void Function(SubtitleStyle style) onStyleChanged,
) {
  final tracks = controller.subtitleTracks();
  final current = controller.currentSubtitleTrack();
  final style = controller.subtitleStyle;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(12),
      child: SubtitlePanel(
        width: double.infinity,
        tracks: [
          for (final t in tracks)
            SubtitleTrackOption(
              id: t.id,
              title: t.title,
              isExternal: t.isExternal,
              selected: current?.id == t.id,
            ),
        ],
        style: SubtitleUiStyle(
          fontSize: style.fontSize,
          backgroundOpacity: style.backgroundOpacity,
          delayMs: style.delayMs,
        ),
        onSelectTrack: (id) {
          if (id == null) {
            controller.selectSubtitleTrack(null);
          } else {
            controller
                .selectSubtitleTrack(tracks.where((e) => e.id == id).firstOrNull);
          }
          Navigator.of(context).pop();
        },
        onStyleChanged: (s) => onStyleChanged(SubtitleStyle(
          fontSize: s.fontSize,
          backgroundOpacity: s.backgroundOpacity,
          delayMs: s.delayMs,
        )),
        onLoadExternal: (uri) => controller.loadExternalSubtitle(uri),
      ),
    ),
  );
}

/// 页面内取播放控制器的作用域（避免层层传参）。
class PlayerScope extends InheritedWidget {
  final MediaKitPlayerController controller;

  const PlayerScope({super.key, required this.controller, required super.child});

  static MediaKitPlayerController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerScope>()!.controller;

  @override
  bool updateShouldNotify(PlayerScope oldWidget) => false;
}
