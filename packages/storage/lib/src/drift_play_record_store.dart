import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';

/// [PlayRecordStore] 的 drift 实现（play_record 表）。
///
/// 注意外键：play_record.work_key 引用 work_snapshot，落记录前须先
/// [upsertSnapshot] 写入作品快照（源失效后「我的」仍完整的依据）。
class DriftPlayRecordStore implements PlayRecordStore {
  final StarDatabase db;

  DriftPlayRecordStore(this.db);

  /// 写入/更新作品快照（播放与收藏的前置）。
  /// 空字段 absent，避免把已有快照抹成 null。
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

  @override
  Future<PlayRecord?> get(String workKey) async {
    final query = db.select(db.playRecords)..where((t) => t.workKey.equals(workKey));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return PlayRecord(
      workKey: row.workKey,
      sourceKey: row.sourceKey,
      episodeIndex: row.episodeIndex,
      positionSec: row.positionSec,
      durationSec: row.durationSec,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  /// 换源保进度（docs/19 P1）：把 [fromKey] 的进度复制到 [toCard]。
  /// 集数按 [maxEpisodeIndex] 钳制；时长按 [durationScale] 缩放（跨源时长不同）。
  @override
  Future<PlayRecord?> copyProgressTo({
    required String fromKey,
    required WorkCard toCard,
    int maxEpisodeIndex = 1 << 30,
    double durationScale = 1.0,
  }) async {
    final rec = await get(fromKey);
    if (rec == null) return null;
    final ep = rec.episodeIndex.clamp(0, maxEpisodeIndex);
    final dur = durationScale <= 0
        ? rec.durationSec
        : (rec.durationSec * durationScale).round();
    final pos = rec.positionSec > dur && dur > 0 ? dur - 1 : rec.positionSec;
    await upsertSnapshot(toCard);
    final out = PlayRecord(
      workKey: toCard.workKey,
      sourceKey: toCard.sourceKey,
      episodeIndex: ep,
      positionSec: pos,
      durationSec: dur > 0 ? dur : rec.durationSec,
      updatedAt: DateTime.now(),
      lineId: rec.lineId,
    );
    await save(out);
    return out;
  }

  @override
  Future<void> save(PlayRecord record) async {
    // FK：play_record 依赖 work_snapshot（P06/整改）
    await _ensureSnapshot(record.workKey, record.sourceKey);
    await db.into(db.playRecords).insertOnConflictUpdate(
          PlayRecordsCompanion.insert(
            workKey: record.workKey,
            sourceKey: record.sourceKey,
            episodeIndex: record.episodeIndex,
            lineId: Value(record.lineId),
            positionSec: Value(record.positionSec),
            durationSec: Value(record.durationSec),
            updatedAt: record.updatedAt.millisecondsSinceEpoch,
          ),
        );
  }

  /// 继续观看条目（记录 + 快照标题/海报，供三端轨道直接渲染）。
  Future<List<ContinueItem>> continueWatchingDetailed() async {
    final query = db.select(db.playRecords).join([
      innerJoin(db.workSnapshots, db.workSnapshots.workKey
          .equalsExp(db.playRecords.workKey)),
    ])
      ..where(db.playRecords.positionSec.isBiggerThanValue(0))
      ..orderBy([
        OrderingTerm(expression: db.playRecords.updatedAt, mode: OrderingMode.desc)
      ])
      ..limit(60);

    final rows = await query.get();
    final items = <ContinueItem>[];
    for (final row in rows) {
      final record = row.readTable(db.playRecords);
      final snapshot = row.readTable(db.workSnapshots);
      final progress =
          record.durationSec > 0 ? record.positionSec / record.durationSec : 0.0;
      if (progress >= 0.9) continue; // 看完自动移出
      items.add(ContinueItem(
        record: PlayRecord(
          workKey: record.workKey,
          sourceKey: record.sourceKey,
          episodeIndex: record.episodeIndex,
          positionSec: record.positionSec,
          durationSec: record.durationSec,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(record.updatedAt),
        ),
        title: snapshot.title,
        posterUrl: snapshot.posterPath,
        remarks: snapshot.remarks,
      ));
    }
    return items;
  }

  /// 简版继续观看（不含快照字段，测试与内部使用）。
  Future<List<PlayRecord>> continueWatching() async {
    final query = db.select(db.playRecords)
      ..where((t) => t.positionSec.isBiggerThanValue(0))
      ..orderBy([
        (u) => OrderingTerm(expression: u.updatedAt, mode: OrderingMode.desc)
      ])
      ..limit(60);
    final rows = await query.get();
    return [
      for (final row in rows)
        if (!(row.durationSec > 0 &&
            row.positionSec / row.durationSec >= 0.9)) // ≥90% 已看完
          PlayRecord(
            workKey: row.workKey,
            sourceKey: row.sourceKey,
            episodeIndex: row.episodeIndex,
            positionSec: row.positionSec,
            durationSec: row.durationSec,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
          ),
    ];
  }

  Future<void> _ensureSnapshot(String workKey, String sourceKey) async {
    final src = sourceKey.isEmpty ? workKey.split('::').first : sourceKey;
    await upsertSnapshot(WorkCard(
      sourceKey: src,
      workId: SourceDef.workIdFromKey(workKey, src),
      title: workKey,
    ));
  }

  /// 导出辅助（v0.9 同步复用）：整表 JSON。
  Future<String> exportJson() async {
    final rows = await db.select(db.playRecords).get();
    return jsonEncode([
      for (final r in rows)
        {
          'workKey': r.workKey,
          'sourceKey': r.sourceKey,
          'episodeIndex': r.episodeIndex,
          'positionSec': r.positionSec,
          'durationSec': r.durationSec,
          'updatedAt': r.updatedAt,
        },
    ]);
  }

  /// 完整观看历史（含已看完），按时间倒序。
  Future<List<ContinueItem>> historyDetailed({int limit = 100}) async {
    final query = db.select(db.playRecords).join([
      innerJoin(db.workSnapshots, db.workSnapshots.workKey
          .equalsExp(db.playRecords.workKey)),
    ])
      ..orderBy([
        OrderingTerm(expression: db.playRecords.updatedAt, mode: OrderingMode.desc)
      ])
      ..limit(limit * 2);

    final rows = await query.get();
    return [
      for (final row in rows)
        ContinueItem(
          record: PlayRecord(
            workKey: row.readTable(db.playRecords).workKey,
            sourceKey: row.readTable(db.playRecords).sourceKey,
            episodeIndex: row.readTable(db.playRecords).episodeIndex,
            positionSec: row.readTable(db.playRecords).positionSec,
            durationSec: row.readTable(db.playRecords).durationSec,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
                row.readTable(db.playRecords).updatedAt),
          ),
          title: row.readTable(db.workSnapshots).title,
          posterUrl: row.readTable(db.workSnapshots).posterPath,
          remarks: row.readTable(db.workSnapshots).remarks,
        ),
    ];
  }

  Future<void> delete(String workKey) async {
    await (db.delete(db.playRecords)..where((t) => t.workKey.equals(workKey)))
        .go();
  }

  Future<void> clearAll() async {
    await db.delete(db.playRecords).go();
  }

  /// 从 JSON 恢复（导出导入）。
  Future<int> importJson(String jsonText) async {
    final list = jsonDecode(jsonText) as List<dynamic>;
    var n = 0;
    for (final item in list) {
      final m = Map<String, dynamic>.from(item as Map);
      final workKey = m['workKey']?.toString();
      if (workKey == null) continue;
      await db.into(db.playRecords).insertOnConflictUpdate(
            PlayRecordsCompanion.insert(
              workKey: workKey,
              sourceKey: m['sourceKey']?.toString() ?? '',
              episodeIndex: (m['episodeIndex'] as num?)?.toInt() ?? 0,
              positionSec: Value((m['positionSec'] as num?)?.toInt() ?? 0),
              durationSec: Value((m['durationSec'] as num?)?.toInt() ?? 0),
              updatedAt: (m['updatedAt'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
      n++;
    }
    return n;
  }
}

/// 继续观看轨道条目：记录 + 快照字段（三端轨道直接渲染）。
class ContinueItem {
  final PlayRecord record;
  final String title;
  final String? posterUrl;
  final String? remarks;

  const ContinueItem({
    required this.record,
    required this.title,
    this.posterUrl,
    this.remarks,
  });

  /// 副信息锁死格式：「第 N 集 · 剩余 M 分钟」（docs/07 §4.5）。
  String get subtitle {
    final remaining = record.durationSec > record.positionSec
        ? record.durationSec - record.positionSec
        : 0;
    final minutes = (remaining / 60).ceil();
    return '第 ${record.episodeIndex + 1} 集 · 剩余 $minutes 分钟';
  }

  double get progress => record.progress;
}
