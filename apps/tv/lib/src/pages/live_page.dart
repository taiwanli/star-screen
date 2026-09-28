import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_player/star_player.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import '../widgets/focus_widgets.dart';

/// TV 直播页（docs/09 M3-5）：分组焦点行 + 频道焦点列表 + 全屏直播。
/// 数字键换台与 EPG 面板随焦点引擎深化接入（M3 收尾）。
class TvLivePage extends StatefulWidget {
  final AppServices services;

  const TvLivePage({super.key, required this.services});

  @override
  State<TvLivePage> createState() => _TvLivePageState();
}

class _TvLivePageState extends State<TvLivePage> {
  late Future<Map<String, List<ParsedLiveChannel>>> _grouped;
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
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
          return const Center(
            child: Text('暂无直播频道 —— 在「设置 → 源管理」导入含直播组的订阅',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, color: StarColors.ink3)),
          );
        }
        final group = _selectedGroup ?? grouped.keys.first;
        final channels = grouped[group] ?? const <ParsedLiveChannel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final g in grouped.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TvFocusChip(
                        label: '$g（${grouped[g]!.length}）',
                        isNavSelected: g == group,
                        onSelect: () => setState(() => _selectedGroup = g),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 5.2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: channels.length,
                itemBuilder: (_, i) => _FocusChannelRow(
                  name: channels[i].name,
                  onTap: () => _play(context, channels[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _play(BuildContext context, ParsedLiveChannel channel) async {
    final all = widget.services.liveStore;
    final grouped = await all.grouped();
    final flat = [
      for (final g in grouped.values) ...g,
    ];
    final index = flat.indexWhere((c) =>
        c.name == channel.name && c.url == channel.url);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _TvLivePlayerPage(
        url: channel.url,
        name: channel.name,
        group: channel.group,
        channels: flat,
        initialIndex: index < 0 ? 0 : index,
      ),
    ));
  }
}

class _FocusChannelRow extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _FocusChannelRow({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: hasFocus ? StarColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFocus ? StarColors.brandHi : Colors.transparent,
                width: 3,
              ),
            ),
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 24,
                    color: hasFocus ? StarColors.ink : StarColors.ink2)),
          );
        },
      ),
    );
  }
}

/// TV 直播播放：数字键换台（1-based 频道号，docs/09 M3-2）+ 直播角标。
class _TvLivePlayerPage extends StatefulWidget {
  final String url;
  final String name;
  final String group;
  final List<ParsedLiveChannel> channels;
  final int initialIndex;

  const _TvLivePlayerPage({
    required this.url,
    required this.name,
    required this.group,
    required this.channels,
    required this.initialIndex,
  });

  @override
  State<_TvLivePlayerPage> createState() => _TvLivePlayerPageState();
}

class _TvLivePlayerPageState extends State<_TvLivePlayerPage> {
  late final MediaKitPlayerController _controller;
  late final VideoController _video;
  late int _index = widget.initialIndex;
  StreamSubscription<PlayerFailed>? _failureSub;
  final ChannelNumberBuffer _buffer = ChannelNumberBuffer();
  String _digits = '';
  List<EpgItemVm> _epg = const [];
  bool _epgLoading = false;
  String? _epgError;
  bool _showEpg = false;

  static const _epgTemplate =
      'https://epg.112114.xyz/e.xml?ch={name}&date={date}';

  @override
  void initState() {
    super.initState();
    _controller = MediaKitPlayerController(subtitleStyle: SubtitleStyle.tv);
    _video = VideoController(_controller.player);
    _failureSub = _controller.events
        .where((e) => e is PlayerFailed)
        .cast<PlayerFailed>()
        .listen((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text('直播播放失败：${e.reason}',
              style: const TextStyle(color: StarColors.bad)),
        ));
      }
    });
    _controller.load(widget.channels[_index].url);
    _loadEpg();
  }

  Future<void> _loadEpg() async {
    final ch = widget.channels[_index];
    setState(() {
      _epgLoading = true;
      _epgError = null;
    });
    try {
      final loader = EpgLoader(getText: (url) async {
        final client = HttpClient();
        try {
          final req = await client.getUrl(Uri.parse(url));
          final res = await req.close().timeout(const Duration(seconds: 8));
          return await res.transform(const SystemEncoding().decoder).join();
        } finally {
          client.close(force: true);
        }
      });
      final programmes = await loader.loadToday(
        template: _epgTemplate,
        channelName: ch.name,
        channelId: ch.tvgId ?? ch.name,
      );
      final now = DateTime.now();
      if (!mounted) return;
      setState(() {
        _epg = [
          for (final p in programmes)
            EpgItemVm(
              title: p.title,
              start: p.start,
              stop: p.stop,
              playing: p.playingAt(now),
            ),
        ];
      });
    } on Object catch (e) {
      if (mounted) setState(() => _epgError = 'EPG 加载失败：$e');
    } finally {
      if (mounted) setState(() => _epgLoading = false);
    }
  }

  @override
  void dispose() {
    _failureSub?.cancel();
    _buffer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _switchTo(int index) {
    if (index < 0 || index >= widget.channels.length) return;
    setState(() {
      _index = index;
      _digits = '';
    });
    _controller.load(widget.channels[index].url);
    _loadEpg();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    final digit = _digitOf(event.logicalKey);
    if (digit != null) {
      _buffer.press(digit, onCommitNow: (v) {
        final n = int.tryParse(v);
        if (n == null) return;
        // 频道号 1-based
        _switchTo(n - 1);
      });
      setState(() => _digits = _buffer.digits);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.channelUp) {
      _switchTo((_index + 1) % widget.channels.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.channelDown) {
      _switchTo((_index - 1 + widget.channels.length) % widget.channels.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static String? _digitOf(LogicalKeyboardKey key) {
    if (key.keyId >= LogicalKeyboardKey.digit0.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      return String.fromCharCode(
          key.keyId - LogicalKeyboardKey.digit0.keyId + 0x30);
    }
    if (key.keyId >= LogicalKeyboardKey.numpad0.keyId &&
        key.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      return String.fromCharCode(
          key.keyId - LogicalKeyboardKey.numpad0.keyId + 0x30);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.channels[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            Positioned.fill(child: Video(controller: _video)),
            if (_digits.isNotEmpty)
              Center(child: ChannelNumberOverlay(digits: _digits)),
            Positioned(
              left: 48,
              top: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: StarColors.ink, size: 36),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text('[${ch.group}] ${ch.name}',
                      style: const TextStyle(
                          fontSize: 26, color: StarColors.ink)),
                  const SizedBox(width: 16),
                  Text('${_index + 1}/${widget.channels.length}',
                      style: const TextStyle(
                          fontSize: 20, color: StarColors.ink3)),
                ],
              ),
            ),
            const Positioned(
              right: 48,
              top: 48,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: StarColors.bad),
                  SizedBox(width: 8),
                  Text('直播',
                      style: TextStyle(fontSize: 22, color: StarColors.ink)),
                ],
              ),
            ),
            Positioned(
              right: 48,
              top: 96,
              child: IconButton(
                tooltip: '节目单',
                icon: const Icon(Icons.schedule,
                    color: StarColors.ink, size: 32),
                onPressed: () => setState(() => _showEpg = !_showEpg),
              ),
            ),
            if (_showEpg)
              Positioned(
                right: 48,
                top: 150,
                child: EpgPanel(
                  channelName: ch.name,
                  items: _epg,
                  loading: _epgLoading,
                  error: _epgError,
                  onRefresh: _loadEpg,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
