import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';
import 'package:test/test.dart';

/// sqlite3 原生库缺失时跳过运行时测试。
final bool _sqliteAvailable = () {
  try {
    StarDatabase.memory();
    return true;
  } on Object {
    return false;
  }
}();

SourceDef _def(String key, {SourceKind kind = SourceKind.cmsJson}) => SourceDef(
      key: key,
      name: '源$key',
      kind: kind,
      endpoint: kind.isSupported ? 'https://x.example.com/$key' : null,
      headers: const {'User-Agent': 'StarScreen/Test'},
    );

void main() {
  group('StarDatabase + DriftSourceDefStore（docs/09 M0-3）', () {
    late StarDatabase db;
    late DriftSourceDefStore store;

    setUp(() {
      db = StarDatabase.memory();
      store = DriftSourceDefStore(db);
    });

    tearDown(() async => db.close());

    test('SourceDef 往返：upsertAll → loadAll 字段一致', () async {
      final defs = [
        _def('a'),
        _def('b', kind: SourceKind.cmsXml),
      ];
      await store.upsertAll(defs);
      final loaded = await store.loadAll();
      expect(loaded, hasLength(2));
      expect(loaded.first.name, '源a');
      expect(loaded.last.kind, SourceKind.cmsXml);
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('upsert 不产生重复行；setEnabled 落库', () async {
      await store.upsertAll([_def('a')]);
      await store.upsertAll([_def('a')]);
      expect(await store.loadAll(), hasLength(1));
      await store.setEnabled('a', false);
      final loaded = await store.loadAll();
      expect(loaded.single.enabled, isFalse);
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('delete 与 updateSort 顺序', () async {
      await store.upsertAll([_def('a'), _def('b'), _def('c')]);
      await store.updateSort(['c', 'a', 'b']);
      var keys = (await store.loadAll()).map((e) => e.key).toList();
      expect(keys, ['c', 'a', 'b']);
      await store.delete('a');
      keys = (await store.loadAll()).map((e) => e.key).toList();
      expect(keys, isNot(contains('a')));
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('播放记录外键级联：删除作品快照时记录消失', () async {
      final card = const WorkCard(sourceKey: 's', workId: 's::w', title: 'T');
      final records = DriftPlayRecordStore(db);
      await records.upsertSnapshot(card);
      await records.save(PlayRecord(
        workKey: card.workKey,
        sourceKey: card.sourceKey,
        episodeIndex: 0,
        positionSec: 10,
        durationSec: 100,
        updatedAt: DateTime.now(),
      ));
      expect(await records.get(card.workKey), isNotNull);
      await db.delete(db.workSnapshots).go();
      expect(await records.get(card.workKey), isNull);
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('DriftKeyValueStore：set/get/remove', () async {
      final kv = DriftKeyValueStore(db);
      await kv.setString('k', 'v');
      expect(await kv.getString('k'), 'v');
      await kv.remove('k');
      expect(await kv.getString('k'), isNull);
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('DriftLiveChannelStore：全量替换 + 分组聚合', () async {
      final live = DriftLiveChannelStore(db);
      await live.replaceAll([
        const ParsedLiveChannel(
            name: 'CCTV1', url: 'http://a/1', group: '央视'),
        const ParsedLiveChannel(
            name: 'CCTV2', url: 'http://a/2', group: '央视'),
        const ParsedLiveChannel(
            name: '湖南', url: 'http://a/3', group: '卫视'),
      ]);
      final grouped = await live.grouped();
      expect(grouped.keys, containsAll(['央视', '卫视']));
      expect(grouped['央视'], hasLength(2));
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');
  });

  group('Favorite + Backup（docs/02 §4.4）', () {
    late StarDatabase db;
    late DriftFavoriteStore favs;
    late DriftPlayRecordStore records;
    late DriftBackupCodec backup;

    setUp(() {
      db = StarDatabase.memory();
      favs = DriftFavoriteStore(db);
      records = DriftPlayRecordStore(db);
      backup = DriftBackupCodec(
        db: db,
        records: records,
        favorites: favs,
        sources: DriftSourceDefStore(db),
        settings: DriftKeyValueStore(db),
      );
    });

    tearDown(() async => db.close());

    test('收藏 toggle + 列表', () async {
      final card =
          const WorkCard(sourceKey: 's1', workId: 's1::w1', title: '夜航西行');
      await favs.toggle(card);
      expect(await favs.isFavorite(card.workKey), isTrue);
      final list = await favs.listAll();
      expect(list, hasLength(1));
      await favs.toggle(card);
      expect(await favs.isFavorite(card.workKey), isFalse);
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('观看历史 + 清空', () async {
      final card =
          const WorkCard(sourceKey: 's1', workId: 's1::w1', title: '夜航西行');
      await records.upsertSnapshot(card);
      await records.save(PlayRecord(
        workKey: card.workKey,
        sourceKey: card.sourceKey,
        episodeIndex: 0,
        positionSec: 30,
        durationSec: 100,
        updatedAt: DateTime.now(),
      ));
      final hist = await records.historyDetailed();
      expect(hist, hasLength(1));
      await records.clearAll();
      expect(await records.historyDetailed(), isEmpty);
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');

    test('备份导出导入往返', () async {
      final card =
          const WorkCard(sourceKey: 's1', workId: 's1::w1', title: '夜航西行');
      await favs.toggle(card);
      await records.upsertSnapshot(card);
      await records.save(PlayRecord(
        workKey: card.workKey,
        sourceKey: card.sourceKey,
        episodeIndex: 0,
        positionSec: 30,
        durationSec: 100,
        updatedAt: DateTime.now(),
      ));
      final text = await backup.exportAll();
      final db2 = StarDatabase.memory();
      final backup2 = DriftBackupCodec(
        db: db2,
        records: DriftPlayRecordStore(db2),
        favorites: DriftFavoriteStore(db2),
        sources: DriftSourceDefStore(db2),
        settings: DriftKeyValueStore(db2),
      );
      final stat = await backup2.importAll(text);
      expect(stat['favorites'], 1);
      expect(stat['records'], 1);
      await db2.close();
    }, skip: _sqliteAvailable ? false : '本机缺少 sqlite3');
  });
}
