import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class FakeSearchSource implements VideoSource {
  @override
  final SourceDef def;
  final List<WorkCard> results;

  FakeSearchSource(String key, this.results)
      : def = SourceDef(key: key, name: key, kind: SourceKind.cmsJson);

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async =>
      PageResult(items: results, page: 1);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

WorkCard card(String source, String title, {String? year}) => WorkCard(
      sourceKey: source,
      workId: title,
      title: title,
      year: year,
    );

void main() {
  group('DetailService.findAltSources —— 跨源同片匹配（docs/09 M2-2）', () {
    test('年份一致者优先，且排除原源', () async {
      const originDef = SourceDef(key: 'a', name: '源A', kind: SourceKind.cmsJson);
      final service = DetailService(sources: [
        FakeSearchSource('a', [card('a', '长夜将尽', year: '2026')]),
        FakeSearchSource('b', [card('b', '长夜将尽', year: '2026')]),
        FakeSearchSource('c', [card('c', '长夜将尽', year: '2025')]),
        FakeSearchSource('d', [card('d', '完全不同')]),
      ]);

      final alts = await service.findAltSources(
        origin: originDef,
        card: card('a', '长夜将尽', year: '2026'),
      );

      expect(alts, hasLength(1));
      expect(alts.single.def.key, 'b');
      expect(alts.single.card.workKey, 'b::长夜将尽');
    });

    test('无年份一致候选时回退为标题匹配', () async {
      final service = DetailService(sources: [
        FakeSearchSource('b', [card('b', '长夜将尽')]),
      ]);
      final alts = await service.findAltSources(
        origin: const SourceDef(key: 'a', name: 'A', kind: SourceKind.cmsJson),
        card: card('a', '长夜将尽', year: '2026'),
      );
      expect(alts.single.def.key, 'b');
    });

    test('无同片候选返回空', () async {
      final service = DetailService(sources: [
        FakeSearchSource('b', [card('b', '别的片子')]),
      ]);
      final alts = await service.findAltSources(
        origin: const SourceDef(key: 'a', name: 'A', kind: SourceKind.cmsJson),
        card: card('a', '长夜将尽'),
      );
      expect(alts, isEmpty);
    });
  });
}
