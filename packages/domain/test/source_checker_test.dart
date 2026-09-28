import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class _Src implements VideoSource {
  @override
  final SourceDef def;
  final bool ok;
  _Src(this.def, this.ok);

  @override
  Future<HomeFeed> home() async {
    if (!ok) throw Exception('down');
    return const HomeFeed(recommend: []);
  }

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    if (!ok) throw Exception('down');
    return const PageResult(items: [WorkCard(sourceKey: 'g', workId: '1', title: 't')], page: 1);
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async =>
      const PageResult(items: [], page: 1);
  @override
  Future<WorkDetail> detail(String workId) async => throw UnimplementedError();
  @override
  Future<PlayCandidate> resolve(PlayRequest request) async =>
      throw UnimplementedError();
}

void main() {
  test('SourceChecker 标出失效源', () async {
    final good = const SourceDef(key: 'g', name: '好', kind: SourceKind.cmsJson);
    final bad = const SourceDef(key: 'b', name: '坏', kind: SourceKind.cmsJson);
    final results = await SourceChecker().checkAll([_Src(good, true), _Src(bad, false)]);
    expect(results.where((r) => r.ok).length, 1);
    expect(results.firstWhere((r) => r.key == 'b').ok, isFalse);

    final checks = {for (final r in results) r.key: r};
    final invalid = SourceFilter.invalid.apply([good, bad], checks);
    expect(invalid.single.key, 'b');
    final enabled = SourceFilter.enabled.apply(
        [good, bad], checks);
    expect(enabled.length, 2);
  });
}
