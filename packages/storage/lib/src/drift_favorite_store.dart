import 'package:drift/drift.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';

/// 收藏夹 + 收藏项（docs/02 §4.4）：作品快照外键，源失效后仍可见。
class DriftFavoriteStore {
  final StarDatabase db;

  DriftFavoriteStore(this.db);

  /// 写入/更新作品快照（收藏前置，与播放记录共用）。
  /// 空字段用 [Value.absent()]，避免 upsert 把已有海报/备注抹成 null。
  Future<void> upsertSnapshot(WorkCard card) async {
    await db.into(db.workSnapshots).insertOnConflictUpdate(
          WorkSnapshotsCompanion.insert(
            workKey: card.workKey,
            sourceKey: card.sourceKey,
            title: card.title,
            posterPath: card.posterUrl == null
                ? const Value.absent()
                : Value(card.posterUrl),
            remarks:
                card.remarks == null ? const Value.absent() : Value(card.remarks),
            year: card.year == null ? const Value.absent() : Value(card.year),
            area: card.area == null ? const Value.absent() : Value(card.area),
            genre: card.genre == null ? const Value.absent() : Value(card.genre),
            score: card.score == null ? const Value.absent() : Value(card.score),
          ),
        );
  }

  Future<int> createFolder(String name) async {
    return db.into(db.favoriteFolders).insert(
          FavoriteFoldersCompanion.insert(name: name),
        );
  }

  Future<List<FavoriteFolderRow>> folders() async {
    final q = db.select(db.favoriteFolders)
      ..orderBy([(t) => OrderingTerm.asc(t.sort), (t) => OrderingTerm.asc(t.id)]);
    return q.get();
  }

  Future<void> renameFolder(int id, String name) async {
    await (db.update(db.favoriteFolders)..where((t) => t.id.equals(id)))
        .write(FavoriteFoldersCompanion(name: Value(name)));
  }

  Future<void> deleteFolder(int id) async {
    // 先把夹内收藏改为无夹，避免 FK 拒删
    await (db.update(db.favorites)..where((t) => t.folderId.equals(id)))
        .write(const FavoritesCompanion(folderId: Value(null)));
    await (db.delete(db.favoriteFolders)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> isFavorite(String workKey) async {
    final q = db.select(db.favorites)..where((t) => t.workKey.equals(workKey));
    return (await q.getSingleOrNull()) != null;
  }

  Future<void> add(String workKey, {int? folderId, WorkCard? card}) async {
    if (card != null) {
      await upsertSnapshot(card);
    } else {
      final src = workKey.split('::').first;
      await upsertSnapshot(WorkCard(
        sourceKey: src,
        workId: SourceDef.workIdFromKey(workKey, src),
        title: workKey,
      ));
    }
    await db.into(db.favorites).insertOnConflictUpdate(
          FavoritesCompanion.insert(
            workKey: workKey,
            folderId: Value(folderId),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> remove(String workKey) async {
    await (db.delete(db.favorites)..where((t) => t.workKey.equals(workKey))).go();
  }

  Future<void> toggle(WorkCard card, {int? folderId}) async {
    await upsertSnapshot(card);
    if (await isFavorite(card.workKey)) {
      await remove(card.workKey);
    } else {
      await add(card.workKey, folderId: folderId, card: card);
    }
  }

  /// 收藏列表（含快照），按收藏时间倒序。
  Future<List<FavoriteItem>> listAll({int? folderId}) async {
    final q = db.select(db.favorites).join([
      innerJoin(db.workSnapshots,
          db.workSnapshots.workKey.equalsExp(db.favorites.workKey)),
    ])
      ..orderBy([
        OrderingTerm(
            expression: db.favorites.createdAt, mode: OrderingMode.desc)
      ]);
    if (folderId != null) {
      q.where(db.favorites.folderId.equals(folderId));
    }
    final rows = await q.get();
    return [
      for (final row in rows)
        FavoriteItem(
          favorite: Favorite(
            workKey: row.readTable(db.favorites).workKey,
            folderId: row.readTable(db.favorites).folderId?.toString() ?? '',
            snapshot: _cardFrom(row.readTable(db.workSnapshots)),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
                row.readTable(db.favorites).createdAt),
          ),
          title: row.readTable(db.workSnapshots).title,
          posterUrl: row.readTable(db.workSnapshots).posterPath,
        ),
    ];
  }

  static WorkCard _cardFrom(WorkSnapshotRow r) => WorkCard(
        sourceKey: r.sourceKey,
        workId: SourceDef.workIdFromKey(r.workKey, r.sourceKey),
        title: r.title,
        posterUrl: r.posterPath,
        remarks: r.remarks,
        year: r.year,
        area: r.area,
        genre: r.genre,
        score: r.score,
      );
}

/// 收藏条目：领域 Favorite + 展示字段。
class FavoriteItem {
  final Favorite favorite;
  final String title;
  final String? posterUrl;

  const FavoriteItem({
    required this.favorite,
    required this.title,
    required this.posterUrl,
  });
}
