import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';

/// [SourceDefStore] 的 drift 实现（docs/09 M0-3）。
///
/// 映射规则与 schema.sql / star_database.dart 保持一致：
/// caps 四布尔 ↔ 布尔列；headers ↔ JSON 文本；启停/排序直接落列。
class DriftSourceDefStore implements SourceDefStore {
  final StarDatabase db;

  DriftSourceDefStore(this.db);

  @override
  Future<List<SourceDef>> loadAll() async {
    final query = db.select(db.sourceDefs)
      ..orderBy([(u) => OrderingTerm(expression: u.sort)]);
    final rows = await query.get();
    return [for (final r in rows) _toModel(r)];
  }

  @override
  Future<void> upsertAll(List<SourceDef> defs) async {
    await db.batch((b) {
      for (final def in defs) {
        b.insert(
          db.sourceDefs,
          _toCompanion(def),
          onConflict: DoUpdate((_) => _toCompanion(def)),
        );
      }
    });
  }

  @override
  Future<void> setEnabled(String key, bool enabled) async {
    await (db.update(db.sourceDefs)..where((t) => t.key.equals(key)))
        .write(SourceDefsCompanion(enabled: Value(enabled)));
  }

  @override
  Future<void> delete(String key) async {
    await (db.delete(db.sourceDefs)..where((t) => t.key.equals(key))).go();
  }

  @override
  Future<void> updateSort(List<String> orderedKeys) async {
    await db.batch((b) {
      for (var i = 0; i < orderedKeys.length; i++) {
        b.update(db.sourceDefs,
            SourceDefsCompanion(sort: Value(i)),
            where: (t) => t.key.equals(orderedKeys[i]));
      }
    });
  }

  // ---------------- 映射 ----------------

  SourceDef _toModel(SourceDefRow r) => SourceDef(
        key: r.key,
        name: r.name,
        kind: SourceKind.values.byName(r.kind),
        cmsVariant: CmsVariant.values.byName(r.cmsVariant),
        endpoint: r.endpoint,
        extRaw: r.extRaw,
        extUrl: r.extUrl,
        sourceUrl: r.sourceUrl,
        jarRef: r.jarRef,
        caps: SourceCaps(
          searchable: r.capsSearchable,
          quickSearch: r.capsQuickSearch,
          filterable: r.capsFilterable,
          changeable: r.capsChangeable,
        ),
        headers: r.headers == null
            ? const {}
            : Map<String, String>.from(jsonDecode(r.headers!) as Map),
        timeoutSec: r.timeoutSec,
        unsupportedReason: r.unsupportedReason,
        enabled: r.enabled,
        groupId: r.groupId,
      );

  SourceDefsCompanion _toCompanion(SourceDef d) => SourceDefsCompanion.insert(
        key: d.key,
        name: d.name,
        kind: d.kind.name,
        cmsVariant: Value(d.cmsVariant.name),
        endpoint: Value(d.endpoint),
        extRaw: Value(d.extRaw),
        extUrl: Value(d.extUrl),
        sourceUrl: Value(d.sourceUrl),
        jarRef: Value(d.jarRef),
        capsSearchable: Value(d.caps.searchable),
        capsQuickSearch: Value(d.caps.quickSearch),
        capsFilterable: Value(d.caps.filterable),
        capsChangeable: Value(d.caps.changeable),
        headers: d.headers.isEmpty
            ? const Value.absent()
            : Value(jsonEncode(d.headers)),
        timeoutSec: Value(d.timeoutSec),
        unsupportedReason: Value(d.unsupportedReason),
        enabled: Value(d.enabled),
        groupId: Value(d.groupId),
      );
}

/// [KeyValueStore] 的 drift 实现（app_setting 表）。
class DriftKeyValueStore implements KeyValueStore {
  final StarDatabase db;

  DriftKeyValueStore(this.db);

  @override
  Future<String?> getString(String key) async {
    final query = db.select(db.appSettings)..where((t) => t.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setString(String key, String value) async {
    await db
        .into(db.appSettings)
        .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
  }

  @override
  Future<void> remove(String key) async {
    await (db.delete(db.appSettings)..where((t) => t.key.equals(key))).go();
  }

  /// 全量 KV（备份导出用）。
  Future<Map<String, String>> all() async {
    final rows = await db.select(db.appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  /// 批量写入（备份导入用）。
  Future<void> putAll(Map<String, String> entries) async {
    for (final e in entries.entries) {
      await setString(e.key, e.value);
    }
  }
}
