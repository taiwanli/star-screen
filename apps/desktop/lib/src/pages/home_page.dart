import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 首页 v2（docs/19 P0）：Hero 续播条 + 横滑行片单，告别均质网格。
/// 对标 Infuse 片墙 + Netflix 行结构；皮肤仍为液态玻璃/新拟态。
class HomePage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;
  final VoidCallback onGoSources;

  const HomePage({
    super.key,
    required this.services,
    required this.onOpenDetail,
    required this.onGoSources,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<SourceDef>> _sources;
  Future<HomeFeed>? _feed;
  SourceDef? _source;

  @override
  void initState() {
    super.initState();
    _sources = widget.services.enabledSources();
    _feed = _loadFeed();
  }

  Future<HomeFeed>? _loadFeed() {
    return _sources.then((list) async {
      if (list.isEmpty) return const HomeFeed(recommend: []);
      final src = await widget.services.pickHomeSource();
      if (src == null) return const HomeFeed(recommend: []);
      _source = src;
      return widget.services.sourceFor(src).home();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SourceDef>>(
      future: _sources,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: StarColors.brand));
        }
        if (snap.hasError) {
          return _Message('源列表加载失败：${snap.error}');
        }
        final sources = snap.data ?? const <SourceDef>[];
        if (sources.isEmpty) {
          return _EmptySources(onGoSources: widget.onGoSources);
        }
        return FutureBuilder<HomeFeed>(
          future: _feed,
          builder: (context, feedSnap) {
            if (feedSnap.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: StarColors.brand));
            }
            if (feedSnap.hasError) {
              return _Message(
                  '「${_source?.name ?? '源'}」暂时不可用：${feedSnap.error}');
            }
            final cards = feedSnap.data?.recommend ?? const <WorkCard>[];
            final srcName = _source?.name ?? '内容源';
            if (cards.isEmpty) {
              return _Message('「$srcName」首页暂无推荐，试试分类或搜索');
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _HeroContinue(
                  card: cards.first,
                  source: _source ?? sources.first,
                  onOpen: () => widget.onOpenDetail(
                      _source ?? sources.first, cards.first),
                ),
                const SizedBox(height: 22),
                _RowHeader(
                  title: '为你推荐',
                  subtitle: '来自「$srcName」',
                  onMore: null,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final card = cards[i];
                      return SizedBox(
                        width: 148,
                        child: StarPoster(
                          title: card.title,
                          subtitle: card.remarks ??
                              [card.year, card.genre]
                                  .whereType<String>()
                                  .join(' · '),
                          shape: StarCardShape.poster,
                          hueSeed: i,
                          imageUrl: card.posterUrl,
                          badgeText: card.score != null &&
                                  card.score!.isNotEmpty
                              ? card.score
                              : null,
                          onTap: () => widget.onOpenDetail(
                              _source ?? sources.first, card),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _RowHeader(title: '最近更新', subtitle: '按来源排序'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) {
                      final card =
                          cards[(i + 1) % cards.length]; // 错位制造“另一行”
                      return SizedBox(
                        width: 220,
                        child: StarPoster(
                          title: card.title,
                          subtitle: card.remarks ?? card.year,
                          shape: StarCardShape.landscape,
                          hueSeed: i + 3,
                          imageUrl: card.posterUrl,
                          onTap: () => widget.onOpenDetail(
                              _source ?? sources.first, card),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _RowHeader(title: '更多源', subtitle: '切换默认首页源可更换推荐'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in sources)
                      ActionChip(
                        avatar: Icon(
                          s.kind.hasAdapter
                              ? Icons.play_circle_outline
                              : Icons.block,
                          size: 18,
                          color: s.kind.hasAdapter
                              ? StarColors.brand
                              : StarColors.ink4,
                        ),
                        label: Text(s.name),
                        onPressed: s.kind.hasAdapter
                            ? () async {
                                await widget.services.setHomeSourceKey(s.key);
                                setState(() {
                                  _feed = _loadFeed();
                                });
                              }
                            : null,
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Hero 续播/首推大卡（Infuse / Netflix）。
class _HeroContinue extends StatelessWidget {
  const _HeroContinue({
    required this.card,
    required this.source,
    required this.onOpen,
  });

  final WorkCard card;
  final SourceDef source;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return HoverScale(
      scaleUp: 1.01,
      onTap: onOpen,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F7FD1), Color(0xFF5AA0E8)],
          ),
          boxShadow: [
            BoxShadow(
              color: StarColors.brand.withValues(alpha: 0.35),
              offset: const Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 右侧淡化海报
            if (card.posterUrl != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 220,
                child: Opacity(
                  opacity: 0.35,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: StarNetworkImage(
                      url: card.posterUrl!,
                      fit: BoxFit.cover,
                      fallback: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '继续观看 · 来自「${source.name}」',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if ((card.remarks ?? '').isNotEmpty) card.remarks!,
                      if ((card.year ?? '').isNotEmpty) card.year!,
                      if ((card.genre ?? '').isNotEmpty) card.genre!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _HeroBtn(
                        icon: Icons.play_arrow_rounded,
                        label: '立即播放',
                        filled: true,
                        onTap: onOpen,
                      ),
                      const SizedBox(width: 10),
                      _HeroBtn(
                        icon: Icons.info_outline,
                        label: '详情',
                        filled: false,
                        onTap: onOpen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  const _HeroBtn({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18, color: filled ? StarColors.brand : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? StarColors.brand : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({
    required this.title,
    this.subtitle,
    this.onMore,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        if (subtitle != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: StarColors.ink4),
            ),
          ),
        ],
        if (onMore != null)
          TextButton(onPressed: onMore, child: const Text('更多')),
      ],
    );
  }
}

class _EmptySources extends StatelessWidget {
  final VoidCallback onGoSources;

  const _EmptySources({required this.onGoSources});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: StarColors.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: StarColors.neuDark.withValues(alpha: 0.4),
              offset: const Offset(6, 6),
              blurRadius: 18,
            ),
            BoxShadow(
              color: StarColors.neuLight.withValues(alpha: 0.9),
              offset: const Offset(-6, -6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined,
                size: 48, color: StarColors.brand),
            const SizedBox(height: 12),
            const Text('还没有内容源',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('星映不内置任何内容源 —— 请导入订阅或本地 StarRule 文件',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: StarColors.ink3)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: StarColors.brand),
              onPressed: onGoSources,
              icon: const Icon(Icons.add),
              label: const Text('去添加源'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: StarColors.ink3)),
    );
  }
}
