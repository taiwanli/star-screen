import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk_video;
import 'package:star_domain/star_domain.dart' show PlayerEngineType;
import 'package:video_player/video_player.dart' as vp;

import 'exo_video_player_controller.dart';
import 'external_player_controller.dart';
import 'media_kit_controller.dart';
import '../star_player.dart' show PlayerController, PlayerEvent, SubtitleStyle;

/// 三内核统一门面：UI 只依赖本类，不再绑死 media_kit。
class PlayerFacade {
  PlayerFacade(this.controller, this.engine);

  final PlayerController controller;
  final PlayerEngineType engine;

  Stream<PlayerEvent> get events => controller.events;

  String get engineName => switch (engine) {
        PlayerEngineType.libmpv => 'libmpv',
        PlayerEngineType.exo => 'Exo',
        PlayerEngineType.system => '外部',
      };

  /// 当前播放状态（尽力而为；外部内核由心跳推进）。
  bool playing = false;
  int positionSec = 0;
  int durationSec = 0;
  double volume = 1.0;
  double rate = 1.0;

  Future<void> load(String url, {Map<String, String> headers = const {}, int startAtSec = 0}) =>
      controller.load(url, headers: headers, startAtSec: startAtSec);

  Future<void> play() async {
    playing = true;
    await controller.play();
  }

  Future<void> pause() async {
    playing = false;
    await controller.pause();
  }

  Future<void> seek(int sec) async {
    positionSec = sec;
    await controller.seek(sec);
  }

  void setVolume(double v) {
    volume = v.clamp(0, 1);
    final c = controller;
    if (c is MediaKitPlayerController) {
      c.player.setVolume(volume * 100);
    }
  }

  void setRate(double r) {
    rate = r;
    final c = controller;
    if (c is MediaKitPlayerController) {
      c.setRate(r);
    }
  }

  void setSubtitleStyle(SubtitleStyle style) {
    final c = controller;
    if (c is MediaKitPlayerController) {
      c.subtitleStyle = style;
    } else if (c is ExoVideoPlayerController) {
      c.subtitleStyle = style;
    }
  }

  SubtitleStyle get subtitleStyle {
    final c = controller;
    if (c is MediaKitPlayerController) return c.subtitleStyle;
    if (c is ExoVideoPlayerController) return c.subtitleStyle;
    return const SubtitleStyle();
  }

  /// 渲染视频面。
  Widget buildView() {
    final c = controller;
    if (c is MediaKitPlayerController) {
      return mk_video.Video(
        controller: mk_video.VideoController(c.player),
        subtitleViewConfiguration:
            const mk_video.SubtitleViewConfiguration(visible: false),
      );
    }
    if (c is ExoVideoPlayerController) {
      final v = c.video;
      if (v == null) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(
              child: CircularProgressIndicator(color: Colors.white54)),
        );
      }
      return vp.VideoPlayer(v);
    }
    if (c is ExternalPlayerController) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_new, color: Colors.white70, size: 48),
              const SizedBox(height: 12),
              Text(
                '已交给外部播放器播放',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 6),
              Text(
                '请在弹出的窗口中观看（mpv / VLC / PotPlayer）',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  /// 字幕流（仅 libmpv 有）。
  Stream<List<String>>? get subtitleStream {
    final c = controller;
    if (c is MediaKitPlayerController) return c.player.stream.subtitle;
    return null;
  }

  Future<void> dispose() => controller.dispose();
}
