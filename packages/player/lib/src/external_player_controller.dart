import 'dart:async';
import 'dart:io';

import 'package:star_domain/star_domain.dart' as domain;

import '../star_player.dart';

/// 外部播放器内核（system）：把播放地址交给本机 mpv / VLC / PotPlayer / 系统默认。
///
/// 适用：libmpv 无法解的冷门封装、DRM/特殊协议、用户本机装了更强解码器。
/// 实现说明：外部进程无法回调精确 position —— 每秒上报 0 进度心跳，
/// 以满足「每秒至少一次 PlayerPosition」契约；进度条由外部窗口接管。
class ExternalPlayerController implements PlayerController {
  ExternalPlayerController({
    this.preferredExe,
    this.onLaunched,
    this.onExit,
  });

  /// 指定可执行文件；空则按平台探测 mpv → vlc → potplayer → 系统默认。
  final String? preferredExe;
  final void Function(int pid)? onLaunched;
  final void Function(int exitCode)? onExit;

  final _events = StreamController<PlayerEvent>.broadcast();
  Process? _proc;
  Timer? _heartbeat;
  int _pos = 0;
  int _dur = 0;
  bool _playing = false;
  String? _url;

  @override
  Stream<PlayerEvent> get events => _events.stream;

  String get engineName => 'external';

  /// 探测本机可用外部播放器。
  static List<String> detectCandidates() {
    if (Platform.isWindows) {
      const names = [
        'mpv.exe',
        'vlc.exe',
        'PotPlayerMini64.exe',
        'PotPlayerMini.exe',
        'wmplayer.exe',
      ];
      final found = <String>[];
      for (final n in names) {
        for (final dir in [
          r'C:\Program Files\VideoLAN\VLC',
          r'C:\Program Files\mpv',
          r'C:\Program Files (x86)\VideoLAN\VLC',
          r'C:\Program Files\DAUM\PotPlayer',
          r'C:\Program Files\PotPlayer',
        ]) {
          final p = '$dir${Platform.pathSeparator}$n';
          if (File(p).existsSync()) found.add(p);
        }
        // PATH
        found.add(n);
      }
      return found;
    }
    if (Platform.isMacOS) {
      return ['/Applications/VLC.app/Contents/MacOS/VLC', '/opt/homebrew/bin/mpv'];
    }
    return ['mpv', 'vlc', 'xdg-open'];
  }

  Future<void> _launch(String url) async {
    await _proc?.kill();
    final exe = preferredExe ?? detectCandidates().first;
    final args = _argsFor(exe, url);
    try {
      _proc = await Process.start(exe, args);
      _playing = true;
      onLaunched?.call(_proc!.pid);
      _proc!.exitCode.then((code) {
        _playing = false;
        _heartbeat?.cancel();
        _events.add(const PlayerCompleted());
        onExit?.call(code);
      });
      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
        // 外部进程无回调：保活事件流（断点续播节流依赖）
        if (_playing) {
          _pos += 1;
          _events.add(PlayerPosition(_pos, _dur));
        }
      });
    } on Object catch (e) {
      _events.add(PlayerFailed('外部播放器启动失败：$e'));
    }
  }

  List<String> _argsFor(String exe, String url) {
    final lower = exe.toLowerCase();
    if (lower.contains('potplayer')) return [url];
    if (lower.contains('vlc') || lower.contains('vlcv')) {
      return ['--play-and-exit', url];
    }
    // mpv / 默认
    if (lower.contains('mpv') || lower.endsWith('wmplayer.exe')) {
      return ['--force-window=yes', url];
    }
    return [url];
  }

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  }) async {
    _url = url;
    _pos = startAtSec;
    _events.add(PlayerBuffering(1));
    await _launch(url);
    _events.add(PlayerBuffering(0));
  }

  @override
  Future<void> play() async {
    if (_url != null && _proc == null) await _launch(_url!);
    _playing = true;
  }

  @override
  Future<void> pause() async {
    _playing = false;
    // 外部播放器暂停由用户在外部窗口操作
  }

  @override
  Future<void> seek(int positionSec) async {
    _pos = positionSec;
    _events.add(PlayerPosition(_pos, _dur));
  }

  @override
  Future<void> dispose() async {
    _heartbeat?.cancel();
    await _proc?.kill();
    _proc = null;
    await _events.close();
  }

  /// 能力：无内嵌字幕/音轨选择（外部窗口内完成）。
  List<PlayerSubtitleTrack> subtitleTracks() => const [];
  List<PlayerAudioTrack> audioTracks() => const [];

  domain.DomainPlayerController asDomain() => _ExternalDomainAdapter(this);
}

class _ExternalDomainAdapter implements domain.DomainPlayerController {
  final ExternalPlayerController _c;
  _ExternalDomainAdapter(this._c);

  @override
  Stream<domain.DomainPlayerEvent> get events => _c.events.map((e) {
        return switch (e) {
          PlayerPosition(:final positionSec, :final durationSec) =>
            domain.DomainPlayerPosition(positionSec, durationSec),
          PlayerBuffering(:final progress) => domain.DomainPlayerBuffering(progress),
          PlayerCompleted() => const domain.DomainPlayerCompleted(),
          PlayerFailed(:final reason) => domain.DomainPlayerFailed(reason),
        };
      });

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

/// 音频轨描述（外部内核占位用）。
class PlayerAudioTrack {
  final String id;
  final String title;
  const PlayerAudioTrack({required this.id, required this.title});
}
