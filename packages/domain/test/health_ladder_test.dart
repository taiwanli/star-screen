import 'dart:async';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class _FailingSource implements VideoSource {
  _FailingSource(this.key);
  final String key;

  @override
  SourceDef get def => SourceDef(key: key, name: key, kind: SourceKind.cmsJson);

  @override
  Future<HomeFeed> home() async => throw TimeoutException('检测超时');

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async =>
      throw TimeoutException('检测超时');

  @override
  Future<WorkDetail> detail(String workId) async =>
      throw TimeoutException('检测超时');

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async =>
      throw TimeoutException('检测超时');

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async =>
      throw TimeoutException('检测超时');
}

class _OkSource implements VideoSource {
  _OkSource(this.key);
  final String key;

  @override
  SourceDef get def => SourceDef(key: key, name: key, kind: SourceKind.cmsJson);

  @override
  Future<HomeFeed> home() async => HomeFeed(recommend: [
        WorkCard(sourceKey: key, workId: '1', title: '片'),
      ]);

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async =>
      const PageResult(items: [], page: 1);

  @override
  Future<WorkDetail> detail(String workId) async => throw UnimplementedError();

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async =>
      throw UnimplementedError();

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async =>
      const PageResult(items: [], page: 1);
}

void main() {
  group('HealthMonitor 阶梯熔断（docs/18 §5）', () {
    test('连续 5 次失败 → 熔断 30min', () async {
      final m = HealthMonitor();
      final src = _FailingSource('bad');
      for (var i = 0; i < 5; i++) {
        await m.probe(src);
      }
      expect(m.failStreak('bad'), 5);
      expect(m.isCooling('bad'), isTrue);
      final until = m.coolUntil('bad');
      expect(until, isNotNull);
      final delta = until!.difference(DateTime.now()).inMinutes;
      expect(delta, inInclusiveRange(29, 30));
    });

    test('连续 10 次失败 → 熔断 24h', () async {
      final m = HealthMonitor();
      final src = _FailingSource('bad');
      for (var i = 0; i < 10; i++) {
        await m.probe(src);
      }
      expect(m.failStreak('bad'), 10);
      expect(m.isCooling('bad'), isTrue);
      final delta = m.coolUntil('bad')!.difference(DateTime.now()).inHours;
      expect(delta, inInclusiveRange(23, 24));
    });

    test('成功一次即清空失败计数与熔断', () async {
      final m = HealthMonitor();
      final bad = _FailingSource('x');
      for (var i = 0; i < 5; i++) {
        await m.probe(bad);
      }
      expect(m.isCooling('x'), isTrue);
      await m.probe(_OkSource('x'));
      expect(m.failStreak('x'), 0);
      expect(m.isCooling('x'), isFalse);
    });

    test('一键 recover 清空熔断', () async {
      final m = HealthMonitor();
      final bad = _FailingSource('y');
      for (var i = 0; i < 6; i++) {
        await m.probe(bad);
      }
      expect(m.isCooling('y'), isTrue);
      m.recover('y');
      expect(m.isCooling('y'), isFalse);
      expect(m.failStreak('y'), 0);
      expect(m.lastFailReason('y'), isNull);
    });

    test('失败原因可读', () async {
      final m = HealthMonitor();
      await m.probe(_FailingSource('z'));
      expect(m.lastFailReason('z'), contains('超时'));
    });

    test('export/import 往返保留熔断', () async {
      final m = HealthMonitor();
      final bad = _FailingSource('w');
      for (var i = 0; i < 5; i++) {
        await m.probe(bad);
      }
      final state = m.exportState();
      final m2 = HealthMonitor()..importState(state);
      expect(m2.failStreak('w'), 5);
      expect(m2.isCooling('w'), isTrue);
      expect(m2.lastFailReason('w'), isNotNull);
    });
  });
}
