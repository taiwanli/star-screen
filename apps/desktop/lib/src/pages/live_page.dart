import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 直播页（docs/09 M3-5 UI）：分组频道列表 + libmpv 直播播放。
/// 数字键换台与 EPG 面板随焦点引擎深化接入（M3 收尾）。
// 注意（docs/13 C2 校正）：EPG 面板 + 数字键换台目前仅在 TV 端 live_page 落地（
// `ChannelNumberBuffer` + EPG 节目单），桌面端待焦点引擎深化后接入，M3 收尾。
class LivePage extends StatefulWidget {
  final AppServices services;

  const LivePage({super.key, required this.services});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late Future<Map<String, List<ParsedLiveChannel>>> _grouped;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _grouped = widget.services.liveStore.grouped();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<ParsedLiveChannel>>>(
      future: _grouped,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: StarColors.brand));
        }
        final grouped = snap.data ?? const {};
        if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('暂无直播频道',
                    style: TextStyle(fontSize: 13, color: StarColors.ink4)),
                const SizedBox(height: 6),
                const Text('在「源管理」导入含直播组的订阅后自动加载',
                    style: TextStyle(fontSize: 12, color: StarColors.ink4)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    await widget.services.liveStore.clearAll();
                    if (mounted) setState(_reload);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('清空频道缓存'),
                ),
              ],
            ),
          );
        }
        final group = _selectedGroup ?? grouped.keys.first;
        final channels = grouped[group] ?? const <ParsedLiveChannel>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text(
                    '直播 · ${grouped.values.fold<int>(0, (a, b) => a + b.length)} 个频道',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await widget.services.liveStore.clearAll();
                      if (mounted) setState(_reload);
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('清空频道'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分组栏
            SizedBox(
              width: 220,
              child: ListView(
                children: [
                  for (final g in grouped.keys)
                    ListTile(
                      dense: true,
                      selected: g == group,
                      selectedTileColor: StarColors.brandSoft,
                      title: Text('$g（${grouped[g]!.length}）',
                          style: TextStyle(
                              fontSize: 13.5,
                              color:
                                  g == group ? StarColors.brandHi : StarColors.ink2)),
                      onTap: () => setState(() => _selectedGroup = g),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: StarColors.line),
            // 频道列表
            Expanded(
              child: ListView.builder(
                itemCount: channels.length,
                itemBuilder: (_, i) {
                  final c = channels[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.live_tv_outlined,
                        size: 20, color: StarColors.ink3),
                    title: Text(c.name,
                        style: const TextStyle(fontSize: 14)),
                    onTap: () => _play(context, c),
                  );
                },
              ),
            ),
          ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _play(BuildContext context, ParsedLiveChannel channel) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LivePlayerPage(
        url: channel.url,
        name: channel.name,
        group: channel.group,
      ),
    ));
  }
}

/// 直播播放：无进度条（直播语义），仅返回 + 标题；换台由直播页完成。
class _LivePlayerPage extends StatefulWidget {
  final String url;
  final String name;
  final String group;

  const _LivePlayerPage({
    required this.url,
    required this.name,
    required this.group,
  });

  @override
  State<_LivePlayerPage> createState() => _LivePlayerPageState();
}

class _LivePlayerPageState extends State<_LivePlayerPage> {
  late final MediaKitPlayerController _controller = MediaKitPlayerController();
  late final VideoController _video = VideoController(_controller.player);
  StreamSubscription<PlayerFailed>? _failureSub;

  @override
  void initState() {
    super.initState();
    _controller.load(widget.url);
    _failureSub = _controller.events
        .where((e) => e is PlayerFailed)
        .cast<PlayerFailed>()
        .listen((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text(playErrorText(e.reason),
              style: const TextStyle(color: StarColors.bad)),
        ));
      }
    });
  }

  @override
  void dispose() {
    _failureSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: Video(controller: _video)),
          // 玻璃顶栏（与播放页 v3 同基因，白玻璃 + ink 字）
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: StarColors.glassStrong,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          offset: const Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: StarColors.ink, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          '[${widget.group}] ${widget.name}',
                          style: const TextStyle(
                            color: StarColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: StarColors.bad.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: StarColors.bad),
                              SizedBox(width: 4),
                              Text('直播',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: StarColors.bad)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
