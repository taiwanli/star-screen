import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class FakeHomeSource implements VideoSource {
  @override
  final SourceDef def;
  final bool ok;
  final int latencyMs;

  FakeHomeSource(String key, {required this.ok, this.latencyMs = 100})
      : def = SourceDef(key: key, name: key, kind: SourceKind.cmsJson);

  @override
  Future<HomeFeed> home() async {
    await Future<void>.delayed(Duration(milliseconds: latencyMs.clamp(0, 50)));
    if (!ok) throw StateError('down');
    return const HomeFeed(recommend: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('HealthMonitor —— 探活与评分（docs/05 §8）', () {
    test('正常源：excellent；失败源：dead', () async {
      final monitor = HealthMonitor(timeout: const Duration(seconds: 2));
      final good = await monitor.probe(FakeHomeSource('good', ok: true, latencyMs: 5));
      expect(good.level, HealthLevel.excellent);
      expect(good.successRate, 1.0);

      final bad = await monitor.probe(FakeHomeSource('bad', ok: false));
      expect(bad.level, HealthLevel.dead);
      expect(bad.successRate, 0.0);
    });

    test('滑动窗口：近 20 次统计', () async {
      final monitor = HealthMonitor();
      final source = FakeHomeSource('half', ok: true, latencyMs: 5);
      for (var i = 0; i < 10; i++) {
        await monitor.probe(source);
      }
      final failing = FakeHomeSource('half', ok: false);
      for (var i = 0; i < 10; i++) {
        await monitor.probe(failing);
      }
      final health = await monitor.probe(failing);
      // probe 自身也计入窗口：10 成功 + 11 次失败 → 窗口保留 20 条 = 9/20
      expect(health.successRate, closeTo(0.45, 0.01));
      expect(health.level, HealthLevel.degraded);
    });

    test('probeAll 批量并发', () async {
      final monitor = HealthMonitor();
      final map = await monitor.probeAll([
        FakeHomeSource('s1', ok: true, latencyMs: 5),
        FakeHomeSource('s2', ok: false),
      ]);
      expect(map['s1']!.level, HealthLevel.excellent);
      expect(map['s2']!.level, HealthLevel.dead);
    });

    test('score 在 0-100 且成功/低延迟者更高', () {
      final good = SourceHealth(latencyMs: 50, successRate: 1.0, lastCheck: DateTime.now());
      final bad = SourceHealth(latencyMs: 900, successRate: 0.2, lastCheck: DateTime.now());
      expect(HealthMonitor.score(good), greaterThan(HealthMonitor.score(bad)));
      expect(HealthMonitor.score(good), inInclusiveRange(0, 100));
      expect(HealthMonitor.score(bad), inInclusiveRange(0, 100));
    });
  });
}
