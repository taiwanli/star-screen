import 'dart:convert';

import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';

/// 全量备份编解码（docs/02 §4.4 导出导入 / v0.9 同步复用）。
class DriftBackupCodec implements BackupCodec {
  final StarDatabase db;
  final DriftPlayRecordStore records;
  final DriftFavoriteStore favorites;
  final DriftSourceDefStore sources;
  final DriftKeyValueStore settings;

  DriftBackupCodec({
    required this.db,
    required this.records,
    required this.favorites,
    required this.sources,
    required this.settings,
  });

  @override
  Future<String> exportAll() async {
    final sourceDefs = await sources.loadAll();
    final playRecords = await records.historyDetailed();
    final favs = await favorites.listAll();
    return jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'sources': [
        for (final s in sourceDefs) _sourceToJson(s),
      ],
      'playRecords': [
        for (final h in playRecords)
          {
            'workKey': h.record.workKey,
            'sourceKey': h.record.sourceKey,
            'episodeIndex': h.record.episodeIndex,
            'positionSec': h.record.positionSec,
            'durationSec': h.record.durationSec,
            'updatedAt': h.record.updatedAt.millisecondsSinceEpoch,
            'title': h.title,
            'posterUrl': h.posterUrl,
            'remarks': h.remarks,
          },
      ],
      'favorites': [
        for (final f in favs)
          {
            'workKey': f.favorite.workKey,
            'sourceKey': f.favorite.snapshot.sourceKey,
            'title': f.title,
            'posterUrl': f.posterUrl,
            'folderId':
                int.tryParse(f.favorite.folderId), // '' → null
            'createdAt': f.favorite.createdAt.millisecondsSinceEpoch,
          },
      ],
      'settings': await settings.all(),
    });
  }

  @override
  Future<Map<String, int>> importAll(String jsonText) async {
    final root = jsonDecode(jsonText) as Map<String, dynamic>;
    var sources = 0, records = 0, favorites = 0, settings = 0;

    final srcList = root['sources'];
    if (srcList is List) {
      for (final item in srcList) {
        final def = _sourceFromJson(item);
        if (def == null) continue;
        await this.sources.upsertAll([def]);
        sources++;
      }
    }

    // play_record 外键要求 work_snapshot 先存在
    final recList = root['playRecords'];
    if (recList is List) {
      for (final item in recList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final workKey = m['workKey']?.toString();
        if (workKey == null || workKey.isEmpty) continue;
        await this.favorites.upsertSnapshot(
            _cardOf(workKey, m['sourceKey']?.toString(), m['title']?.toString(),
                poster: m['posterUrl']?.toString()));
      }
      // 用带标题的快照 + 记录字段导入
      for (final item in recList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final workKey = m['workKey']?.toString();
        if (workKey == null || workKey.isEmpty) continue;
        await this.records.importJson(jsonEncode([
          {
            'workKey': workKey,
            'sourceKey': m['sourceKey']?.toString() ?? '',
            'episodeIndex': m['episodeIndex'],
            'positionSec': m['positionSec'],
            'durationSec': m['durationSec'],
            'updatedAt': m['updatedAt'],
          }
        ]));
        records++;
      }
    }

    final favList = root['favorites'];
    if (favList is List) {
      for (final item in favList) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final workKey = m['workKey']?.toString();
        if (workKey == null || workKey.isEmpty) continue;
        await this.favorites.upsertSnapshot(_cardOf(
          workKey,
          m['sourceKey']?.toString(),
          m['title']?.toString(),
          poster: m['posterUrl']?.toString(),
        ));
        await this.favorites.add(
          workKey,
          folderId: (m['folderId'] as num?)?.toInt(),
        );
        favorites++;
      }
    }

    final kvMap = root['settings'];
    if (kvMap is Map) {
      final entries = <String, String>{};
      for (final e in kvMap.entries) {
        entries[e.key.toString()] = e.value?.toString() ?? '';
      }
      await this.settings.putAll(entries);
      settings = entries.length;
    }

    return {
      'sources': sources,
      'records': records,
      'favorites': favorites,
      'settings': settings,
    };
  }

  static Map<String, Object?> _sourceToJson(SourceDef s) => {
        'key': s.key,
        'name': s.name,
        'kind': s.kind.name,
        'cmsVariant': s.cmsVariant.name,
        'endpoint': s.endpoint,
        'extRaw': s.extRaw,
        'extUrl': s.extUrl,
        'sourceUrl': s.sourceUrl,
        'jarRef': s.jarRef,
        'timeoutSec': s.timeoutSec,
        'enabled': s.enabled,
        'groupId': s.groupId,
        'headers': s.headers,
        'unsupportedReason': s.unsupportedReason,
      };

  static SourceDef? _sourceFromJson(Object? item) {
    if (item is! Map) return null;
    final m = Map<String, dynamic>.from(item);
    final kindName = m['kind']?.toString();
    final kind =
        SourceKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) return null;
    final variantName = m['cmsVariant']?.toString();
    final variant =
        CmsVariant.values.where((v) => v.name == variantName).firstOrNull ??
            CmsVariant.none;
    return SourceDef(
      key: m['key']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      kind: kind,
      cmsVariant: variant,
      endpoint: m['endpoint']?.toString(),
      extRaw: m['extRaw']?.toString(),
      extUrl: m['extUrl']?.toString(),
      sourceUrl: m['sourceUrl']?.toString(),
      jarRef: m['jarRef']?.toString(),
      timeoutSec: (m['timeoutSec'] as num?)?.toInt(),
      enabled: m['enabled'] != false,
      groupId: m['groupId']?.toString(),
      headers: m['headers'] is Map
          ? Map<String, String>.from((m['headers'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString())))
          : const {},
      unsupportedReason: m['unsupportedReason']?.toString(),
    );
  }

  /// workKey = `sourceKey::workId` → WorkCard（用于写快照）。
  static WorkCard _cardOf(String workKey, String? sourceKey, String? title,
      {String? poster}) {
    final src = (sourceKey == null || sourceKey.isEmpty)
        ? workKey.split('::').first
        : sourceKey;
    final workId = SourceDef.workIdFromKey(workKey, src);
    return WorkCard(
      sourceKey: src,
      workId: workId,
      title: title ?? workId,
      posterUrl: poster,
    );
  }
}
