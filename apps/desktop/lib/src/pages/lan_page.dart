import 'dart:io';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_lan/star_lan.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 局域网互联页（docs/02 §4.9）：发现设备、推片、备份同步、下载管理。
class LanPage extends StatefulWidget {
  final AppServices services;
  final void Function(PlayPush push)? onPlayPush;

  const LanPage({
    super.key,
    required this.services,
    this.onPlayPush,
  });

  @override
  State<LanPage> createState() => _LanPageState();
}

class _LanPageState extends State<LanPage> {
  late final LanBridge _bridge;
  List<LanPeer> _peers = const [];
  StreamSubscription<List<LanPeer>>? _peerSub;
  List<DownloadItem> _downloads = const [];
  bool _hosting = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _bridge = widget.services.lan;
    _bridge.resolveToken().then((t) {
      if (mounted) setState(() => _token = t);
    });
    _peerSub = _bridge.peers.listen((p) {
      if (mounted) setState(() => _peers = p);
    });
    _reloadDownloads();
  }

  Future<void> _reloadDownloads() async {
    final list = await widget.services.downloads.list();
    if (mounted) setState(() => _downloads = list);
  }

  /// docs/13 B1：推最近继续观看记录（真实播放地址跨端解析 v0.9 完善）。
  Future<PlayPush> _pushLatest(LanPeer peer) async {
    final items = await widget.services.playRecordStore.continueWatchingDetailed();
    final first = items.firstOrNull;
    if (first == null) return const PlayPush(url: '', title: '星映推片');
    // 解析真实播放地址（禁止把 workKey 当 url）
    try {
      final srcKey = first.record.workKey.split('::').first;
      final defs = await widget.services.registry.all();
      final def = defs.where((s) => s.key == srcKey).firstOrNull;
      if (def == null) return PlayPush(url: '', title: first.title);
      final src = widget.services.sourceFor(def);
      final play = await src.resolve(PlayRequest(
        workId: SourceDef.workIdFromKey(first.record.workKey, srcKey),
        episodeIndex: first.record.episodeIndex,
        lineId: first.record.lineId,
      ));
      return PlayPush(url: play.url, title: first.title, headers: play.headers);
    } on Object {
      return PlayPush(url: '', title: first.title);
    }
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LanPanel(
            peers: [
              for (final p in _peers)
                LanPeerVm(
                  name: p.name,
                  ip: p.ip,
                  port: p.port,
                  deviceId: p.deviceId,
                ),
            ],
            pairingToken: _token,
            hosting: _hosting,
            onToggleHosting: () async {
              if (_hosting) {
                await _bridge.stopHosting();
              } else {
                await _bridge.startHosting();
              }
              if (mounted) setState(() => _hosting = _bridge.hosting);
            },
            onRefresh: () {},
            onPushPlay: (vm) async {
              final peer = _peers
                  .where((e) => e.deviceId == vm.deviceId)
                  .firstOrNull;
              if (peer == null) return;
              final ok = await _bridge.client.pushPlay(
                peer,
                await _pushLatest(peer),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: StarColors.raised,
                content: Text(ok ? '已推送到 ${peer.name}' : '推送失败',
                    style: const TextStyle(color: StarColors.ink)),
              ));
            },
            onPullBackup: (vm) async {
              final peer =
                  _peers.where((e) => e.deviceId == vm.deviceId).firstOrNull;
              if (peer == null) return;
              final text = await _bridge.client.pullBackup(peer);
              if (text == null) return;
              await widget.services.backup.importAll(text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: StarColors.raised,
                content: Text('已从 ${peer.name} 拉取同步',
                    style: const TextStyle(color: StarColors.ink)),
              ));
            },
            onPushBackup: (vm) async {
              final peer =
                  _peers.where((e) => e.deviceId == vm.deviceId).firstOrNull;
              if (peer == null) return;
              final text = await widget.services.backup.exportAll();
              final ok = await _bridge.client.pushBackup(peer, text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: StarColors.raised,
                content: Text(ok ? '已推送到 ${peer.name}' : '推送同步失败',
                    style: const TextStyle(color: StarColors.ink)),
              ));
            },
          ),
          const SizedBox(height: 24),
          DownloadList(
            items: [
              for (final d in _downloads)
                DownloadVm(
                  id: d.id,
                  title: d.title,
                  statusText: switch (d.status) {
                    DownloadStatus.queued => '排队中',
                    DownloadStatus.running =>
                      '下载中 ${((d.progress ?? 0) * 100).round()}%',
                    DownloadStatus.done => '已完成',
                    DownloadStatus.failed => '失败：${d.error ?? ''}',
                  },
                  progress: d.progress,
                  done: d.status == DownloadStatus.done,
                  savePath: d.savePath,
                ),
            ],
            onRemove: (vm) async {
              await widget.services.downloads.remove(vm.id);
              await _reloadDownloads();
            },
            onClear: () async {
              await widget.services.downloads.clear();
              await _reloadDownloads();
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.services.lan.enqueueDownload(
                title: '示例下载',
                url: 'https://example.com/video.m3u8',
                dir: downloadDirFor(Directory.systemTemp.path),
              );
              await _reloadDownloads();
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('添加示例下载任务'),
          ),
        ],
      ),
    );
  }
}
