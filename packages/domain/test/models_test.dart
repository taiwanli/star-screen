import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PlayRecord 进度阈值（docs/07 §4.5 锁死语义）', () {
    PlayRecord record(int pos, int dur) => PlayRecord(
          workKey: 'src::1',
          sourceKey: 'src',
          episodeIndex: 1,
          positionSec: pos,
          durationSec: dur,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
        );

    test('≥90% 视为已看完，移出继续观看', () {
      expect(record(90, 100).isFinished, isTrue);
      expect(record(89, 100).isFinished, isFalse);
    });

    test('<5% 不生成续播记录（误点不污染轨道）', () {
      expect(record(4, 100).shouldRecord, isFalse);
      expect(record(5, 100).shouldRecord, isTrue);
    });

    test('进度夹取在 0-1，零时长安全', () {
      expect(record(150, 100).progress, 1.0);
      expect(record(-5, 100).progress, 0.0);
      expect(record(10, 0).progress, 0.0);
    });
  });

  group('SourceDef.workKey —— 跨源唯一键', () {
    test('sourceKey 与 workId 复合', () {
      expect(SourceDef.workKey('nas', '163403'), 'nas::163403');
    });
  });

  group('SourceCaps / HealthLevel', () {
    test('不支持的源能力全关', () {
      const caps = SourceCaps.disabled();
      expect(caps.searchable, isFalse);
      expect(caps.quickSearch, isFalse);
      expect(caps.filterable, isFalse);
      expect(caps.changeable, isFalse);
    });

    test('健康度分级', () {
      const good = SourceHealth(latencyMs: 86, successRate: 0.98);
      expect(good.level, HealthLevel.excellent);
      const degraded = SourceHealth(latencyMs: 1200, successRate: 0.5);
      expect(degraded.level, HealthLevel.degraded);
      const dead = SourceHealth(successRate: 0.0);
      expect(dead.level, HealthLevel.dead);
    });
  });

  group('PageResult.hasMore（total 缺失容错，docs/04 §5.1）', () {
    test('pageCount 存在时按页码判断', () {
      const r = PageResult<int>(items: [1], page: 2, pageCount: 3);
      expect(r.hasMore, isTrue);
      const last = PageResult<int>(items: [1], page: 3, pageCount: 3);
      expect(last.hasMore, isFalse);
    });

    test('pageCount 缺失时以 items 非空判断', () {
      const r = PageResult<int>(items: [1], page: 1);
      expect(r.hasMore, isTrue);
      const empty = PageResult<int>(items: [], page: 1);
      expect(empty.hasMore, isFalse);
    });
  });
}
