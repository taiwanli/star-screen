import 'dart:async';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class FakeSearchSource implements VideoSource {
  @override
  final SourceDef def;
  final PageResult<WorkCard>? result;
  final Object? throw_;
  final Duration? delay;

  FakeSearchSource(String key, String name,
      {this.result, this.throw_, this.delay})
      : def = SourceDef(key: key, name: name, kind: SourceKind.cmsJson);

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    if (delay != null) await Future<void>.delayed(delay!);
    if (throw_ != null) throw throw_!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

WorkCard card(String source, String title, {String? year}) => WorkCard(
      sourceKey: source,
      workId: '$source-$title',
      title: title,
      year: year,
    );

void main() {
  group('SearchEngine —— 聚合搜索（docs/09 M2-1）', () {
    test('渐进更新：成功/失败/完成三类事件，单源失败不阻塞整体', () async {
      final engine = SearchEngine(sources: [
        FakeSearchSource('a', '源A',
            result: PageResult(items: [card('a', '长夜将尽', year: '2026')], page: 1)),
        FakeSearchSource('b', '源B', throw_: const FetchException('请求失败')),
        FakeSearchSource(
            'c',
            '源C',
            result: PageResult(
                items: [card('c', '长夜将尽', year: '2026'), card('c', '其他片')], page: 1)),
      ], timeout: const Duration(seconds: 2));

      final updates = await engine.searchAll('长夜').toList();
      final done = updates.whereType<SearchSourceDone>().toList();
      final failed = updates.whereType<SearchSourceFailed>().toList();

      expect(done, hasLength(2));
      expect(failed, hasLength(1));
      expect(failed.single.sourceKey, 'b');
      expect(updates.last, isA<SearchCompleted>());
      expect(done.expand((u) => u.items), hasLength(3));
    });

    test('单源超时被捕获并标记失败（信号量并发=1 也能推进）', () async {
      final engine = SearchEngine(
        sources: [
          FakeSearchSource('slow', '慢源',
              delay: const Duration(seconds: 2),
              result: PageResult(items: [card('slow', '慢片')], page: 1)),
        ],
        concurrency: 1,
        timeout: const Duration(milliseconds: 100),
      );
      final updates = await engine.searchAll('x').toList();
      final failed = updates.whereType<SearchSourceFailed>().single;
      expect(failed.reason, contains('超时'));
      expect(updates.last, isA<SearchCompleted>());
    });

    test('mergeWorks：同片归并为多源组并置前', () {
      final groups = SearchEngine.mergeWorks([
        card('a', '长夜将尽', year: '2026'),
        card('b', '长 夜 将 尽', year: '2026'), // 空白差异归一
        card('c', '其他片'),
        card('d', '长夜将尽', year: '2025'), // 年份不同 → 独立组
      ]);
      expect(groups, hasLength(3));
      expect(groups.first.items, hasLength(2));
      expect(groups.first.title, '长夜将尽');
    });
  });

  group('Semaphore', () {
    test('并发上限与释放', () async {
      final sem = Semaphore(2);
      var running = 0;
      var peak = 0;
      await Future.wait([
        for (var i = 0; i < 5; i++)
          () async {
            await sem.acquire();
            running++;
            peak = peak > running ? peak : running;
            await Future<void>.delayed(const Duration(milliseconds: 20));
            running--;
            sem.release();
          }(),
      ]);
      expect(peak, 2);
    });
  });
}
