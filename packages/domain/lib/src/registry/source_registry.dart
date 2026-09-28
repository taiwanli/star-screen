import '../config/parse_report.dart';
import '../models/models.dart';
import '../playback/play_url_filter.dart';

/// 源定义持久化接口 —— 由 storage 包以 drift 实现（docs/09 M0-3），
/// 测试与默认场景使用 [InMemorySourceDefStore]。
abstract interface class SourceDefStore {
  Future<List<SourceDef>> loadAll();

  /// 按 key 插入或更新；已存在的条目不覆盖（固化由 [SourceRegistry] 保证）。
  Future<void> upsertAll(List<SourceDef> defs);

  Future<void> setEnabled(String key, bool enabled);

  Future<void> delete(String key);

  /// 按 [orderedKeys] 顺序写 sort；未列出的 key 排在最后（保持相对顺序）。
  Future<void> updateSort(List<String> orderedKeys);
}

/// 内存实现（默认/测试）。
class InMemorySourceDefStore implements SourceDefStore {
  final Map<String, SourceDef> _byKey = {};
  final List<String> _order = [];

  @override
  Future<List<SourceDef>> loadAll() async {
    final rank = <String, int>{for (var i = 0; i < _order.length; i++) _order[i]: i};
    final defs = _byKey.values.toList()
      ..sort((a, b) =>
          (rank[a.key] ?? 1 << 30).compareTo(rank[b.key] ?? 1 << 30));
    return defs;
  }

  @override
  Future<void> upsertAll(List<SourceDef> defs) async {
    for (final def in defs) {
      if (!_byKey.containsKey(def.key)) _order.add(def.key);
      _byKey[def.key] = def;
    }
  }

  @override
  Future<void> setEnabled(String key, bool enabled) async {
    final def = _byKey[key];
    if (def != null) _byKey[key] = def.withEnabled(enabled);
  }

  @override
  Future<void> delete(String key) async {
    _byKey.remove(key);
    _order.remove(key);
  }

  @override
  Future<void> updateSort(List<String> orderedKeys) async {
    final known = orderedKeys.where(_byKey.containsKey).toSet();
    _order
      ..removeWhere(known.contains)
      ..insertAll(0, known);
  }
}

/// 源注册表（docs/05 §3「source_registry」）。
///
/// 关键原则「解析器固化」：同一 key 重复导入时，已注册源的解析结果与启停
/// 状态不被覆盖 —— 根治生态中"多配置合并覆盖全局 spider 导致站点失效"的问题。
class SourceRegistry {
  final SourceDefStore store;

  SourceRegistry({SourceDefStore? store})
      : store = store ?? InMemorySourceDefStore();

  /// 导入解析报告：新源插入（不支持的源默认禁用并保留原因）；已注册的 key
  /// 完整保留现有定义。[groupId] 用于多仓导入的分组归属（docs/09 M2-4）。
  Future<void> applyReport(ParseReport report, {String? groupId}) async {
    final existing = {for (final d in await store.loadAll()) d.key: d};
    final merged = <SourceDef>[];
    for (final def in report.sources) {
      final old = existing[def.key];
      if (old != null) {
        merged.add(old);
      } else if (def.kind.isSupported) {
        merged.add(groupId == null ? def : def.withGroup(groupId));
      } else {
        merged.add(def.withEnabled(false).withGroup(groupId));
      }
    }
    await store.upsertAll(merged);
    // FongMi/TV：ads / flags 进全局播放过滤（docs/05 修订）
    if (report.adFilters.isNotEmpty) {
      PlayUrlFilter.globalAds = [
        ...PlayUrlFilter.globalAds,
        ...report.adFilters,
      ];
    }
    if (report.playFlags.isNotEmpty) {
      PlayUrlFilter.globalFlags = [
        ...PlayUrlFilter.globalFlags,
        ...report.playFlags,
      ];
    }
  }

  Future<List<SourceDef>> all() => store.loadAll();

  /// 参与聚合的源：已启用且受支持。
  Future<List<SourceDef>> enabled() async =>
      (await store.loadAll()).where((d) => d.enabled && d.kind.isSupported).toList();

  Future<void> setEnabled(String key, bool enabled) =>
      store.setEnabled(key, enabled);

  Future<void> remove(String key) => store.delete(key);

  /// 按给定 key 顺序重排（拖拽排序/健康度排序的落点）。
  Future<void> reorder(List<String> orderedKeys) => store.updateSort(orderedKeys);
}
