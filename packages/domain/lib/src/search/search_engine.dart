import 'dart:async';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../util/semaphore.dart';

/// 聚合搜索更新事件（渐进推送：先到先渲染，失败不阻塞 —— docs/05 §4.2 时序）。
sealed class SearchUpdate {
  const SearchUpdate();
}

class SearchSourceDone extends SearchUpdate {
  final String sourceKey;
  final String sourceName;
  final List<WorkCard> items;

  const SearchSourceDone(this.sourceKey, this.sourceName, this.items);
}

class SearchSourceFailed extends SearchUpdate {
  final String sourceKey;
  final String sourceName;
  final String reason;

  const SearchSourceFailed(this.sourceKey, this.sourceName, this.reason);
}

class SearchCompleted extends SearchUpdate {
  final int failedCount;

  const SearchCompleted(this.failedCount);
}

/// 归并后的同片分组（多源卡的数据源）。
class SearchGroup {
  final String key;
  final String title;
  final String? year;
  final List<WorkCard> items;

  const SearchGroup({required this.key, required this.title, this.year, required this.items});
}

/// 聚合搜索引擎（docs/09 M2-1）。
///
/// 并发分片（信号量限流）+ 单源超时 + 失败跳过（不阻塞整体）+ 同片归并。
/// 渐进 Stream：UI 先到先渲染，失败源置灰可重试。
class SearchEngine {
  final List<VideoSource> sources;
  final int concurrency;
  final Duration timeout;

  /// 跳过的源（熔断冷却中，docs/18 §5）。
  final Set<String> skipKeys;

  SearchEngine({
    required this.sources,
    this.concurrency = 8,
    this.timeout = const Duration(seconds: 8),
    this.skipKeys = const {},
  });

  Stream<SearchUpdate> searchAll(String keyword) {
    // 单订阅控制器：未 listen 时缓冲事件，避免 broadcast 丢包
    final controller = StreamController<SearchUpdate>();
    Future(() async {
      var failed = 0;
      final semaphore = Semaphore(concurrency);
      final active = [
        for (final s in sources)
          if (!skipKeys.contains(s.def.key)) s,
      ];
      await Future.wait([
        for (final source in active)
          () async {
            await semaphore.acquire();
            try {
              final page = await source.search(keyword).timeout(timeout);
              controller.add(SearchSourceDone(
                source.def.key,
                source.def.name,
                page.items,
              ));
            } on TimeoutException {
              failed++;
              controller.add(
                  SearchSourceFailed(source.def.key, source.def.name, '搜索超时'));
            } on Object catch (e) {
              failed++;
              controller.add(
                  SearchSourceFailed(source.def.key, source.def.name, e.toString()));
            } finally {
              semaphore.release();
            }
          }(),
      ]);
      controller.add(SearchCompleted(failed));
      await controller.close();
    });
    return controller.stream;
  }

  /// 同片归并去重：标题（去空白）+ 年份为指纹（docs/04 §4.2 DetailService 同思路）。
  /// [healthScore] 可选：sourceKey → 0-100，多源组内按健康分排序。
  static List<SearchGroup> mergeWorks(
    Iterable<WorkCard> cards, {
    Map<String, double> healthScore = const {},
  }) {
    final groups = <String, SearchGroup>{};
    for (final card in cards) {
      final normTitle = card.title.replaceAll(RegExp(r'\s+'), '');
      final key = '$normTitle|${card.year ?? ''}';
      final existing = groups[key];
      if (existing == null) {
        groups[key] = SearchGroup(
          key: key,
          title: card.title,
          year: card.year,
          items: [card],
        );
      } else {
        existing.items.add(card);
      }
    }
    // 多源的组排前；组内按健康分（无分则保持原序）
    final list = groups.values.toList()
      ..sort((a, b) {
        final n = b.items.length.compareTo(a.items.length);
        if (n != 0) return n;
        double best(List<WorkCard> items) {
          var m = 0.0;
          for (final c in items) {
            final s = healthScore[c.sourceKey] ?? 0;
            if (s > m) m = s;
          }
          return m;
        }

        return best(b.items).compareTo(best(a.items));
      });
    for (final g in list) {
      if (healthScore.isNotEmpty) {
        g.items.sort((a, b) =>
            (healthScore[b.sourceKey] ?? 0).compareTo(healthScore[a.sourceKey] ?? 0));
      }
    }
    return list;
  }

  static String normalizeTitle(String title) =>
      title.replaceAll(RegExp(r'\s+'), '');
}
