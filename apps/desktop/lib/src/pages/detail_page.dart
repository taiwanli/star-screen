import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import 'multi_engine_player_page.dart';
import 'player_page.dart';

/// 详情页（区块顺序锁死：主视觉→标题→主操作→选集→简介，docs/07 §4.3）。
class DetailPage extends StatefulWidget {
  final AppServices services;
  final SourceDef def;
  final WorkCard card;

  const DetailPage({
    super.key,
    required this.services,
    required this.def,
    required this.card,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final VideoSource _source = widget.services.sourceFor(widget.def);
  late Future<WorkDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _source.detail(widget.card.workId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<WorkDetail>(
        future: _detail,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: StarColors.brand));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('详情加载失败：${snap.error}',
                      style: const TextStyle(color: StarColors.ink3)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('重试')),
                ],
              ),
            );
          }
          return _DetailBody(
            services: widget.services,
            def: widget.def,
            card: widget.card,
            detail: snap.data!,
            source: _source,
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final AppServices services;
  final SourceDef def;
  final WorkCard card;
  final WorkDetail detail;
  final VideoSource source;

  const _DetailBody({
    required this.services,
    required this.def,
    required this.card,
    required this.detail,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final line = detail.lines.firstOrNull;
    final poster = card.posterUrl ?? detail.card.posterUrl;
    return Stack(
      children: [
        // 模糊铺底（Infuse 式）
        Positioned.fill(
          child: poster == null
              ? const ColoredBox(color: StarColors.page)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    StarNetworkImage(
                      url: poster,
                      fit: BoxFit.cover,
                      cacheWidth: 720,
                      fallback: const ColoredBox(color: StarColors.page),
                    ),
                    // 压暗 + 向下渐隐到 page 底
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x55152033),
                            Color(0x99E8EEF5),
                            StarColors.page,
                          ],
                          stops: [0, 0.45, 0.72],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        // 顶栏返回
        Positioned(
          top: 8,
          left: 8,
          child: Material(
            color: StarColors.glass,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: StarColors.ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        // 内容
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 小海报（清晰叠在模糊层上）
                    HoverScale(
                      scaleUp: 1.02,
                      child: Container(
                        width: 180,
                        height: 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 12),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: poster == null
                              ? const ColoredBox(
                                  color: StarColors.raised,
                                  child: Icon(Icons.movie_outlined,
                                      color: StarColors.ink4),
                                )
                              : StarNetworkImage(
                                  url: poster,
                                  fit: BoxFit.cover,
                                  cacheWidth: 480,
                                  fallback: const ColoredBox(
                                    color: StarColors.raised,
                                    child: Icon(Icons.broken_image_outlined,
                                        color: StarColors.ink4),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: StarColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              if ((card.score ?? '').isNotEmpty)
                                '★ ${card.score}',
                              card.year,
                              card.area,
                              card.genre,
                              card.remarks,
                            ].whereType<String>().join('  ·  '),
                            style: const TextStyle(
                                fontSize: 13, color: StarColors.ink2),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _PlayButton(
                                services: services,
                                def: def,
                                card: card,
                                source: source,
                                defaultEpisode: 0,
                                episodes: line?.episodes ?? const [],
                                lineId: line?.lineId,
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: StarColors.ink2,
                                  side: const BorderSide(
                                      color: StarColors.lineStrong),
                                ),
                                onPressed: () => _showAltSources(context),
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('换源'),
                              ),
                              const SizedBox(width: 8),
                              _FavoriteButton(services: services, card: card),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 选集
                          Expanded(
                            child: Builder(builder: (context) {
                              Future<void> playAt(String lineId, int index) async {
                                final controller = PlayerEngineFactory.create(await services.playerEngine());
                                final session = PlaybackSession(
                                  source: source,
                                  player: _asDomain(controller),
                                  records: services.playRecordStore,
                                );
                                await services.playRecordStore.upsertSnapshot(card);
                                final outcome = await session.start(PlayRequest(
                                  workId: card.workId,
                                  episodeIndex: index,
                                  lineId: lineId,
                                ));
                                if (outcome is PlayOutcomeBlocked) {
                                  controller.dispose();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: StarColors.raised,
                                        content: Text(
                                          '该线路需要网页解析，请换线路或换源',
                                          style: TextStyle(color: StarColors.ink),
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (!context.mounted) return;
                                final eps = detail.lines
                                    .firstWhere(
                                      (l) => l.lineId == lineId,
                                      orElse: () => detail.lines.first,
                                    )
                                    .episodes;
                                final next =
                                    index + 1 < eps.length ? eps[index + 1] : null;
                                await _openPlayer(
                                  context,
                                  controller: controller,
                                  session: session,
                                  title: card.title,
                                  lineId: lineId,
                                  nextEpisodeTitle: next?.name,
                                  onPlayNext: next == null
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            if (!context.mounted) return;
                                            playAt(lineId, next.index);
                                          });
                                        },
                                );
                              }

                              return _EpisodePanel(
                                lines: detail.lines,
                                onPlay: playAt,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 简介条
              if ((detail.content ?? '').isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StarColors.glass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  child: Text(
                    detail.content!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: StarColors.ink2, height: 1.6),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 换源：搜同名片单，带进度迁移（docs/19 P1 换源保进度）。
  Future<void> _showAltSources(BuildContext context) async {
    final all = await services.enabledSources();
    final others = [
      for (final s in all)
        if (s.key != def.key && s.kind.hasAdapter) s
    ];
    if (!context.mounted) return;
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('没有其他可用源', style: TextStyle(color: StarColors.ink)),
      ));
      return;
    }
    // 当前进度（用于迁移）
    final rec = await services.playRecordStore.get(card.workKey);
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AltSourceDialog(
        services: services,
        card: card,
        currentDef: def,
        others: others,
        progress: rec,
      ),
    );
  }
}

/// 换源对话框：同名搜索 + 一键带进度跳转。
class _AltSourceDialog extends StatefulWidget {
  const _AltSourceDialog({
    required this.services,
    required this.card,
    required this.currentDef,
    required this.others,
    required this.progress,
  });

  final AppServices services;
  final WorkCard card;
  final SourceDef currentDef;
  final List<SourceDef> others;
  final PlayRecord? progress;

  @override
  State<_AltSourceDialog> createState() => _AltSourceDialogState();
}

class _AltSourceDialogState extends State<_AltSourceDialog> {
  final Map<String, List<WorkCard>> _hits = {};
  final Set<String> _loading = {};

  @override
  void initState() {
    super.initState();
    _searchAll();
  }

  Future<void> _searchAll() async {
    setState(() {
      _loading
        ..clear()
        ..addAll(widget.others.map((e) => e.key));
    });
    for (final s in widget.others) {
      try {
        final page = await widget.services
            .sourceFor(s)
            .search(widget.card.title)
            .timeout(const Duration(seconds: 8));
        if (!mounted) return;
        setState(() {
          _hits[s.key] = page.items.take(5).toList();
        });
      } on Object {
        if (mounted) setState(() => _hits[s.key] = const []);
      } finally {
        if (mounted) setState(() => _loading.remove(s.key));
      }
    }
  }

  Future<void> _switchTo(SourceDef def, WorkCard hit) async {
    final store = widget.services.playRecordStore;
    final prog = widget.progress;
    // 迁移进度：集数钳制 + 时长 1:1（未知则按原值）
    if (prog != null) {
      await store.copyProgressTo(
        fromKey: widget.card.workKey,
        toCard: hit,
        maxEpisodeIndex: 9999,
        durationScale: 1.0,
      );
    } else {
      await store.upsertSnapshot(hit);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailPage(
        services: widget.services,
        def: def,
        card: hit,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StarColors.surface,
      title: const Text('换源 · 保进度'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.progress == null
                  ? '当前：${widget.currentDef.name} · 无播放记录'
                  : '当前：${widget.currentDef.name} · '
                    '第 ${widget.progress!.episodeIndex + 1} 集 '
                    '${widget.progress!.positionSec}s 将迁移到新源',
              style: const TextStyle(fontSize: 12, color: StarColors.ink3),
            ),
            const SizedBox(height: 10),
            if (_loading.isNotEmpty && _hits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                    child:
                        CircularProgressIndicator(color: StarColors.brand)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in widget.others)
                      _sourceTile(s),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _searchAll();
          },
          child: const Text('重试搜索'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _sourceTile(SourceDef s) {
    final hits = _hits[s.key] ?? const <WorkCard>[];
    final loading = _loading.contains(s.key);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        s.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        loading ? '搜索中…' : (hits.isEmpty ? '无同名结果' : '命中 ${hits.length} 条'),
        style: const TextStyle(fontSize: 11, color: StarColors.ink3),
      ),
      children: [
        for (final h in hits)
          ListTile(
            dense: true,
            leading: const Icon(Icons.play_circle_outline, size: 18),
            title: Text(h.title, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              [h.year, h.remarks].whereType<String>().join(' · '),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _switchTo(s, h),
          ),
      ],
    );
  }
}

class _EpisodePanel extends StatelessWidget {
  const _EpisodePanel({
    required this.lines,
    required this.onPlay,
  });

  final List<PlayLine> lines;
  final void Function(String lineId, int episodeIndex) onPlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lines.length > 1)
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < lines.length; i++)
                Chip(
                  label: Text(lines[i].name),
                  backgroundColor: i == 0
                      ? StarColors.brandSoft
                      : StarColors.surface,
                  labelStyle: TextStyle(
                    color: i == 0 ? StarColors.brand : StarColors.ink2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        Expanded(
          child: Builder(builder: (context) {
            final eps = lines.firstOrNull?.episodes ?? const <Episode>[];
            return GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 72,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.35,
              ),
              itemCount: eps.length,
              itemBuilder: (_, i) {
                final ep = eps[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onPlay(lines.firstOrNull?.lineId ?? '', i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: StarColors.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ep.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: StarColors.ink),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}


DomainPlayerController _asDomain(PlayerController c) {
  if (c is MediaKitPlayerController) return c.asDomain();
  if (c is ExoVideoPlayerController) return c.asDomain();
  return (c as ExternalPlayerController).asDomain();
}

/// 按内核打开播放页：libmpv 走完整 PlayerPage；Exo/外部走精简多内核页。
Future<void> _openPlayer(
  BuildContext context, {
  required PlayerController controller,
  required PlaybackSession session,
  required String title,
  String? lineId,
  String? nextEpisodeTitle,
  VoidCallback? onPlayNext,
}) async {
  if (controller is MediaKitPlayerController) {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerPage(
        controller: controller,
        session: session,
        title: title,
        lineId: lineId,
        nextEpisodeTitle: nextEpisodeTitle,
        onPlayNext: onPlayNext,
      ),
    ));
    return;
  }
  final label = controller is ExoVideoPlayerController ? 'Exo' : '外部播放器';
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MultiEnginePlayerPage(
      controller: controller,
      title: title,
      engineLabel: label,
    ),
  ));
}

class _PlayButton extends StatelessWidget {
  final AppServices services;
  final SourceDef def;
  final WorkCard card;
  final VideoSource source;
  final int defaultEpisode;
  final List<Episode> episodes;
  final String? lineId;

  const _PlayButton({
    required this.services,
    required this.def,
    required this.card,
    required this.source,
    required this.defaultEpisode,
    this.episodes = const [],
    this.lineId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayRecord?>(
      future: services.playRecordStore.get(card.workKey),
      builder: (context, snap) {
        final record = snap.data;
        final resume = record != null &&
            !record.isFinished &&
            true;
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: StarColors.brand,
            minimumSize: const Size(200, 48),
          ),
          // 主操作文案随播放状态变化（docs/07 §4.3 锁死）
          label: Text(resume
              ? '继续观看 · 第 ${record.episodeIndex + 1} 集 ${_fmt(record.positionSec)}'
              : '立即播放'),
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _playFrom(context, resume ? record.episodeIndex : 0),
        );
      },
    );
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _playFrom(BuildContext context, int episodeIndex) async {
    final controller = PlayerEngineFactory.create(await services.playerEngine());
    final session = PlaybackSession(
      source: source,
      player: _asDomain(controller),
      records: services.playRecordStore,
    );
    await services.playRecordStore.upsertSnapshot(card);
    final outcome = await session.start(
      PlayRequest(workId: card.workId, episodeIndex: episodeIndex, lineId: lineId),
    );
    final playing = switch (outcome) {
      PlayOutcomeBlocked() => () {
          controller.dispose();
          if (!context.mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: StarColors.raised,
            content: const Text('该线路需要网页解析，请换线路或换源',
                style: TextStyle(color: StarColors.ink)),
          ));
          return null;
        }(),
      PlayOutcomePlaying() => outcome,
    };
    if (playing == null || !context.mounted) return;
    final next =
        episodeIndex + 1 < episodes.length ? episodes[episodeIndex + 1] : null;
    await _openPlayer(
      context,
      controller: controller,
      session: session,
      title: card.title,
      lineId: lineId,
      nextEpisodeTitle: next?.name,
      onPlayNext: next == null
          ? null
          : () {
              Navigator.of(context).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                _playFrom(context, next.index);
              });
            },
    );
  }
}

/// 收藏开关（docs/02 §4.4）。
class _FavoriteButton extends StatefulWidget {
  final AppServices services;
  final WorkCard card;

  const _FavoriteButton({required this.services, required this.card});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _fav = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await widget.services.favoriteStore.isFavorite(widget.card.workKey);
    if (mounted) setState(() => _fav = v);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _fav ? StarColors.brandHi : StarColors.ink2,
        side: const BorderSide(color: StarColors.lineStrong),
      ),
      onPressed: () async {
        if (_busy) return;
        setState(() => _busy = true);
        try {
          await widget.services.favoriteStore.toggle(widget.card);
          await _load();
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        },
      icon: Icon(_fav ? Icons.favorite : Icons.favorite_border, size: 18),
      label: Text(_fav ? '已收藏' : '收藏'),
    );
  }
}
