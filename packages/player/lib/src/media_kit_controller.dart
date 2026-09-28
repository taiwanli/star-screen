import 'dart:async';
import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:star_domain/star_domain.dart' hide SubtitleTrack;

import '../star_player.dart';

/// libmpv 内核实现（media_kit 封装），三端共用（docs/09 M1-5 决策：
/// v0.1 统一 libmpv 以最快闭环；ExoPlayer 平台通道于 v0.2 接入后，
/// 回退链将变为 exo 默认 → libmpv 兜底）。
///
/// 实现宿主契约（[PlayerController]）；[asDomain] 提供领域侧适配
/// （[DomainPlayerController]，供 playback_session 直接使用）。
/// Windows 需要 media_kit_libs_windows_video，Android/TV 需要
/// media_kit_libs_android_video（由各端 app 声明原生库依赖）。
class MediaKitPlayerController implements PlayerController {
  final Player player = Player();

  final _events = StreamController<PlayerEvent>.broadcast();
  late final List<StreamSubscription<dynamic>> _subs;

  /// 桥接为领域契约（playback_session 使用）。
  DomainPlayerController asDomain() => _DomainAdapter(this);

  /// 已加载的外挂字幕（srt/ass/ssa/vtt；URL 或本地 file://）。
  final List<SubtitleTrack> _externalTracks = [];

  /// 字幕样式（字号 / 底板透明度 / 延迟）——由 UI 面板写入，渲染层读取。
  SubtitleStyle subtitleStyle;

  MediaKitPlayerController({this.subtitleStyle = const SubtitleStyle()}) {
    _subs = [
      player.stream.position.listen((d) {
        _events.add(PlayerPosition(d.inSeconds, player.state.duration.inSeconds));
      }),
      player.stream.buffering.listen((buffering) {
        // media_kit 1.2.x 的 buffering 为 bool（是否缓冲中）
        _events.add(PlayerBuffering(buffering ? 1.0 : 0.0));
      }),
      player.stream.completed.listen((completed) {
        if (completed) _events.add(const PlayerCompleted());
      }),
      player.stream.error.listen((message) {
        if (message.isNotEmpty) _events.add(PlayerFailed(message));
      }),
    ];
  }

  @override
  Stream<PlayerEvent> get events => _events.stream;

  /// 内封字幕轨列表（docs/09 M3-3）。
  List<PlayerSubtitleTrack> subtitleTracks() => [
        for (final t in player.state.tracks.subtitle)
          PlayerSubtitleTrack(
              id: t.id,
              title: (t.title == null || t.title!.isEmpty) ? t.id : t.title!),
        for (final t in _externalTracks)
          PlayerSubtitleTrack(
              id: t.id, title: t.title ?? t.id, isExternal: true),
      ];

  /// 当前选中字幕轨（关闭时返回 null）。
  PlayerSubtitleTrack? currentSubtitleTrack() {
    final current = player.state.track.subtitle;
    if (current.id == SubtitleTrack.no().id) return null;
    return PlayerSubtitleTrack(
        id: current.id,
        title: current.title ?? current.id,
        isExternal: current.uri || current.data);
  }

