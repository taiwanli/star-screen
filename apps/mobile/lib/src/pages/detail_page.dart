import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import 'player_page.dart';

/// 手机详情页（docs/07 §4.3：主操作吸底）。
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
      appBar: AppBar(
        backgroundColor: StarColors.page,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.card.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<WorkDetail>(
        future: _detail,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: StarColors.brand));
          }
          if (snap.hasError) {
            return Center(
              child: Text('详情加载失败：${snap.error}',
                  style: const TextStyle(fontSize: 13, color: StarColors.ink3)),
            );
          }
          final detail = snap.data!;
          final line = detail.lines.firstOrNull;
      _lastEpisodes = line?.episodes ?? const [];
      _lastLineId = line?.lineId;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (detail.content != null)
                Text(detail.content!,
                    style: const TextStyle(
                        fontSize: 13.5, color: StarColors.ink2, height: 1.6)),
              const SizedBox(height: 16),
              if (line != null) ...[
                Text('${line.name}（${line.episodes.length} 集）',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ep in line.episodes)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StarColors.ink2,
                          side: const BorderSide(color: StarColors.line),
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () => _play(context, ep.index, ep.name, line.lineId,
                            episodes: line.episodes),
                        child: Text(ep.name),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
      // 主操作吸底常驻（规范 6.3：禁止滚到底才发现播放按钮）
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _PlayButton(
            services: widget.services,
            card: widget.card,
            source: _source,
            episodes: _lastEpisodes,
            lineId: _lastLineId,
          ),
        ),
      ),
    );
  }

  Future<void> _play(
      BuildContext context, int episodeIndex, String episodeName, String? lineId,
      {List<Episode> episodes = const []}) async {
    final controller = MediaKitPlayerController();
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

class _PlayButton extends StatelessWidget {
  final AppServices services;
  final WorkCard card;
  final VideoSource source;
  final List<Episode> episodes;
  final String? lineId;

  const _PlayButton({
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
        final episode = resume ? record.episodeIndex : 0;
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: StarColors.brand,
            minimumSize: const Size.fromHeight(52),
          ),
          label: Text(resume
              ? '继续观看 · 第 ${record.episodeIndex + 1} 集'
              : '立即播放'),
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _startPlay(context, episode),
        );
      },
    );
  }

  Future<void> _startPlay(BuildContext context, int episodeIndex) async {
    final controller = MediaKitPlayerController();
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
