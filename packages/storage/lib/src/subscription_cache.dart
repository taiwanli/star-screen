import 'package:drift/drift.dart' show Value;

import 'db/star_database.dart';

/// 订阅 ETag 缓存（docs/13 B2 共享层）：
/// 按 URL 查最近一次已缓存订阅（etag + raw），供 `FeedFetcher` 发起
/// 304 协商；刷新成功后回填，避免全量重拉。三端 `AppServices` 共用。
class SubscriptionCache {
  SubscriptionCache(this.db);

  final StarDatabase db;

  /// 查最近一次该订阅（按 url 匹配）的缓存行。
  Future<SubscriptionRow?> find(String ref) async {
    final url = ref.trim();
    return (db.select(db.subscriptions)..where((t) => t.url.equals(url)))
        .getSingleOrNull();
  }

  /// 把 ETag + 原文回填 [subscriptions] 表（仅 http(s) 远程地址）。
  Future<void> upsert(String ref, String? etag, String raw) async {
    final url = ref.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    final existing = await find(url);
    final companion = SubscriptionsCompanion(
      kind: const Value('tvbox'),
      url: Value(url),
      etag: Value(etag),
      fetchedAt: Value(DateTime.now().millisecondsSinceEpoch),
      raw: Value(raw),
    );
    if (existing != null) {
      await (db.update(db.subscriptions)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
    } else {
      await db.into(db.subscriptions).insert(companion);
    }
  }
}
