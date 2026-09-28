import 'dart:async';

import 'package:star_domain/star_domain.dart' hide SubtitleTrack;
import 'package:video_player/video_player.dart' as vp;

import '../star_player.dart';

/// ExoPlayer / video_player 内核（Android 主用；桌面第二通道）。
///
/// 与 libmpv 差异：Flutter `video_player` → Android ExoPlayer，
/// 对部分 HLS/DASH/特殊封装更宽容；加载失败由回退链换内核。
class ExoVideoPlayerController implements PlayerController {
  ExoVideoPlayerController({this.subtitleStyle = const SubtitleStyle()});

  SubtitleStyle subtitleStyle;

  final _events = StreamController<PlayerEvent>.broadcast();
  vp.VideoPlayerController? _c;
  Timer? _tick;
  int _lastPos = 0;
  int _lastDur = 0;

  String get engineName => 'exo';

  /// 供 UI 用 `VideoPlayer(controller)` 渲染。
  vp.VideoPlayerController? get video => _c;

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  }) async {
    await disposePlayer();
    _events.add(const PlayerBuffering(1));
    try {
      final c = vp.VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers,
        formatHint: _hintFor(url),
      );
      _c = c;
      await c.initialize();
      if (startAtSec > 0) {
        await c.seekTo(Duration(seconds: startAtSec));
      }
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        final v = _c;
        if (v == null) return;
        final pos = v.value.position.inSeconds;
        final dur = v.value.duration.inSeconds;
        _lastPos = pos;
        _lastDur = dur;
        _events.add(PlayerPosition(pos, dur));
        if (v.value.isCompleted) {
          _events.add(const PlayerCompleted());
        }
      });
      _events.add(const PlayerBuffering(0));
      await c.play();
    } on Object catch (e) {
      _events.add(PlayerFailed('Exo 内核加载失败：$e'));
      rethrow;
    }
  }

  vp.VideoFormat? _hintFor(String url) {
    final u = url.toLowerCase();
    if (u.contains('.m3u8') || u.contains('m3u8')) return vp.VideoFormat.hls;
    if (u.contains('.mpd')) return vp.VideoFormat.dash;
    return null;
  }

  @override
  Future<void> play() async => _c?.play();

  @override
  Future<void> pause() async => _c?.pause();

  @override
  Future<void> seek(int positionSec) async {
    await _c?.seekTo(Duration(seconds: positionSec));
    _lastPos = positionSec;
    _events.add(PlayerPosition(positionSec, _lastDur));
  }

  /// 释放播放器但不关事件流（load 时复用）。
  Future<void> disposePlayer() async {
    _tick?.cancel();
    _tick = null;
    await _c?.dispose();
    _c = null;
  }

  @override
  Future<void> dispose() async {
    await disposePlayer();
    await _events.close();
  }

  DomainPlayerController asDomain() => _DomainAdapter(this);
}

class _DomainAdapter implements DomainPlayerController {
  final ExoVideoPlayerController _c;
  _DomainAdapter(this._c);

  @override
  Stream<DomainPlayerEvent> get events => _c.events.map(_map);

  static DomainPlayerEvent _map(PlayerEvent e) => switch (e) {
        PlayerPosition(:final positionSec, :final durationSec) =>
          DomainPlayerPosition(positionSec, durationSec),
        PlayerBuffering(:final progress) => DomainPlayerBuffering(progress),
        PlayerCompleted() => const DomainPlayerCompleted(),
        PlayerFailed(:final reason) => DomainPlayerFailed(reason),
      };

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  }) =>
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
