import 'dart:async';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../player_events.dart';

/// 播放记录持久化接口 —— storage 包以 play_record 表实现；测试用内存实现。
abstract interface class PlayRecordStore {
  Future<PlayRecord?> get(String workKey);
  Future<void> save(PlayRecord record);

  /// 换源保进度：把 [fromKey] 的观看进度复制到 [toCard]。
  /// [maxEpisodeIndex] 钳制集数；[durationScale] 缩放时长（跨源片长不同）。
  /// 默认实现按 1:1 复制 position/duration/episode。
  Future<PlayRecord?> copyProgressTo({
    required String fromKey,
    required WorkCard toCard,
    int maxEpisodeIndex = 1 << 30,
    double durationScale = 1.0,
  }) async {
    final rec = await get(fromKey);
    if (rec == null) return null;
    final ep = rec.episodeIndex < 0
        ? 0
        : (rec.episodeIndex > maxEpisodeIndex ? maxEpisodeIndex : rec.episodeIndex);
    final dur = durationScale <= 0
        ? rec.durationSec
        : (rec.durationSec * durationScale).round();
    final pos = (dur > 0 && rec.positionSec > dur) ? dur - 1 : rec.positionSec;
    final out = PlayRecord(
      workKey: toCard.workKey,
      sourceKey: toCard.sourceKey,
      episodeIndex: ep,
      positionSec: pos < 0 ? 0 : pos,
      durationSec: dur > 0 ? dur : rec.durationSec,
      updatedAt: DateTime.now(),
      lineId: rec.lineId,
    );
    await save(out);
    return out;
  }
}

class InMemoryPlayRecordStore implements PlayRecordStore {
  final Map<String, PlayRecord> _byKey = {};

  @override
  Future<PlayRecord?> get(String workKey) async => _byKey[workKey];

  @override
  Future<void> save(PlayRecord record) async => _byKey[record.workKey] = record;

  @override
  Future<PlayRecord?> copyProgressTo({
    required String fromKey,
    required WorkCard toCard,
    int maxEpisodeIndex = 1 << 30,
    double durationScale = 1.0,
  }) async {
    final rec = _byKey[fromKey];
    if (rec == null) return null;
    final ep = rec.episodeIndex < 0
        ? 0
        : (rec.episodeIndex > maxEpisodeIndex
            ? maxEpisodeIndex
            : rec.episodeIndex);
    final dur = durationScale <= 0
        ? rec.durationSec
        : (rec.durationSec * durationScale).round();
    final pos = (dur > 0 && rec.positionSec > dur) ? dur - 1 : rec.positionSec;
    final out = PlayRecord(
      workKey: toCard.workKey,
      sourceKey: toCard.sourceKey,
      episodeIndex: ep,
      positionSec: pos < 0 ? 0 : pos,
      durationSec: dur > 0 ? dur : rec.durationSec,
      updatedAt: DateTime.now(),
      lineId: rec.lineId,
    );
    _byKey[out.workKey] = out;
    return out;
  }

  /// 测试辅助。
  Iterable<PlayRecord> get all => _byKey.values;
}

/// 起播结果。
sealed class PlayOutcome {
  const PlayOutcome();
}

/// 正常开播（可能为续播）。
class PlayOutcomePlaying extends PlayOutcome {
  final PlayCandidate candidate;
  final int startAtSec;

  /// true = 命中跨端/本地续播记录（规范 6.5：播了就续，不从头放）。
  final bool resumed;

  const PlayOutcomePlaying(this.candidate, {required this.startAtSec, required this.resumed});
}

/// 候选地址需要网页解析 —— 合规基线：默认拦截不播，交 UI 提示换线路。
class PlayOutcomeBlocked extends PlayOutcome {
  final PlayCandidate candidate;

  const PlayOutcomeBlocked(this.candidate);
}

