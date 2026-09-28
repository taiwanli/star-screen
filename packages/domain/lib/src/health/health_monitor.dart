import 'dart:async';
import 'dart:collection';
import 'dart:math';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../util/semaphore.dart';

/// 源健康度探活 v1（docs/09 M2-3；评分模型 docs/05 §8；阶梯熔断 docs/18 §5）。
///
/// L2 站点探活：调用源首页/列表端点，记录延迟与成功与否；
/// 滑动窗口（近 20 次）计算成功率；score = 0.5×成功率 + 0.3×延迟分 + 0.2×新鲜度。
/// 连续失败触发阶梯熔断（30min → 24h），可一键恢复。
class HealthMonitor {
  final Duration timeout;
  final int windowSize;

  final _windows = <String, Queue<bool>>{};
  final _latencies = <String, List<int>>{};
  final _lastCheck = <String, DateTime>{};
  final _failStreak = <String, int>{};
  final _coolUntil = <String, DateTime>{};
  final _lastFailReason = <String, String>{};

  HealthMonitor({this.timeout = const Duration(seconds: 8), this.windowSize = 20});

  /// 探活单源（首页调用即 L2 抽样）。
  Future<SourceHealth> probe(VideoSource source) async {
    final sw = Stopwatch()..start();
    var ok = false;
    String? reason;
    try {
      await source.home().timeout(timeout);
      ok = true;
    } on TimeoutException {
      reason = '检测超时（${timeout.inSeconds}s）';
    } on Object catch (e) {
      reason = e.toString();
    }
    final latency = ok ? sw.elapsedMilliseconds : null;
    _record(source.def.key, ok, latency, failReason: reason);
    return healthOf(source.def.key);
  }

  /// 批量探活（并发 6），返回 sourceKey → 健康度。
  Future<Map<String, SourceHealth>> probeAll(List<VideoSource> sources) async {
    final semaphore = Semaphore(6);
    final out = <String, SourceHealth>{};
    await Future.wait([
      for (final s in sources)
        () async {
          await semaphore.acquire();
          try {
            out[s.def.key] = await probe(s);
          } on Object {
            out[s.def.key] = healthOf(s.def.key);
          } finally {
            semaphore.release();
          }
        }(),
    ]);
    return out;
  }

  void _record(String key, bool ok, int? latency, {String? failReason}) {
    final window = _windows.putIfAbsent(key, Queue<bool>.new);
    window.addLast(ok);
    while (window.length > windowSize) {
      window.removeFirst();
    }
    if (ok && latency != null) {
      _latencies.putIfAbsent(key, () => []).add(latency);
      final list = _latencies[key]!;
      if (list.length > windowSize) list.removeAt(0);
    }
    _lastCheck[key] = DateTime.now();
    if (ok) {
      _failStreak[key] = 0;
      _coolUntil.remove(key);
      _lastFailReason.remove(key);
    } else {
      final streak = (_failStreak[key] ?? 0) + 1;
      _failStreak[key] = streak;
      if (failReason != null) _lastFailReason[key] = failReason;
      // 阶梯熔断（docs/18 §5）：5 次→30min；再累到 10 次→24h
      final now = DateTime.now();
      if (streak >= 10) {
        _coolUntil[key] = now.add(const Duration(hours: 24));
      } else if (streak >= 5) {
        _coolUntil[key] = now.add(const Duration(minutes: 30));
      }
    }
  }

  /// 是否处于熔断冷却期（聚合搜索应跳过）。
  bool isCooling(String key, {DateTime? now}) {
    final until = _coolUntil[key];
    if (until == null) return false;
    return (now ?? DateTime.now()).isBefore(until);
  }

  /// 连续失败次数。
  int failStreak(String key) => _failStreak[key] ?? 0;

  /// 最近失败原因（展示用）。
  String? lastFailReason(String key) => _lastFailReason[key];

  /// 熔断截止时间。
  DateTime? coolUntil(String key) => _coolUntil[key];

