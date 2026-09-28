import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import 'src/app_services.dart';
import 'src/http_overrides.dart';
import 'src/pages/category_page.dart';
import 'src/pages/detail_page.dart';
import 'src/pages/search_page.dart';
import 'src/pages/settings_page.dart';
import 'src/widgets/focus_widgets.dart';
import 'src/widgets/tv_focus_engine.dart';

void main() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 32 << 20;
  CrashGuard.install(baseDir: Directory.systemTemp.path);
  WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    installStarHttpOverrides(); // 视频内核（缺失会导致无法播放）
  // TV 端焦点驱动：全屏方向键遍历（docs/07 §4）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const StarApp());
}

/// TV 端壳：顶部固定栏目 + 书架横向轨道 + 5% 安全区（48px）。
class StarApp extends StatelessWidget {
  const StarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = StarTokens.forFormFactor(StarFormFactor.tv);
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final services = await AppServices.load();
    services.startPeriodicHealthCheck();
    if (mounted) setState(() => _services = services);
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return Scaffold(
      body: services == null
          ? const Center(child: _Wordmark())
          : TvShell(services: services),
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
          radius: 24,
          backgroundColor: StarColors.brand,
          child: Text('星', style: TextStyle(color: Colors.white, fontSize: 26)),
        ),
        SizedBox(width: 16),
        Text('星映', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class TvShell extends StatefulWidget {
  final AppServices services;

  const TvShell({super.key, required this.services});

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  String _nav = '首页';
  int _reloadTick = 0;

  void _openDetail(SourceDef def, WorkCard card) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailPage(services: widget.services, def: def, card: card),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = StarTheme.of(context).sizes;
    return Scaffold(
      // 5% overscan 安全区：所有内容与焦点框不得越界（规范 §5.3）
      body: TvFocusScope(
        pageKey: 'tv-shell/$_nav',
        child: Padding(
          padding: EdgeInsets.all(s.safeArea),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopNav(current: _nav, onSelect: (v) => setState(() => _nav = v)),
              const SizedBox(height: 24),
              Expanded(child: _content()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return switch (_nav) {
      '首页' => _HomeBody(
          services: widget.services,
          reloadTick: _reloadTick,
          onOpenDetail: _openDetail,
        ),
      '点播' => TvCategoryPage(
          services: widget.services,
          onOpenDetail: _openDetail,
        ),
      '搜索' => TvSearchPage(
          services: widget.services,
          onOpenDetail: _openDetail,
        ),
      '设置' => SettingsPage(
          services: widget.services,
          onChanged: () => setState(() => _reloadTick++),
        ),
      _ => Center(
          child: Text('「$_nav」随里程碑接入（docs/09）',
              style: const TextStyle(fontSize: 24, color: StarColors.ink4)),
        ),
    };
  }
}

class _TopNav extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;

  const _TopNav({required this.current, required this.onSelect});

  static const _items = ['首页', '点播', '直播', '搜索', '我的', '设置'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _Wordmark(),
        const SizedBox(width: 40),
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TvFocusChip(
                label: item,
                focusId: 'nav-$item',
                isNavSelected: item == current,
                onSelect: () => onSelect(item)),
          ),
      ],
    );
  }
}

class _HomeBody extends StatelessWidget {
  final AppServices services;
  final int reloadTick;
  final void Function(SourceDef, WorkCard) onOpenDetail;

  const _HomeBody({
    required this.services,
    required this.reloadTick,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SourceDef>>(
      key: ValueKey(reloadTick),
      future: services.enabledSources(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: StarColors.brand));
        }
        final sources = snap.data ?? const <SourceDef>[];
        if (sources.isEmpty) {
          return const Center(
            child: Text(
                '还没有内容源 —— 请在「设置 → 源管理」接入自有合法内容源\n'
                '（TVBox 配置 / 苹果CMS 接口 / 本地文件路径）',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, color: StarColors.ink3, height: 1.6)),
          );
        }
        final source = sources.where((s) => s.kind.hasAdapter).firstOrNull ?? sources.first;
        return ListView(
          children: [
            // 继续观看轨道（真实记录；副信息=第N集·剩余M分钟）
            FutureBuilder<List<ContinueItem>>(
              future: services.playRecordStore.continueWatchingDetailed(),
              builder: (context, cw) {
                final items = cw.data ?? const <ContinueItem>[];
                if (items.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text('继续观看',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(
                        height: 364,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 32),
                          itemBuilder: (_, i) => TvFocusCard(
                            title: items[i].title,
                            subtitle: items[i].subtitle,
                            progress: items[i].progress,
                            hueSeed: i,
                            imageUrl: items[i].posterUrl,
                            focusId: 'cw-$i',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // 推荐轨道（首个启用源）
            FutureBuilder<HomeFeed>(
              future: services.sourceFor(source).home(),
              builder: (context, feedSnap) {
                if (feedSnap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(color: StarColors.brand));
                }
                if (feedSnap.hasError) {
                  return Text('「${source.name}」暂时不可用：${feedSnap.error}',
                      style:
                          const TextStyle(fontSize: 22, color: StarColors.ink3));
                }
                final cards = feedSnap.data?.recommend ?? const <WorkCard>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('来自「${source.name}」的推荐',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(
                      height: 364,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: cards.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 32),
                        itemBuilder: (_, i) => TvFocusCard(
                          title: cards[i].title,
                          subtitle: cards[i].remarks ?? '',
                          hueSeed: i,
                          imageUrl: cards[i].posterUrl,
                          focusId: 'rec-$i',
                          onTap: () => onOpenDetail(source, cards[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
