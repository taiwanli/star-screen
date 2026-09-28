import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import '../widgets/focus_widgets.dart';
import '../widgets/tv_focus_engine.dart';
import 'player_page.dart';

/// TV 详情页（docs/07 §4.3）：左 35 主视觉+主操作 / 右 65 选集网格，
/// 一屏内同时可见「播放」与「选集」，焦点默认落在「播放」。
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
  List<Episode> _lastEpisodes = const [];
  String? _lastLineId;
  late Future<WorkDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = _source.detail(widget.card.workId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TvFocusScope(
        pageKey: 'tv-detail/${widget.card.workId}',
        child: FutureBuilder<WorkDetail>(
          future: _detail,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                  child: CircularProgressIndicator(color: StarColors.brand));
            }
            if (snap.hasError) {
              return Center(
                child: Text('详情加载失败：${snap.error}',
                    style: const TextStyle(fontSize: 22, color: StarColors.ink3)),
              );
            }
            final detail = snap.data!;
            final line = detail.lines.firstOrNull;
          _lastEpisodes = line?.episodes ?? const [];
          _lastLineId = line?.lineId;
            final card = widget.card;
            return Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                  children: [
                    BackButton(
                        color: StarColors.ink,
                        onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 8),
                    Text(card.title,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左 35%：主视觉 + 元数据 + 主操作
                      Expanded(
                        flex: 35,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (card.posterUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 420,
                                  height: 236,
                                  child: Image.network(
                  card.posterUrl!,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0',
                  },
                  cacheWidth: 480,
                  filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, _, _) => const ColoredBox(
                                          color: StarColors.raised,
                                          child: Center(
                                              child: Icon(Icons.movie_outlined,
                                                  size: 48,
                                                  color: StarColors.ink4)))),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Text(card.title,
                                style: const TextStyle(
                                    fontSize: 44, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(
                              [
                                if (card.score != null) '★ ${card.score}',
                                card.year,
                                card.area,
                                card.genre,
                                card.remarks,
                              ].whereType<String>().join(' · '),
                              style: const TextStyle(
                                  fontSize: 24, color: StarColors.ink2),
                            ),
                            const SizedBox(height: 28),
                            _TvPlayButton(
                              services: widget.services,
                              card: card,
                              source: _source,
                              episodes: _lastEpisodes,
                              lineId: _lastLineId,
                            ),
                          ],
                        ),
                      ),
                      // 右 65%：选集网格（焦点严格二维移动）
                      Expanded(
                        flex: 65,
                        child: line == null
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${line.name} · ${line.episodes.length} 集（前导零三端统一）',
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: [
                                      for (final ep in line.episodes)
                                        TvFocusChip(
                                          label: ep.name,
                                          isNavSelected: false,
                                          onSelect: () => _play(
                                              context, ep.index, ep.name, line.lineId,
                                              episodes: line.episodes),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Future<void> _play(BuildContext context, int episodeIndex,
      String episodeName, String? lineId,
      {List<Episode> episodes = const []}) async {
    final controller = MediaKitPlayerController(subtitleStyle: SubtitleStyle.tv);
    final session = PlaybackSession(
      source: _source,
      player: controller.asDomain(),
      records: widget.services.playRecordStore,
    );
    await widget.services.playRecordStore.upsertSnapshot(widget.card);
    final outcome = await session.start(
      PlayRequest(workId: widget.card.workId, episodeIndex: episodeIndex, lineId: lineId),
    );
    if (outcome is PlayOutcomeBlocked) {
      controller.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: const Text('该线路需要网页解析，请换线路或换源',
              style: TextStyle(color: StarColors.ink)),
        ));
      }
      return;
    }
    if (!context.mounted) return;
    final next =
        episodeIndex + 1 < episodes.length ? episodes[episodeIndex + 1] : null;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerPage(
        controller: controller,
        session: session,
        title:
            '${widget.card.title} · ${episodeName.isNotEmpty ? episodeName : '第${episodeIndex + 1}集'}',
        nextEpisodeTitle: next?.name,
        onPlayNext: next == null
            ? null
            : () {
                Navigator.of(context).pop();
                // 等旧播放页 dispose（释放内核）后再起下一集，避免竞态
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  _play(context, next.index, next.name, lineId,
                      episodes: episodes);
                });
              },
      ),
    ));
  }
}

class _TvPlayButton extends StatelessWidget {
  final AppServices services;
  final WorkCard card;
  final VideoSource source;
  final List<Episode> episodes;
  final String? lineId;

  const _TvPlayButton({
    required this.services,
    required this.card,
    required this.source,
    this.episodes = const [],
    this.lineId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayRecord?>(
      future: services.playRecordStore.get(card.workKey),
      builder: (context, snap) {
        final record = snap.data;
        final resume = record != null && !record.isFinished;
        final label = resume ? '继续观看 · 第 ${record.episodeIndex + 1} 集' : '立即播放';
        final episode = resume ? record.episodeIndex : 0;
        return TvFocusChip(
          label: '▶  $label',
          isNavSelected: true,
          onSelect: () => _startPlay(context, episode),
        );
      },
    );
  }

  Future<void> _startPlay(BuildContext context, int episodeIndex) async {
    final controller =
        MediaKitPlayerController(subtitleStyle: SubtitleStyle.tv);
    final session = PlaybackSession(
      source: source,
      player: controller.asDomain(),
      records: services.playRecordStore,
    );
    await services.playRecordStore.upsertSnapshot(card);
    final outcome = await session.start(
      PlayRequest(workId: card.workId, episodeIndex: episodeIndex, lineId: lineId),
    );
    if (outcome is PlayOutcomeBlocked) {
      controller.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: const Text('该线路需要网页解析，请换线路或换源',
              style: TextStyle(color: StarColors.ink)),
        ));
      }
      return;
    }
    if (!context.mounted) return;
    final next = episodeIndex + 1 < episodes.length
        ? episodes[episodeIndex + 1]
        : null;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerPage(
        controller: controller,
        session: session,
        title: card.title,
        nextEpisodeTitle: next?.name,
        onPlayNext: next == null
            ? null
            : () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  _startPlay(context, next.index);
                });
              },
      ),
    ));
  }
}
