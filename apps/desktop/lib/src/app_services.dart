import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:star_domain/star_domain.dart';

import 'package:star_plugins/star_plugins.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_lan/star_lan.dart';

import 'flutter_js_runtime.dart';
import 'jar_host.dart';

/// 桌面端服务装配（docs/03 §2：基础设施在启动时注入领域层）。
///
/// 数据库位置：`%APPDATA%/StarScreen/star.db`；测试环境（FLUTTER_TEST）
/// 使用内存库，避免测试污染真实数据。
class AppServices {
  final StarDatabase db;
  final SourceRegistry registry;
  final FeedFetcher fetcher;
  final DriftPlayRecordStore playRecordStore;
  final DriftLiveChannelStore liveStore;
  final DriftFavoriteStore favoriteStore;
  final DriftKeyValueStore kv;
  final DriftBackupCodec backup;
  final DownloadStore downloads;
  final JarSpiderHost jarHost;
  final LanBridge lan;

  AppServices._({
    required this.db,
    required this.registry,
    required this.fetcher,
    required this.playRecordStore,
    required this.liveStore,
    required this.favoriteStore,
    required this.kv,
    required this.backup,
    required this.downloads,
    required this.jarHost,
    required this.lan,
  });

  static Future<AppServices> load() async {
    final StarDatabase db;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      db = StarDatabase.memory();
    } else {
      final base = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
      final dir = Directory('$base/StarScreen')..createSync(recursive: true);
      db = StarDatabase(
        NativeDatabase.createInBackground(File('${dir.path}/star.db')),
      );
    }
    final playRecordStore = DriftPlayRecordStore(db);
    final favoriteStore = DriftFavoriteStore(db);
    final sourceStore = DriftSourceDefStore(db);
    final kv = DriftKeyValueStore(db);
    final backup = DriftBackupCodec(
      db: db,
      records: playRecordStore,
      favorites: favoriteStore,
      sources: sourceStore,
      settings: kv,
    );
    final downloads = DownloadStore(kv);
    final jarHost = DesktopJvmJarHost();
    final lan = LanBridge(
      deviceName: '星映·桌面',
      deviceId: 'desktop-${_stableDeviceId()}',
      backup: backup,
      downloads: downloads,
      onPlayPush: (push) async {
        // docs/13 B1：接收端最小承接 —— 推片落下载队列，UI 由「局域网」页查看。
        await downloads.enqueue(title: push.title, url: push.url);
      },
      kv: kv,
    );
    final services = AppServices._(
      db: db,
      registry: SourceRegistry(store: sourceStore),
      fetcher: FeedFetcher(),
      playRecordStore: playRecordStore,
      liveStore: DriftLiveChannelStore(db),
      favoriteStore: favoriteStore,
      kv: kv,
      backup: backup,
      downloads: downloads,
      jarHost: jarHost,
      lan: lan,
    );
    try {
      final hs = await kv.getString('healthState');
      if (hs != null) {
        services.healthMonitor.importState(jsonDecode(hs) as Map<String, dynamic>);
      }
    } on Object {
      // 健康度快照不可读（测试环境无 sqlite 等）不影响启动
    }
    return services;
  }

  /// 受支持且已启用的源（聚合浏览/搜索的数据面）。
  Future<List<SourceDef>> enabledSources() => registry.enabled();

  /// 默认首页源（FongMi/TV home 字段；KV `homeSourceKey`）。
  static const homeSourceKvKey = 'homeSourceKey';

  Future<void> setHomeSourceKey(String key) => kv.setString(homeSourceKvKey, key);

  Future<SourceDef?> pickHomeSource() async {
    final all = await registry.enabled();
    final adaptable = [
      for (final s in all)
        if (s.kind.hasAdapter) s,
    ];
    if (adaptable.isEmpty) return null;
    final saved = await kv.getString(homeSourceKvKey);
    if (saved != null) {
      for (final s in adaptable) {
        if (s.key == saved) return s;
      }
    }
    return adaptable.first;
  }

  Future<PlayerEngineType> playerEngine() async {
    final raw = await kv.getString('playerEngine');
    return PlayerEnginePref.parse(raw);
  }

  Future<void> setPlayerEngine(PlayerEngineType t) =>
      kv.setString('playerEngine', PlayerEnginePref.nameOf(t));

  /// drpy 源实例缓存 —— QuickJS 运行时创建有成本，且同一源的规则/沙箱
  /// 可跨页面复用；导入订阅时失效（_drpyCache.clear）。
  final Map<String, DrpyTemplateSource> _drpyCache = {};

  /// 按固化的解析器类型创建源实例（docs/05 §3「解析器固化」）。
  /// drpy 源带 QuickJS 工厂：纯模板源原生执行，js: 内联源走沙箱（docs/09 M3-4）。
  VideoSource sourceFor(SourceDef def) => switch (def.kind) {
        SourceKind.cmsJson => CmsJsonSource(def: def),
        SourceKind.cmsXml => CmsXmlSource(def: def),
        SourceKind.spiderJar => JarSpiderSource(def: def, host: jarHost),
        SourceKind.starRule => StarRuleSource.fromDef(def),
        SourceKind.drpyJs => _drpyCache.putIfAbsent(
            def.key,
            () => DrpyTemplateSource(def: def, jsFactory: FlutterJsRuntime.new),
          ),
        _ => throw StateError('该源类型暂无适配器：${def.kind.name}'),
      };

  /// ETag 订阅缓存（docs/13 B2 共享层，三端共用 [SubscriptionCache]）。
  late final SubscriptionCache subCache = SubscriptionCache(db);

  /// 导入订阅：URL / 本地文件 → 获取 → 解析 → 注册。
  /// 多仓自动展开（一层，上限 8 个子仓），子仓归组到仓库名（docs/09 M2-4）。
  /// ETag 协商（docs/13 B2）：按 ref 查最近一次已缓存订阅（etag + raw），
  /// 服务端返回 304 时直接用缓存原文，避免全量重拉。
  Future<ImportSummary> importFromRef(String ref) async {
    final cached = await subCache.find(ref);
    var result = await fetcher.fetchSubscription(ref, etag: cached?.etag);
    if (result.notModified && cached != null && cached.raw != null) {
      // 304：服务端确认未变化，使用本地缓存原文
      result = FetchResult(url: result.url, statusCode: result.statusCode, etag: result.etag, body: cached.raw!, headers: result.headers, notModified: true);
    }
    if (!result.notModified) {
      // 200 成功：回填 ETag + 原文，供下次 304 协商（docs/13 B2）
      await subCache.upsert(ref, result.etag, result.body);
    }
    _drpyCache.clear(); // 源定义可能变化，drpy 沙箱实例全部重建
    // 本地目录批量导入（LocalFeedPolicy）
    final localDirCheck = LocalFeedPolicy.resolvePath(ref);
    if (localDirCheck != null && Directory(localDirCheck).existsSync()) {
      final batch = fetcher.fetchDirectory(localDirCheck);
      var sites = 0;
      var unsupported = 0;
      final failed = <String>[
        for (final f in batch.failed) '${f.path.split(Platform.pathSeparator).last}: ${f.reason}',
      ];
      for (final read in batch.reads) {
        try {
          if (StarRuleParser.looksLikeStarRule(read.body)) {
            final sr = StarRuleImporter.toParseReport(
              read.body,
              baseUrl: read.uri,
            );
            await registry.applyReport(sr);
            sites += sr.sources.length;
            unsupported += sr.countOf(SourceKind.unsupported);
          } else {
            var rep = TvBoxConfigParser.parse(raw: read.body, baseUrl: read.uri);
            final (defs, convN) = convertXpathDefs(rep.sources);
            if (convN > 0) {
              rep = ParseReport(
                warehouses: rep.warehouses,
                sources: defs,
                lives: rep.lives,
                issues: [...rep.issues],
                spiderRef: rep.spiderRef,
                adFilters: rep.adFilters,
                playFlags: rep.playFlags,
                homeSiteKey: rep.homeSiteKey,
              );
            }
            await registry.applyReport(rep);
            sites += rep.sources.length;
            unsupported += rep.countOf(SourceKind.unsupported);
          }
        } on Object catch (e) {
          failed.add('${read.path}: $e');
        }
      }
      _drpyCache.clear();
      return _importSummaryOfDir(batch, sites, unsupported, failed);
    }
    // starrule://import 深链（docs/18 §8）
    if (StarRuleDeepLink.isImportLink(ref)) {
      final parsedLink = StarRuleDeepLink.parse(ref);
      if (parsedLink.inline != null && parsedLink.inline!.isNotEmpty) {
        final sr = StarRuleImporter.toParseReport(parsedLink.inline!);
        await registry.applyReport(sr);
        await _importLiveGroups(sr);
        return ImportSummary(
          configs: 1,
          sites: sr.sources.length,
          unsupported: sr.countOf(SourceKind.unsupported),
        );
      }
      if (parsedLink.url != null && parsedLink.url!.isNotEmpty) {
        final r2 = await fetcher.fetchSubscription(parsedLink.url!);
        await subCache.upsert(ref, r2.etag, r2.body);
        result = r2;
      }
    }
    // StarRule（docs/17）优先识别：三端统一源规则
    if (StarRuleParser.looksLikeStarRule(result.body)) {
      final srReport = StarRuleImporter.toParseReport(result.body, baseUrl: result.url);
      await registry.applyReport(srReport);
      await _importLiveGroups(srReport);
      return ImportSummary(
        configs: 1,
        sites: srReport.sources.length,
        unsupported: srReport.countOf(SourceKind.unsupported),
      );
    }
    var report = TvBoxConfigParser.parse(raw: result.body, baseUrl: result.url);
    // XPath 规则源自动转译为 StarRule（docs/17 §7.3）
    final (convDefs, convN) = convertXpathDefs(report.sources);
    if (convN > 0) {
      report = ParseReport(
        warehouses: report.warehouses,
        sources: convDefs,
        lives: report.lives,
        issues: [
          ...report.issues,
          ParseIssue('已自动转译 $convN 个 XPath 规则源为 StarRule'),
        ],
        spiderRef: report.spiderRef,
        adFilters: report.adFilters,
        playFlags: report.playFlags,
        homeSiteKey: report.homeSiteKey,
      );
    }

    if (!report.isWarehouseList) {
      await registry.applyReport(report);
      await _importLiveGroups(report);
      return ImportSummary(
        configs: 1,
        sites: report.sources.length,
        unsupported: report.countOf(SourceKind.unsupported),
      );
    }

    var configs = 0;
    var sites = 0;
    var unsupported = 0;
    final failed = <String>[];
    for (final warehouse in report.warehouses.take(8)) {
      try {
        final sub = await fetcher.fetchSubscription(warehouse.url);
        final subReport =
            TvBoxConfigParser.parse(raw: sub.body, baseUrl: Uri.parse(warehouse.url));
        await registry.applyReport(subReport, groupId: warehouse.name);
        configs++;
        sites += subReport.sources.length;
        unsupported += subReport.countOf(SourceKind.unsupported);
      } on Object {
        failed.add(warehouse.name);
      }
    }
    return ImportSummary(
      configs: configs,
      sites: sites,
      unsupported: unsupported,
      failedWarehouses: failed,
    );
  }

  /// 导入订阅中的直播组（上限 4 个）：拉取频道表 → LiveParser 解析 → 落库。
  /// 直播源失效不阻断配置导入。
  Future<void> _importLiveGroups(ParseReport report) async {
    for (final live in report.lives.take(4)) {
      try {
        final sub = await fetcher.fetchSubscription(live.url);
        final parsed = LiveParser.parse(sub.body);
        if (parsed.channels.isNotEmpty) {
          await liveStore.replaceAll(parsed.channels);
        }
      } on Object {
        // 直播源失效不影响点播源导入
      }
    }
  }

  /// 把已启用源构建为引擎可用实例列表（聚合搜索/健康度/换源共用）。
  List<VideoSource> buildVideoSources(List<SourceDef> defs) => [
        for (final def in defs)
          if (def.kind.isSupported) sourceFor(def),
      ];

  final HealthMonitor healthMonitor = HealthMonitor();
  Timer? _healthTimer;

  /// 周期 L2 探活（默认每 2 小时；测试环境跳过，docs/09 M2-3）。
  void startPeriodicHealthCheck({Duration every = const Duration(hours: 2)}) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(every, (_) async {
      final defs = await registry.enabled();
      await healthMonitor.probeAll(buildVideoSources(defs));
      await kv.setString('healthState', jsonEncode(healthMonitor.exportState()));
      // docs/13 B2 收尾：探活同时刷新远程订阅（带 ETag，304 零消耗）
      await refreshSubscriptions();
    });
  }

  /// 周期刷新远程订阅原文：对每个缓存过的订阅重发带 ETag 的 GET。
  /// 命中 304 则跳过（零带宽消耗）；200 时重新解析并注册（docs/13 B2 收尾）。
  /// 返回本次实际重新解析的订阅数。
  Future<int> refreshSubscriptions() async {
    final subs = await db.select(db.subscriptions).get();
    var refreshed = 0;
    for (final s in subs) {
      if (s.url == null) continue;
      try {
        final res = await fetcher.fetchSubscription(s.url!, etag: s.etag);
        if (res.notModified) continue; // 304：内容未变，无需重解析
        final report =
            TvBoxConfigParser.parse(raw: res.body, baseUrl: res.url);
        await registry.applyReport(report);
        await subCache.upsert(s.url!, res.etag, res.body);
        refreshed++;
      } on Object {
        // 单订阅失效不影响其他订阅
      }
    }
    return refreshed;
  }

  Future<void> disposeServices() async {
    _healthTimer?.cancel();
    for (final source in _drpyCache.values) {
      source.disposeRuntime();
    }
    _drpyCache.clear();
    await lan.dispose();
    await db.close();
  }
}

/// 导入结果摘要（多仓展开后聚合统计）。

  ImportSummary _importSummaryOfDir(
    LocalDirReadResult batch,
    int sites,
    int unsupported,
    List<String> failed,
  ) {
    return ImportSummary(
      configs: batch.reads.length,
      sites: sites,
      unsupported: unsupported,
      failedWarehouses: failed,
    );
  }

class ImportSummary {
  final int configs;
  final int sites;
  final int unsupported;
  final List<String> failedWarehouses;

  const ImportSummary({
    required this.configs,
    required this.sites,
    required this.unsupported,
    this.failedWarehouses = const [],
  });
}

String _stableDeviceId() {
  try {
    return Platform.localHostname;
  } on Object {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