  /// 选择字幕轨（null = 关闭字幕）。
  Future<void> selectSubtitleTrack(PlayerSubtitleTrack? track) async {
    if (track == null) {
      await player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    final external = _externalTracks.where((t) => t.id == track.id).firstOrNull;
    if (external != null) {
      await player.setSubtitleTrack(external);
      return;
    }
    final match = player.state.tracks.subtitle
        .where((t) => t.id == track.id)
        .firstOrNull;
    await player.setSubtitleTrack(
        match ?? SubtitleTrack(track.id, track.title, ''));
  }

  // ---------------- 倍速 / 音轨 / 清晰度偏好 ----------------

  /// 当前内核名（用于错误提示）。
  String get engineName => 'libmpv';

  /// 倍速（0.5–4.0，docs/02 §4.3）。
  Future<void> setRate(double rate) =>
      player.setRate(rate.clamp(0.25, 4.0));

  double get rate => player.state.rate;

  /// 音轨列表（内封）。
  List<PlayerAudioTrack> audioTracks() => [
        for (final t in player.state.tracks.audio)
          PlayerAudioTrack(
            id: t.id,
            title: (t.title == null || t.title!.isEmpty) ? t.id : t.title!,
          ),
      ];

  PlayerAudioTrack? currentAudioTrack() {
    final current = player.state.track.audio;
    if (current.id == AudioTrack.no().id || current.id == AudioTrack.auto().id) {
      return null;
    }
    return PlayerAudioTrack(id: current.id, title: current.title ?? current.id);
  }

  Future<void> selectAudioTrack(PlayerAudioTrack? track) async {
    if (track == null) {
      await player.setAudioTrack(AudioTrack.auto());
      return;
    }
    final match = player.state.tracks.audio
        .where((t) => t.id == track.id)
        .firstOrNull;
    await player.setAudioTrack(match ?? AudioTrack(track.id, track.title, ''));
  }

  /// 加载外挂字幕（http(s):// 或 file:// / 绝对路径）。
  /// 同名重复加载按 id 幂等；成功后自动选中该轨。
  Future<void> loadExternalSubtitle(String uri, {String? title}) async {
    final cleaned = uri.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('字幕地址为空');
    }
    final normalized = normalizeSubtitleUri(cleaned);
    final id = 'ext:$normalized';
    final existing = _externalTracks.where((t) => t.id == id).firstOrNull;
    if (existing != null) {
      await player.setSubtitleTrack(existing);
      return;
    }
    final track = SubtitleTrack.uri(
      normalized,
      title: title ?? subtitleTitleFromUri(normalized),
    );
    _externalTracks.add(track);
    await player.setSubtitleTrack(track);
  }

  static DomainPlayerEvent _toDomainEvent(PlayerEvent event) => switch (event) {
        PlayerBuffering(:final progress) => DomainPlayerBuffering(progress),
        PlayerPosition(:final positionSec, :final durationSec) =>
          DomainPlayerPosition(positionSec, durationSec),
        PlayerCompleted() => const DomainPlayerCompleted(),
        PlayerFailed(:final reason) => DomainPlayerFailed(reason),
      };

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  }) async {
    await player.open(Media(url, httpHeaders: headers), play: false);
    if (startAtSec > 0) {
      await player.seek(Duration(seconds: startAtSec));
    }
    // 本地文件同名外挂字幕自动匹配（docs/02 §4.3 P1）
    final sidecar = _sidecarFor(url);
    if (sidecar != null) {
      try {
        await loadExternalSubtitle(sidecar);
      } on Object {
        // 无同名字幕或加载失败：忽略
      }
    }
  }

  static String? _sidecarFor(String videoUrl) {
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      return null;
    }
    var path = videoUrl;
    if (path.startsWith('file://')) {
      try {
        path = Uri.parse(path).toFilePath();
      } on Object {
        return null;
      }
    }
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    if (dot <= slash) return null;
    final stem = path.substring(0, dot);
    for (final e in const ['.srt', '.ass', '.ssa', '.vtt']) {
      final f = File('$stem$e');
      if (f.existsSync()) return f.path;
    }
    return null;
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(int positionSec) => player.seek(Duration(seconds: positionSec));

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _events.close();
    await player.dispose();
  }
}

/// 领域侧适配器：把宿主事件流映射为 [DomainPlayerEvent]。
class _DomainAdapter implements DomainPlayerController {
  final MediaKitPlayerController _c;

  _DomainAdapter(this._c);

  @override
  Stream<DomainPlayerEvent> get events =>
      _c.events.map(MediaKitPlayerController._toDomainEvent);

  @override
  Future<void> load(String url,
          {Map<String, String> headers = const {}, int startAtSec = 0}) =>
      _c.load(url, headers: headers, startAtSec: startAtSec);

  @override
  Future<void> play() => _c.play();

  @override
  Future<void> pause() => _c.pause();

  @override
  Future<void> seek(int positionSec) => _c.seek(positionSec);

  @override
  Future<void> dispose() => _c.dispose();
}
