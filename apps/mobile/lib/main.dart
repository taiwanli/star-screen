import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import 'src/app_services.dart';
import 'src/http_overrides.dart';
import 'src/pages/category_page.dart';
import 'src/pages/detail_page.dart';
import 'src/pages/home_page.dart';
import 'src/pages/mine_page.dart';
import 'src/pages/search_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    installStarHttpOverrides(); // 视频内核（缺失会导致无法播放）
  PaintingBinding.instance.imageCache.maximumSizeBytes = 32 << 20;
  CrashGuard.install(baseDir: Directory.systemTemp.path);
  runApp(const StarApp());
}

/// 手机端壳（docs/07 §3）：底部标签栏 4 项。
class StarApp extends StatelessWidget {
  const StarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = StarTokens.forFormFactor(StarFormFactor.mobile);
    return StarTheme(
      tokens: tokens,
      child: MaterialApp(
        title: '星映',
        theme: starThemeData(tokens),
        home: const _ServicesBootstrap(),
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text('初始化失败：$_error',
                    style: const TextStyle(color: StarColors.bad, fontSize: 13)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _init, child: const Text('重试')),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(color: StarColors.brand),
                ),
            ],
          ),
        ),
      );
    }
    return MobileShell(services: services);
  }
}

class MobileShell extends StatefulWidget {
  final AppServices services;

  const MobileShell({super.key, required this.services});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _tab = 0;

  static const _tabs = <String, IconData>{
    '首页': Icons.home_outlined,
    '分类': Icons.grid_view_outlined,
    '搜索': Icons.search,
    '我的': Icons.person_outline,
  };

  void _openDetail(SourceDef def, WorkCard card) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailPage(services: widget.services, def: def, card: card),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: StarColors.page,
        surfaceTintColor: Colors.transparent,
        title: Text(_tabs.keys.elementAt(_tab),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: StarColors.ink)),
      ),
      body: switch (_tab) {
        0 => HomePage(
            services: widget.services,
            onOpenDetail: _openDetail,
            onGoMine: () => setState(() => _tab = 3),
          ),
        1 => CategoryPage(
            services: widget.services,
            onOpenDetail: _openDetail,
          ),
        2 => SearchPage(services: widget.services, onOpenDetail: _openDetail),
        3 => MinePage(
            services: widget.services,
            onOpenDetail: _openDetail,
          ),
        _ => Center(
            child: Text('「${_tabs.keys.elementAt(_tab)}」随里程碑接入（docs/09）',
                style: const TextStyle(color: StarColors.ink4)),
          ),
      },
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: StarColors.surface,
          indicatorColor: StarColors.brandSoft,
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? StarColors.brandHi
                  : StarColors.ink4)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? StarColors.brandHi
                  : StarColors.ink4)),
        ),
        child: NavigationBar(
          height: 80,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            for (final e in _tabs.entries)
              NavigationDestination(icon: Icon(e.value, size: 24), label: e.key),
          ],
        ),
      ),
    );
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
        Text('星映', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
