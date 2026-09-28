import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 手机直播页（docs/09 M3-5）：分组切换 + 频道列表 + 横屏直播播放。
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
    _grouped = widget.services.liveStore.grouped();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StarColors.page,
        surfaceTintColor: Colors.transparent,
        title: const Text('直播',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<Map<String, List<ParsedLiveChannel>>>(
        future: _grouped,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: StarColors.brand));
          }
          final grouped = snap.data ?? const {};
          if (grouped.isEmpty) {
            return const Center(
              child: Text('暂无直播频道 —— 导入含直播组的订阅后自动加载',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: StarColors.ink4)),
            );
          }
          final group = _selectedGroup ?? grouped.keys.first;
          final channels = grouped[group] ?? const <ParsedLiveChannel>[];
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    for (final g in grouped.keys)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(g, style: const TextStyle(fontSize: 13)),
                          selected: g == group,
                          selectedColor: StarColors.brandSoft,
                          labelStyle: TextStyle(
                              color: g == group ? StarColors.brandHi : StarColors.ink2),
                          onSelected: (_) => setState(() => _selectedGroup = g),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: channels.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: StarColors.line, height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final c = channels[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading:
                          const Icon(Icons.live_tv_outlined, color: StarColors.ink3),
                      title: Text(c.name, style: const TextStyle(fontSize: 15)),
                      onTap: () => _play(context, c),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller.load(widget.url);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Video(controller: _video)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [StarColors.glass, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  BackButton(
                      color: StarColors.ink,
                      onPressed: () => Navigator.of(context).pop()),
                  Text('[${widget.group}] ${widget.name}',
                      style: const TextStyle(
                          color: StarColors.ink, fontSize: 14)),
                ],
              ),
            ),
          ),
          const Positioned(
            right: 16,
            top: 16,
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: StarColors.bad),
                SizedBox(width: 6),
                Text('直播', style: TextStyle(fontSize: 12, color: StarColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
