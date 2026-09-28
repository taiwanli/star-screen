import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  group('TtlCache', () {
    test('过期与前缀失效', () async {
      final c = TtlCache<int>(ttl: const Duration(milliseconds: 30));
      c.set('a/1', 1);
      c.set('b/2', 2);
      expect(c.get('a/1'), 1);
      c.invalidatePrefix('a/');
      expect(c.get('a/1'), isNull);
      expect(c.get('b/2'), 2);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(c.get('b/2'), isNull);
    });
  });

  group('HealthMonitor 升级', () {
    test('rank 按分排序；export/import 往返', () async {
      final mon = HealthMonitor();
      // 手工记录：key1 全成功低延迟，key2 全失败
      for (var i = 0; i < 5; i++) {
        await mon.probe(_FakeSource('k1', ok: true));
        await mon.probe(_FakeSource('k2', ok: false));
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final ranked = mon.rank([
        const SourceDef(key: 'k2', name: '差', kind: SourceKind.cmsJson),
        const SourceDef(key: 'k1', name: '好', kind: SourceKind.cmsJson),
      ]);
      expect(ranked.first.key, 'k1');
      expect(mon.isDegraded('k2'), isTrue);

      final state = mon.exportState();
      final mon2 = HealthMonitor()..importState(state);
      expect(mon2.healthOf('k1').successRate, mon.healthOf('k1').successRate);
    });
  });

  group('mergeWorks 健康分排序', () {
    test('多源组内高分源在前', () {
      final cards = [
        const WorkCard(sourceKey: 'low', workId: '1', title: '同片'),
        const WorkCard(sourceKey: 'high', workId: '2', title: '同片'),
      ];
      final groups = SearchEngine.mergeWorks(cards, healthScore: {
        'high': 90,
        'low': 10,
      });
      expect(groups.single.items.first.sourceKey, 'high');
    });
  });
}

class _FakeSource implements VideoSource {
  @override
  final SourceDef def;
  final bool ok;
  _FakeSource(String key, {required this.ok})
      : def = SourceDef(key: key, name: key, kind: SourceKind.cmsJson);

  @override
  Future<HomeFeed> home() async {
    if (!ok) throw Exception('down');
    return const HomeFeed(recommend: []);
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async =>
      const PageResult(items: [], page: 1);
  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async =>
      const PageResult(items: [], page: 1);
  @override
  Future<WorkDetail> detail(String workId) async => throw UnimplementedError();
  @override
  Future<PlayCandidate> resolve(PlayRequest request) async =>
      throw UnimplementedError();
}
