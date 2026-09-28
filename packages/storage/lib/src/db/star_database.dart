import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'star_database.g.dart';

/// 星映本地库（docs/03 §6 / packages/storage/db/schema.sql）。
/// 表结构与 schema.sql 一一对应；schema 变更必须两边同步并升 schemaVersion。
///
/// 9 张表：订阅 / 源定义 / 作品快照 / 播放记录 / 收藏夹 / 收藏 /
/// 直播频道 / 健康记录 / 应用设置。

@DataClassName('SubscriptionRow')
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // tvbox | warehouse | libretv | live
  TextColumn get url => text().nullable()();
  TextColumn get etag => text().nullable()();

  /// 最近一次订阅原文（刷新成功后回填，供离线回退与 304 协商，docs/13 B2）。
  IntColumn get fetchedAt => integer().nullable()();
  TextColumn get raw => text().nullable()();
}

@DataClassName('SourceDefRow')
class SourceDefs extends Table {
  TextColumn get key => text()();
  IntColumn get subId => integer().nullable().references(Subscriptions, #id)();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // cmsJson|cmsXml|xpathRule|drpyJs|alist|live|unsupported
  TextColumn get cmsVariant => text().withDefault(const Constant('none'))();
  TextColumn get endpoint => text().nullable()();
  TextColumn get extRaw => text().nullable()();
  TextColumn get extUrl => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();

  /// 仅引用记录，永不执行（docs/05 §10）
  TextColumn get jarRef => text().nullable()();

  BoolColumn get capsSearchable => boolean().withDefault(const Constant(true))();
  BoolColumn get capsQuickSearch =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get capsFilterable =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get capsChangeable =>
      boolean().withDefault(const Constant(true))();
  TextColumn get headers => text().nullable()(); // JSON
  IntColumn get timeoutSec => integer().nullable()();
  TextColumn get unsupportedReason => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get groupId => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('WorkSnapshotRow')
class WorkSnapshots extends Table {
  TextColumn get workKey => text()(); // sourceKey::workId
  TextColumn get sourceKey => text()();
  TextColumn get title => text()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get remarks => text().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get area => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get score => text().nullable()();
  TextColumn get raw => text().nullable()(); // 详情缓存 JSON（TTL 6h）

  @override
  Set<Column> get primaryKey => {workKey};
}

@DataClassName('PlayRecordRow')
class PlayRecords extends Table {
  TextColumn get workKey =>
      text().references(WorkSnapshots, #workKey, onDelete: KeyAction.cascade)();
  TextColumn get sourceKey => text()();
  IntColumn get episodeIndex => integer()();
  TextColumn get lineId => text().nullable()();
  IntColumn get positionSec => integer().withDefault(const Constant(0))();
  IntColumn get durationSec => integer().withDefault(const Constant(0))();

  /// 跨端同步以最后播放时间戳为准（docs/07 §4.5）
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {workKey};
}

@DataClassName('FavoriteFolderRow')
class FavoriteFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
}

@DataClassName('FavoriteRow')
class Favorites extends Table {
  TextColumn get workKey =>
      text().references(WorkSnapshots, #workKey, onDelete: KeyAction.cascade)();
  IntColumn get folderId =>
      integer().nullable().references(FavoriteFolders, #id)();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {workKey};
}

@DataClassName('LiveChannelRow')
class LiveChannels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  TextColumn get logo => text().nullable()();
  TextColumn get epgId => text().nullable()();
  IntColumn get tuneNo => integer().nullable()(); // 数字键换台
  IntColumn get sort => integer().withDefault(const Constant(0))();
}

@DataClassName('HealthRecordRow')
class HealthRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceKey => text().references(SourceDefs, #key,
      onDelete: KeyAction.cascade)();
  IntColumn get ts => integer()();
  IntColumn get latencyMs => integer().nullable()();
  BoolColumn get ok => boolean()();
  TextColumn get failStage => text().nullable()(); // probe|detail|play
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Subscriptions,
  SourceDefs,
  WorkSnapshots,
  PlayRecords,
  FavoriteFolders,
  Favorites,
  LiveChannels,
  HealthRecords,
  AppSettings,
])
class StarDatabase extends _$StarDatabase {
  StarDatabase(QueryExecutor executor) : super(executor);

  /// 内存库（测试）。
  StarDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
