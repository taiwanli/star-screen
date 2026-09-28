import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 手机首页：继续观看轨道（真实记录）+ 首个启用源的真实推荐流。
class HomePage extends StatelessWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;
  final VoidCallback onGoMine;

  const HomePage({
    super.key,
    required this.services,
    required this.onOpenDetail,
    required this.onGoMine,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SourceDef>>(
      future: services.enabledSources(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: StarColors.brand));
        }
        final sources = snap.data ?? const <SourceDef>[];
        if (snap.hasError || sources.isEmpty) {
          return _EmptySources(onGoMine: onGoMine);
        }
        final source = sources.where((s) => s.kind.hasAdapter).firstOrNull ?? sources.first;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // 继续观看（规范 6.5：置顶，副信息=第N集·剩余M分钟）
            FutureBuilder<List<ContinueItem>>(
              future: services.playRecordStore.continueWatchingDetailed(),
              builder: (context, cw) {
                final items = cw.data ?? const <ContinueItem>[];
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Text('继续观看',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => StarPoster(
                          title: items[i].title,
                          subtitle: items[i].subtitle,
                          shape: StarCardShape.landscape,
                          hueSeed: i,
                          progress: items[i].progress,
                          width: 168,
                          imageUrl: items[i].posterUrl,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // 推荐流（首个启用源）
            FutureBuilder<HomeFeed>(
              future: services.sourceFor(source).home(),
              builder: (context, feedSnap) {
                if (feedSnap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: CircularProgressIndicator(color: StarColors.brand)),
                  );
                }
                if (feedSnap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('「${source.name}」暂时不可用：${feedSnap.error}',
                        style:
                            const TextStyle(fontSize: 13, color: StarColors.ink3)),
                  );
                }
                final cards = feedSnap.data?.recommend ?? const <WorkCard>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('来自「${source.name}」的推荐',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          if (sources.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text('共 ${sources.length} 个源',
                                  style: const TextStyle(
                                      fontSize: 11, color: StarColors.ink4)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cards.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final card = cards[i];
                          return StarPoster(
                            title: card.title,
                            subtitle: card.remarks,
                            hueSeed: i,
                            width: 112,
                            imageUrl: card.posterUrl,
                            badgeText: card.remarks != null &&
                                    card.remarks!.contains('集')
                                ? card.remarks
                                : null,
                            onTap: () => onOpenDetail(source, card),
                          );
                        },
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

class _EmptySources extends StatelessWidget {
  final VoidCallback onGoMine;

  const _EmptySources({required this.onGoMine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_outlined, size: 44, color: StarColors.ink3),
            const SizedBox(height: 12),
            const Text('还没有内容源',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              '星映是播放器，不内置任何内容源 —— 请在「我的 → 源管理」\n接入自有合法内容源（TVBox 配置 / 苹果CMS 接口）。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: StarColors.ink3, height: 1.6),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: StarColors.brand),
              onPressed: onGoMine,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('去添加内容源'),
            ),
          ],
        ),
      ),
    );
  }
}
