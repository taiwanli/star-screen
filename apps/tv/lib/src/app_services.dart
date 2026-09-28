import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_lan/star_lan.dart';

import 'flutter_js_runtime.dart';
import 'jar_host.dart';

/// TV 端服务装配（与手机/桌面同构；数据库位于应用支持目录）。
/// 测试环境（FLUTTER_TEST）使用内存库。
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
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/StarScreen')
        ..createSync(recursive: true);
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
    final jarHost = MethodChannelJarHost();
    final lan = LanBridge(
      deviceName: '星映·TV',
      deviceId: 'tv-${_stableDeviceId()}',
      backup: backup,
      downloads: downloads,
      onPlayPush: (push) async {
        // docs/13 B1：接收端最小承接 —— 推片落下载队列，UI 由「设置 → 局域网」查看。
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

  /// drpy 源实例缓存 —— QuickJS 运行时创建有成本（与桌面同构）。
  final Map<String, DrpyTemplateSource> _drpyCache = {};

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

  /// 把已启用源构建为引擎可用实例列表（聚合搜索/健康度共用）。
  List<VideoSource> buildVideoSources(List<SourceDef> defs) => [
        for (final def in defs)
          if (def.kind.isSupported) sourceFor(def),
      ];

  final HealthMonitor healthMonitor = HealthMonitor();
  Timer? _healthTimer;

  /// 周期 L2 探活（测试环境跳过）。
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

  /// 周期刷新远程订阅原文：对每个缓存过的订阅重发一次带 ETag 的 GET。
  /// 命中 304 则跳过（零带宽消耗）；200 时重新解析并注册（docs/13 B2 收尾）。
  /// 测试环境跳过；单次刷新失败不影响其他订阅。
  Future<int> refreshSubscriptions() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return 0;
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



  /// ETag 订阅缓存（docs/13 B2 共享层，三端共用 [SubscriptionCache]）。
  late final SubscriptionCache subCache = SubscriptionCache(db);

  Future<ParseReport> importFromRef(String ref) async {
    // docs/13 B2 共享层：ETag 协商 + 304 回退缓存原文
    final cached = await subCache.find(ref);
    var result = await fetcher.fetchSubscription(ref, etag: cached?.etag);
    if (result.notModified && cached != null && cached.raw != null) {
      result = FetchResult(url: result.url, statusCode: result.statusCode, etag: result.etag, body: cached.raw!, headers: result.headers, notModified: true);
    }
    if (!result.notModified) {
      await subCache.upsert(ref, result.etag, result.body);
    }
    _drpyCache.clear(); // 源定义可能变化，drpy 沙箱实例全部重建
    // 本地目录批量导入（LocalFeedPolicy）
    final localDirCheck = LocalFeedPolicy.resolvePath(ref);
    if (localDirCheck != null && Directory(localDirCheck).existsSync()) {
      final batch = fetcher.fetchDirectory(localDirCheck);
      final merged = <SourceDef>[];
      final issues = <ParseIssue>[];
      for (final read in batch.reads) {
        try {
          if (StarRuleParser.looksLikeStarRule(read.body)) {
            final sr = StarRuleImporter.toParseReport(
              read.body,
              baseUrl: read.uri,
            );
            merged.addAll(sr.sources);
            issues.addAll(sr.issues);
          } else {
            var rep = TvBoxConfigParser.parse(raw: read.body, baseUrl: read.uri);
            final (defs, convN) = convertXpathDefs(rep.sources);
            merged.addAll(defs);
            issues.addAll(rep.issues);
          }
        } on Object catch (e) {
          issues.add(ParseIssue('本地文件失败：${read.path} — $e'));
        }
      }
      for (final f in batch.failed) {
        issues.add(ParseIssue('本地文件失败：${f.path} — ${f.reason}'));
      }
      final report = ParseReport(
        warehouses: const [],
        sources: merged,
        lives: const [],
        issues: issues,
      );
      await registry.applyReport(report);
      _drpyCache.clear();
      return report;
    }
    // starrule://import 深链（docs/18 §8）
    if (StarRuleDeepLink.isImportLink(ref)) {
      final parsedLink = StarRuleDeepLink.parse(ref);
      if (parsedLink.inline != null && parsedLink.inline!.isNotEmpty) {
        final sr = StarRuleImporter.toParseReport(parsedLink.inline!);
        await registry.applyReport(sr);
        return sr;
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
      return srReport;
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
    await registry.applyReport(report);
    return report;
  }
}

String _stableDeviceId() {
  try {
    return Platform.localHostname;
  } on Object {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