  /// 一键恢复：清空失败计数/熔断，立即可重新探活。
  void recover(String key) {
    _failStreak.remove(key);
    _coolUntil.remove(key);
    _lastFailReason.remove(key);
    _windows[key]?.clear();
  }

  /// 批量恢复（源页一键恢复）。
  void recoverAll(Iterable<String> keys) {
    for (final k in keys) {
      recover(k);
    }
  }

  SourceHealth healthOf(String key) {
    final window = _windows[key];
    if (window == null || window.isEmpty) {
      return const SourceHealth();
    }
    final okCount = window.where((e) => e).length;
    final successRate = okCount / window.length;
    final latencies = _latencies[key];
    final avg = latencies == null || latencies.isEmpty
        ? null
        : (latencies.reduce((a, b) => a + b) / latencies.length).round();
    return SourceHealth(
      latencyMs: avg,
      successRate: successRate,
      lastCheck: _lastCheck[key],
    );
  }

  /// 综合分（0-100）：0.5×成功率 + 0.3×延迟分 + 0.2×新鲜度（docs/05 §8）。
  static double score(SourceHealth health, {DateTime? now}) {
    final nowAt = now ?? DateTime.now();
    final latencyScore = health.latencyMs == null
        ? 0.5
        : 1 - min(health.latencyMs!, 1000) / 1000;
    final age = health.lastCheck == null
        ? const Duration(days: 99)
        : nowAt.difference(health.lastCheck!);
    final freshness = age <= const Duration(minutes: 30)
        ? 1.0
        : max(0.0, 1 - age.inMinutes / (24 * 60));
    return ((health.successRate * 0.5 +
                latencyScore * 0.3 +
                freshness * 0.2) *
            100)
        .clamp(0.0, 100.0);
  }

  /// 按健康分降序排序（聚合搜索/推荐用）。
  List<SourceDef> rank(List<SourceDef> defs, {DateTime? now}) {
    final list = [...defs];
    list.sort((a, b) {
      final sa = score(healthOf(a.key), now: now);
      final sb = score(healthOf(b.key), now: now);
      return sb.compareTo(sa);
    });
    return list;
  }

  /// 是否应自动降权/置灰（近窗成功率过低）。
  bool isDegraded(String key, {double threshold = 0.25}) {
    final h = healthOf(key);
    return h.lastCheck != null && h.successRate < threshold;
  }

  /// 导出窗口状态（KV 落库，重启后保留健康分）。
  Map<String, Object?> exportState() => {
        for (final e in _windows.entries)
          e.key: {
            'window': e.value.toList(),
            'latencies': _latencies[e.key] ?? const <int>[],
            'last': _lastCheck[e.key]?.toIso8601String(),
            if (_failStreak[e.key] != null) 'failStreak': _failStreak[e.key],
            if (_coolUntil[e.key] != null)
              'coolUntil': _coolUntil[e.key]!.toIso8601String(),
            if (_lastFailReason[e.key] != null)
              'lastFailReason': _lastFailReason[e.key],
          },
      };

  void importState(Map<String, dynamic> raw) {
    _windows.clear();
    _latencies.clear();
    _lastCheck.clear();
    _failStreak.clear();
    _coolUntil.clear();
    _lastFailReason.clear();
    for (final e in raw.entries) {
      final m = e.value;
      if (m is! Map) continue;
      final w = m['window'];
      if (w is List) {
        _windows[e.key] = Queue<bool>.from(w.map((x) => x == true));
      }
      final lat = m['latencies'];
      if (lat is List) {
        _latencies[e.key] = [
          for (final x in lat) if (x is num) x.toInt(),
        ];
      }
      final last = m['last'];
      if (last is String) {
        _lastCheck[e.key] = DateTime.tryParse(last) ?? DateTime.now();
      }
      final streak = m['failStreak'];
      if (streak is num) _failStreak[e.key] = streak.toInt();
      final cool = m['coolUntil'];
      if (cool is String) {
        _coolUntil[e.key] = DateTime.tryParse(cool) ?? DateTime.now();
      }
      final reason = m['lastFailReason'];
      if (reason is String) _lastFailReason[e.key] = reason;
    }
  }
}
