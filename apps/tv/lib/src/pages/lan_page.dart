import 'dart:async';

import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_lan/star_lan.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 局域网互联页（手机/TV 共用逻辑，docs/02 §4.9）。
class LanPage extends StatefulWidget {
  final AppServices services;

  const LanPage({super.key, required this.services});

  @override
  State<LanPage> createState() => _LanPageState();
}

class _LanPageState extends State<LanPage> {
  late final LanBridge _bridge = widget.services.lan;
  List<LanPeer> _peers = const [];
  StreamSubscription<List<LanPeer>>? _peerSub;
  List<DownloadItem> _downloads = const [];
  bool _hosting = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _peerSub = _bridge.peers.listen((p) {
      if (mounted) setState(() => _peers = p);
    });
    _reloadDownloads();
    _bridge.resolveToken().then((t) {
      if (mounted) setState(() => _token = t);
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网互联', style: TextStyle(fontSize: 16)),
        backgroundColor: StarColors.page,
      ),
      body: SingleChildScrollView(
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
              hosting: _hosting,
              pairingToken: _token,
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
                await _bridge.client.pushPlay(peer, await _pushLatest(peer));
              },
              onPullBackup: (vm) async {
                final peer = _peers
                    .where((e) => e.deviceId == vm.deviceId)
                    .firstOrNull;
                if (peer == null) return;
                final text = await _bridge.client.pullBackup(peer);
                if (text == null) return;
                await widget.services.backup.importAll(text);
                setState(() {});
              },
              onPushBackup: (vm) async {
                final peer = _peers
                    .where((e) => e.deviceId == vm.deviceId)
                    .firstOrNull;
                if (peer == null) return;
                final text = await widget.services.backup.exportAll();
                await _bridge.client.pushBackup(peer, text);
              },
            ),
            const SizedBox(height: 24),
            DownloadList(
              items: [
                for (final d in _downloads)
                  DownloadVm(
                    id: d.id,
                    title: d.title,
                    statusText: d.status.name,
                    progress: d.progress,
                    done: d.status == DownloadStatus.done,
                    savePath: d.savePath,
                  ),
              ],
              onRemove: (vm) async {
                await widget.services.downloads.remove(vm.id);
                await _reloadDownloads();
              },
            ),
          ],
        ),
      ),
    );
  }
}
