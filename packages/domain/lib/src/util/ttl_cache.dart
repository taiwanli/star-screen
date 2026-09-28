/// 简易 TTL 内存缓存（源引擎 HTTP 响应，降低重复拉取）。
class TtlCache<T> {
  TtlCache({this.ttl = const Duration(minutes: 3), this.maxEntries = 256});

  final Duration ttl;
  final int maxEntries;

  final _map = <String, _Entry<T>>{};

  T? get(String key) {
    final e = _map[key];
    if (e == null) return null;
    if (DateTime.now().difference(e.at) > ttl) {
      _map.remove(key);
      return null;
    }
    // 命中即移到尾部（最近使用）
    _map.remove(key);
    _map[key] = e;
    return e.value;
  }

  void set(String key, T value) {
    // docs/13 D2：命中/写入均移到尾部（LRU 语义），淘汰从头部取最久未用
    _map.remove(key);
    if (_map.length >= maxEntries) {
      _map.remove(_map.keys.first);
    }
    _map[key] = _Entry(value, DateTime.now());
  }

  void clear() => _map.clear();

  void invalidatePrefix(String prefix) {
    _map.removeWhere((k, _) => k.startsWith(prefix));
  }

  int get length => _map.length;
}

class _Entry<T> {
  final T value;
  final DateTime at;
  const _Entry(this.value, this.at);
}
