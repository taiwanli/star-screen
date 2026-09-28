/// 本地存储抽象（docs/03 §6 / docs/05 §4.1）。
///
/// 表结构唯一事实来源：`db/schema.sql`（与 drift 表定义一一对应）。
/// 领域层只依赖本包接口，不感知 SQLite 细节。
library;

export 'src/crash_guard.dart';
export 'src/db/star_database.dart';
export 'src/download_service.dart';
export 'src/download_store.dart';
export 'src/drift_backup_codec.dart';
export 'src/drift_favorite_store.dart';
export 'src/drift_live_channel_store.dart';
export 'src/drift_play_record_store.dart';
export 'src/drift_source_def_store.dart';
export 'src/subscription_cache.dart';

/// KV 存储（app_setting 表：播放偏好、主题、启动页等）。
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// 导出/导入/同步共用的传输包（v0.9 局域网同步复用，docs/03 §6）。
abstract interface class BackupCodec {
  /// 全量导出为明文 JSON（加密后续支持）。
  Future<String> exportAll();

  /// 导入；返回导入条目统计（favorites/records/sources/settings）。
  Future<Map<String, int>> importAll(String jsonText);
}
