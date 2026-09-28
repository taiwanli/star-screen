import 'package:star_storage/star_storage.dart';
import 'package:test/test.dart';

class _MemKv implements KeyValueStore {
  final Map<String, String> _m = {};
  @override
  Future<String?> getString(String key) async => _m[key];
  @override
  Future<void> setString(String key, String value) async => _m[key] = value;
  @override
  Future<void> remove(String key) async => _m.remove(key);
}

void main() {
  test('DownloadStore enqueue/update/remove', () async {
    final store = DownloadStore(_MemKv());
    final item = await store.enqueue(title: '片', url: 'http://a/b.mp4');
    expect(await store.list(), hasLength(1));
    await store.update(item.copyWith(status: DownloadStatus.done));
    final list = await store.list();
    expect(list.single.status, DownloadStatus.done);
    await store.remove(item.id);
    expect(await store.list(), isEmpty);
  });
}