/// 播放会话（docs/03 §4.3 起播时序；docs/09 M1-6）。
///
/// 职责：resolve 候选地址 → 自动续播 → 订阅播放事件 → **5 秒节流**写观看记录
/// （≥5% 才记录、≥90% 标记看完，docs/07 §4.5 锁死阈值）→ 暂停/退出强制落盘。
/// 内核回退链是 player_abstraction 的职责，不在本层。
class PlaybackSession {
  final VideoSource source;
  final DomainPlayerController player;
  final PlayRecordStore records;

  /// 内核回退链全部失败后触发（UI 提示换线路/换源）。
  Stream<String> get failures => _failures.stream;

  /// 当前候选播放地址（投屏/推片取真实 URL，docs/13 B1）。未起播为 null。
  PlayCandidate? get candidate => _candidate;

  final _failures = StreamController<String>.broadcast();
  StreamSubscription<DomainPlayerEvent>? _sub;

  PlayRequest? _request;
  PlayCandidate? _candidate;
  int _lastPositionSec = 0;
  int _lastDurationSec = 0;
  DateTime? _lastSaveAt;
  bool _disposed = false;

  PlaybackSession({
    required this.source,
    required this.player,
    required this.records,
  });

  /// 起播（或续播）。同一会话内换集/换线路可重复调用。
  Future<PlayOutcome> start(PlayRequest request) async {
    final candidate = await source.resolve(request);
    if (candidate.needsParse) {
      return PlayOutcomeBlocked(candidate);
    }

    final workKey = SourceDef.workKey(source.def.key, request.workId);
    final existing = await records.get(workKey);
    final resumeAt = existing != null &&
            existing.episodeIndex == request.episodeIndex &&
            !existing.isFinished
        ? existing.positionSec
        : 0;

    _request = request;
    _candidate = candidate;
    _lastPositionSec = resumeAt;
    _lastDurationSec = 0;
    _lastSaveAt = null;

    await player.load(
      candidate.url,
      headers: candidate.headers,
      startAtSec: resumeAt,
    );
    await player.play();

    _sub ??= player.events.listen(_onEvent);
    return PlayOutcomePlaying(
      candidate,
      startAtSec: resumeAt,
      resumed: resumeAt > 0,
    );
  }

  /// 换线路 / 换集（进度语义：换集按各自记录续播）。
  Future<PlayOutcome> switchTo(PlayRequest request) => start(request);

  void _onEvent(DomainPlayerEvent event) {
    switch (event) {
      case DomainPlayerPosition(:final positionSec, :final durationSec):
        _lastPositionSec = positionSec;
        _lastDurationSec = durationSec;
        // 5 秒节流写库（docs/03 §6）
        // 时间戳制节流：向前大 seek 后也能在 5s 内恢复写库（docs/13 A1）
        final last = _lastSaveAt;
        if (last == null ||
                DateTime.now().difference(last) >= const Duration(seconds: 5)) {
          _save(positionSec, durationSec);
        }
      case DomainPlayerCompleted():
        _save(_lastDurationSec, _lastDurationSec);
      case DomainPlayerFailed(:final reason):
        _failures.add(reason);
      case DomainPlayerBuffering():
        break;
    }
  }

  Future<void> _save(int positionSec, int durationSec) async {
    final request = _request;
    if (request == null || _disposed) return;
    _lastSaveAt = DateTime.now();
    final workKey = SourceDef.workKey(source.def.key, request.workId);
    final record = PlayRecord(
      workKey: workKey,
      sourceKey: source.def.key,
      episodeIndex: request.episodeIndex,
      positionSec: positionSec,
      durationSec: durationSec,
      updatedAt: DateTime.now(),
      lineId: request.lineId,
    );
    if (!record.shouldRecord) return; // <5% 不生成续播记录
    await records.save(record);
  }


  /// 退出播放：强制落盘最后进度并停止监听。
  Future<void> stop() async {
    if (_candidate != null &&
        _lastPositionSec != 0 &&
        _lastDurationSec > 0) {
      await _save(_lastPositionSec, _lastDurationSec);
    }
    _candidate = null;
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _failures.close();
  }
}
