/// 播放器抽象（docs/03 §1.2 / docs/07 §4.4）。
///
/// 上层 playback_session 依赖 [DomainPlayerController]（star_domain）；
/// 宿主依赖本包的 [PlayerController]，并负责桥接。
/// 内核实现：[MediaKitPlayerController]（libmpv，三端共用，v0.1）；
/// ExoPlayer/IJK 平台通道实现于 v0.2 接入回退链。
library;

export 'src/exo_video_player_controller.dart';
export 'src/external_player_controller.dart';
export 'src/media_kit_controller.dart';
export 'src/player_engine_factory.dart';
export 'src/player_facade.dart';

/// 播放内核（docs/03 §1.2）。
enum PlayerKernel { auto, exo, ijk, system, libmpv }

/// 端形态上下文 —— 由宿主注入，回退链据此取默认内核序。
enum PlayerHost { windows, androidPhone, androidTv }

/// 播放器事件流。
sealed class PlayerEvent {
  const PlayerEvent();
}

class PlayerBuffering extends PlayerEvent {
  final double progress; // 0-1
  const PlayerBuffering(this.progress);
}

class PlayerPosition extends PlayerEvent {
  final int positionSec;
  final int durationSec;
  const PlayerPosition(this.positionSec, this.durationSec);
}

class PlayerCompleted extends PlayerEvent {
  const PlayerCompleted();
}

class PlayerFailed extends PlayerEvent {
  final String reason;
  const PlayerFailed(this.reason);
}

/// 统一播放器契约。实现必须：
/// 1. 每秒至少回调一次 [PlayerPosition]（断点续播 5 秒节流写库的依据）；
/// 2. 轨道能力（清晰度/字幕/音轨）由实现暴露，契约层 v0.1 先覆盖播放主链路。
abstract interface class PlayerController {
  Stream<PlayerEvent> get events;

  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(int positionSec);
  Future<void> dispose();
}

/// 失败回退链（docs/03 §1.2 / docs/05 决策）：起播失败依次降级，
/// 全部失败后由上层提示「换线路 / 换源」—— 绝不静默黑屏。
/// docs/13 B4：v0.1 三端统一 libmpv，本类为契约占位，执行方
/// 计划在 v0.2 接入多内核通道（ExoPlayer 等）时调用。
class FallbackChain {
  final PlayerHost host;

  const FallbackChain(this.host);

  /// 默认内核序。
  List<PlayerKernel> defaults() => switch (host) {
        PlayerHost.windows => [PlayerKernel.libmpv],
        PlayerHost.androidPhone ||
        PlayerHost.androidTv => [PlayerKernel.exo, PlayerKernel.ijk, PlayerKernel.system],
      };

  /// 起播失败后的下一档：硬解 → 软解 → 换内核 → null（交还上层）。
  PlayerKernel? nextAfter(PlayerKernel current) => switch (current) {
        PlayerKernel.exo => PlayerKernel.ijk,
        PlayerKernel.ijk => PlayerKernel.system,
        PlayerKernel.system => host == PlayerHost.windows ? PlayerKernel.libmpv : null,
        PlayerKernel.libmpv => null,
        PlayerKernel.auto => defaults().first,
      };
}

/// 字幕轨描述（内封轨来自容器；外挂轨为 srt/ass/ssa/vtt URI，docs/09 M3-3）。
class PlayerSubtitleTrack {
  final String id;
  final String title;
  final bool isExternal;

  const PlayerSubtitleTrack({
    required this.id,
    required this.title,
    this.isExternal = false,
  });
}

/// 音轨描述（docs/02 §4.3 音轨切换）。
class PlayerAudioTrack {
  final String id;
  final String title;

  const PlayerAudioTrack({required this.id, required this.title});
}

/// 字幕样式（docs/02 P1：大小/颜色（底板透明度）/延迟）。
/// TV 默认字号 ≥32（docs/07 §4.4），由端上按形态注入。
class SubtitleStyle {
  final double fontSize;
  final double backgroundOpacity; // 0–1，0.67 ≈ aa000000
  final int delayMs; // 正值 = 字幕延后出现

  const SubtitleStyle({
    this.fontSize = 24,
    this.backgroundOpacity = 0.67,
    this.delayMs = 0,
  });

  SubtitleStyle copyWith({
    double? fontSize,
    double? backgroundOpacity,
    int? delayMs,
  }) =>
      SubtitleStyle(
        fontSize: fontSize ?? this.fontSize,
        backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
        delayMs: delayMs ?? this.delayMs,
      );

  /// TV 形态默认（≥32px + 半透明背景板，docs/07 §4.4）。
  static const tv = SubtitleStyle(fontSize: 32, backgroundOpacity: 0.72);
}

/// 外挂字幕 URI 归一：http(s)/file 原样；本地绝对路径转 file://。
String normalizeSubtitleUri(String raw) {
  final s = raw.trim();
  if (s.startsWith('http://') ||
      s.startsWith('https://') ||
      s.startsWith('file://')) {
    return s;
  }
  return Uri.file(s).toString();
}

/// 字幕显示名（取路径末段）。
String subtitleTitleFromUri(String uri) {
  final seg = uri.split(RegExp(r'[/\\]')).last;
  return seg.isEmpty ? '外挂字幕' : seg;
}
