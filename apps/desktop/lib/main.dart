import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:star_storage/star_storage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import 'src/app_services.dart';
import 'src/http_overrides.dart';
import 'src/pages/category_page.dart';
import 'src/pages/detail_page.dart';
import 'src/pages/home_page.dart';
import 'src/pages/lan_page.dart';
import 'src/pages/library_page.dart';
import 'src/pages/live_page.dart';
import 'src/pages/search_page.dart';
import 'src/pages/sources_page.dart';
import 'src/theme_notifier.dart';
import 'src/window_controls.dart';

void main() {
  final guard = CrashGuard.install(baseDir: _dataDir());
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized(); // 视频内核
    installStarHttpOverrides(); // 图片/视频证书与 UA
    PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;
    runApp(const StarApp());
  }, (e, s) {
    guard.record('zone', e.toString(), stack: s.toString());
  });
}

String _dataDir() {
  final base = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
  return '$base${Platform.pathSeparator}StarScreen';
}

/// 桌面端壳（docs/07 §3）：左侧导航 240px + 顶栏 56px。
class StarApp extends StatelessWidget {
  const StarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = StarTokens.forFormFactor(StarFormFactor.desktop);
    return StarTheme(
      tokens: tokens,
      child: ValueListenableBuilder<Brightness>(
        valueListenable: themeNotifier,
        builder: (context, brightness, _) => MaterialApp(
          title: '星映',
          theme: starThemeData(tokens),
          home: const _ServicesBootstrap(),
        ),
      ),
    );
  }
}

class _ServicesBootstrap extends StatefulWidget {
  const _ServicesBootstrap();

  @override
  State<_ServicesBootstrap> createState() => _ServicesBootstrapState();
}

class _ServicesBootstrapState extends State<_ServicesBootstrap> {
  AppServices? _services;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        await windowManager.ensureInitialized();
        const options = WindowOptions(
          size: Size(1280, 800),
          minimumSize: Size(960, 600),
          title: '星映',
          titleBarStyle: TitleBarStyle.hidden,
          backgroundColor: Colors.transparent,
        );
        await windowManager.waitUntilReadyToShow(options, () async {
          await windowManager.setResizable(true);
          await windowManager.setMovable(true);
          await windowManager.show();
          await windowManager.focus();
        });
      } on Object {
        // 窗口 API 不可用时忽略
      }
    }
    setState(() => _error = null);
    try {
      final services = await AppServices.load();
      services.startPeriodicHealthCheck();
      if (mounted) setState(() => _services = services);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Wordmark(),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text('初始化失败：$_error',
                    style: const TextStyle(color: StarColors.bad)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _init, child: const Text('重试')),
              ] else
                const CircularProgressIndicator(color: StarColors.brand),
            ],
          ),
        ),
      );
    }
    return DesktopShell(services: services);
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _navItems = <_NavItem>[
  _NavItem(Icons.home_outlined, '首页'),
  _NavItem(Icons.grid_view_outlined, '分类'),
  _NavItem(Icons.search, '搜索'),
  _NavItem(Icons.cast_outlined, '直播'),
  _NavItem(Icons.favorite_border, '我的'),
  _NavItem(Icons.storage_outlined, '源管理'),
];

class DesktopShell extends StatefulWidget {
  final AppServices services;

  const DesktopShell({super.key, required this.services});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;

  /// 源变化后刷新首页数据面。
  void _reloadSources() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = StarTheme.of(context).sizes;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: StarColors.glass,
              border: const Border(bottom: BorderSide(color: StarColors.line)),
              boxShadow: [
                BoxShadow(
                  color: StarColors.neuDark.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            // 顶栏可拖拽移动窗口
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const _Wordmark(),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        height: s.controlHeightMd,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: StarColors.surface,
                          borderRadius: BorderRadius.circular(s.radiusLg),
                          border: Border.all(color: StarColors.line),
                          boxShadow: [
                            BoxShadow(
                              color: StarColors.neuDark.withValues(alpha: 0.2),
                              offset: const Offset(2, 2),
                              blurRadius: 6,
                            ),
                            BoxShadow(
                              color: StarColors.neuLight.withValues(alpha: 0.9),
                              offset: const Offset(-2, -2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Text('搜索',
                            style:
                                TextStyle(color: StarColors.ink3, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const WindowControls(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: StarColors.glass,
                    border: Border(right: BorderSide(color: StarColors.line)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (var i = 0; i < _navItems.length; i++)
                        _NavTile(
                          item: _navItems[i],
                          active: i == _index,
                          onTap: () => setState(() => _index = i),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(s.pageMargin),
                    child: _content(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return switch (_index) {
      0 => HomePage(
          services: widget.services,
          onOpenDetail: _openDetail,
          onGoSources: () => setState(() => _index = 5),
        ),
      1 => CategoryPage(
          services: widget.services,
          onOpenDetail: _openDetail,
        ),
      2 => SearchPage(services: widget.services, onOpenDetail: _openDetail),
      3 => LivePage(services: widget.services),
      4 => LibraryPage(
          services: widget.services,
          onOpenDetail: _openDetail,
          onOpenLan: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LanPage(services: widget.services),
              )),
        ),
      5 => SourcesPage(services: widget.services, onChanged: _reloadSources),
      _ => Center(
          child: Text('「${_navItems[_index].label}」随里程碑接入（docs/09）',
              style: const TextStyle(color: StarColors.ink4)),
        ),
    };
  }

  void _openDetail(SourceDef def, WorkCard card) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailPage(services: widget.services, def: def, card: card),
    ));
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: StarColors.brand,
          child: Text('星', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        SizedBox(width: 10),
        Text('星映',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: active ? StarColors.brandSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? StarColors.brand.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: StarColors.neuDark.withValues(alpha: 0.28),
                        offset: const Offset(3, 3),
                        blurRadius: 8,
                      ),
                      BoxShadow(
                        color: StarColors.neuLight.withValues(alpha: 0.9),
                        offset: const Offset(-3, -3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color: active ? StarColors.brand : StarColors.ink3),
                const SizedBox(width: 12),
                Text(item.label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? StarColors.ink : StarColors.ink2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
