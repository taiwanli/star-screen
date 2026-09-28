-- 星映 · 本地 SQLite schema（唯一事实来源；drift 表定义须与本文件保持一致）
-- 依据：docs/03-整体设计方案.md §6、docs/05-源管理引擎开发报告.md §4.1

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- 订阅（TVBox 单仓 / 多仓 / LibreTV / 直播源订阅）
CREATE TABLE IF NOT EXISTS subscription (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  kind        TEXT NOT NULL,             -- tvbox | warehouse | libretv | live
  url         TEXT,                      -- 远程地址（本地/粘贴为 NULL）
  etag        TEXT,
  fetched_at  INTEGER,
  raw         TEXT                       -- 原文缓存（TTL 6h，docs/05 §9）
);

-- 源定义（解析管线产物；解析器固化，合并永不覆盖 —— docs/05 §3 原则 1）
CREATE TABLE IF NOT EXISTS source_def (
  key                TEXT NOT NULL,
  sub_id             INTEGER REFERENCES subscription(id) ON DELETE CASCADE,
  name               TEXT NOT NULL,
  kind               TEXT NOT NULL,        -- cmsJson|cmsXml|xpathRule|drpyJs|alist|live|unsupported
  cms_variant        TEXT NOT NULL DEFAULT 'none',
  endpoint           TEXT,
  ext_raw            TEXT,
  ext_url            TEXT,
  source_url         TEXT,
  jar_ref            TEXT,                 -- 仅引用记录，永不执行（docs/05 §10）
  caps_searchable    INTEGER NOT NULL DEFAULT 1,
  caps_quick_search  INTEGER NOT NULL DEFAULT 1,
  caps_filterable    INTEGER NOT NULL DEFAULT 1,
  caps_changeable    INTEGER NOT NULL DEFAULT 1,
  headers            TEXT,                 -- JSON
  timeout_sec        INTEGER,
  unsupported_reason TEXT,
  enabled            INTEGER NOT NULL DEFAULT 1,
  sort               INTEGER NOT NULL DEFAULT 0,
  group_id           TEXT,                   -- 多仓导入时 = 仓库名（docs/09 M2-4）
  PRIMARY KEY (key)
);

-- 作品快照（收藏/历史存快照，源失效仍可见 —— docs/03 §6）
CREATE TABLE IF NOT EXISTS work_snapshot (
  work_key    TEXT PRIMARY KEY,            -- sourceKey::workId
  source_key  TEXT NOT NULL,
  title       TEXT NOT NULL,
  poster_path TEXT,                        -- 磁盘缓存引用
  remarks     TEXT,
  year        TEXT,
  area        TEXT,
  genre       TEXT,
  score       TEXT,
  raw         TEXT                         -- 原始 JSON（详情缓存 TTL 6h）
);
CREATE INDEX IF NOT EXISTS idx_snapshot_source ON work_snapshot(source_key);

-- 观看记录（断点续播唯一事实源；5 秒节流写库 —— docs/03 §6）
CREATE TABLE IF NOT EXISTS play_record (
  work_key      TEXT PRIMARY KEY REFERENCES work_snapshot(work_key) ON DELETE CASCADE,
  source_key    TEXT NOT NULL,
  episode_index INTEGER NOT NULL,
  line_id       TEXT,
  position_sec  INTEGER NOT NULL DEFAULT 0,
  duration_sec  INTEGER NOT NULL DEFAULT 0,
  updated_at    INTEGER NOT NULL           -- 跨端同步以最后播放时间戳为准
);
CREATE INDEX IF NOT EXISTS idx_record_updated ON play_record(updated_at DESC);

-- 收藏夹与收藏
CREATE TABLE IF NOT EXISTS favorite_folder (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  sort INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS favorite (
  work_key    TEXT PRIMARY KEY REFERENCES work_snapshot(work_key) ON DELETE CASCADE,
  folder_id   INTEGER REFERENCES favorite_folder(id) ON DELETE SET NULL,
  created_at  INTEGER NOT NULL
);

-- 直播频道（tuneNo 支持数字键换台，docs/07 §4）
CREATE TABLE IF NOT EXISTS live_channel (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id  TEXT NOT NULL,                 -- #genre# 分组 / m3u group-title
  name      TEXT NOT NULL,
  url       TEXT NOT NULL,
  logo      TEXT,
  epg_id    TEXT,
  tune_no   INTEGER,
  sort      INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_live_group ON live_channel(group_id);

-- 健康记录（滑动窗口评分，docs/05 §8）
CREATE TABLE IF NOT EXISTS health_record (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  source_key  TEXT NOT NULL REFERENCES source_def(key) ON DELETE CASCADE,
  ts          INTEGER NOT NULL,
  latency_ms  INTEGER,
  ok          INTEGER NOT NULL,
  fail_stage  TEXT                         -- probe|detail|play
);
CREATE INDEX IF NOT EXISTS idx_health_source ON health_record(source_key, ts DESC);

-- 应用设置（KV）
CREATE TABLE IF NOT EXISTS app_setting (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL                      -- JSON
);
