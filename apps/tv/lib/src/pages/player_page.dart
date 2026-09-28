import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

/// TV 播放页：OSD（docs/07 §4.4）。
/// 连播 10s 倒计时可取消；返回键两级语义（先收 OSD 再退出，docs/09 M3-2）。
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
  bool _osdVisible = true;

  @override
  void initState() {
    super.initState();
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
    // 退出播放：强制落盘最后进度（docs/05 M1-6）
    widget.session.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.browserBack) {
      // F7 返回两级语义：有 OSD/倒计时先收起，再退出
      if (_completed) {
        setState(() => _completed = false);
        return KeyEventResult.handled;
      }
      if (_osdVisible) {
        setState(() => _osdVisible = false);
        return KeyEventResult.handled;
      }
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
      setState(() => _osdVisible = !_osdVisible);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.controller.subtitleStyle;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
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
            if (_completed && widget.onPlayNext != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 180),
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
            // 顶部标题（OSD 显隐时保留）
            Positioned(
              left: 48,
              right: 48,
              top: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 28, color: StarColors.ink)),
                  ),
                  IconButton(
                    tooltip: '字幕',
                    icon: const Icon(Icons.subtitles_outlined,
                        color: StarColors.ink, size: 36),
                    onPressed: () => _openSubtitlePanel(context),
                  ),
                ],
              ),
            ),
            // OSD（底部，F7 可收起）
            if (_osdVisible)
              Positioned(
                left: 96,
                right: 96,
                bottom: 48,
                child: StreamBuilder<DomainPlayerEvent>(
              stream: widget.controller.asDomain().events,
              builder: (context, snap) {
                final st = widget.controller.player.state;
                final position = st.position.inSeconds;
                final duration = st.duration.inSeconds;
                final remaining =
                    duration > position ? _fmt(duration - position) : '--:--';
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: StarColors.glassStrong,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 进度条（默认焦点，←→ 连续调整）
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 12,
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 12),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 18),
                        ),
                        child: Slider(
                          autofocus: true,
                          activeColor: StarColors.brandHi,
                          inactiveColor: const Color(0x38FFFFFF),
                          max: duration > 0 ? duration.toDouble() : 1,
                          value: position
                              .clamp(0, duration > 0 ? duration : 1)
                              .toDouble(),
                          onChanged: (v) => widget.controller.seek(v.round()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_fmt(position)} / ${_fmt(duration)}   ·   剩余 $remaining',
                        style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 24,
                            color: StarColors.ink2),
                      ),
                      const SizedBox(height: 12),
                      PlayerExtrasBar(
                        rate: widget.controller.rate == 0
                            ? 1.0
                            : widget.controller.rate,
                        onRateChanged: (r) {
                          widget.controller.setRate(r);
                          setState(() {});
                        },
                        onQualityChanged: (_) {},
                        audioTracks: [
                          for (final t in widget.controller.audioTracks())
                            TrackOption(id: t.id, title: t.title),
                        ],
                        audioTrackId:
                            widget.controller.currentAudioTrack()?.id,
                        onAudioChanged: (id) {
                          final t = widget.controller
                              .audioTracks()
                              .where((e) => e.id == id)
                              .firstOrNull;
                          widget.controller.selectAudioTrack(t);
                        },
                        onSkipIntro: () =>
                            widget.controller.seek(position + 85),
                        onSkipOutro: duration > 0
                            ? () => widget.controller.seek(duration - 30)
                            : null,
                      ),
                    ],
                  ),
                );
              },
              ),
            ),
          // 退出按钮（返回键亦可）
          Positioned(
            right: 48,
            top: 40,
            child: IconButton(
              icon: const Icon(Icons.close, color: StarColors.ink, size: 36),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _openSubtitlePanel(BuildContext context) {
    final controller = widget.controller;
    final tracks = controller.subtitleTracks();
    final current = controller.currentSubtitleTrack();
    final style = controller.subtitleStyle;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: SubtitlePanel(
          width: 420,
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
            fontSize: style.fontSize < 32 ? 32 : style.fontSize,
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
          onStyleChanged: (s) {
            controller.subtitleStyle = SubtitleStyle(
              fontSize: s.fontSize,
              backgroundOpacity: s.backgroundOpacity,
              delayMs: s.delayMs,
            );
            if (mounted) setState(() {});
          },
          onLoadExternal: (uri) => controller.loadExternalSubtitle(uri),
        ),
      ),
    );
  }

  String _fmt(int sec) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}
