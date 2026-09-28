import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// 局域网设备列表 + 推送/同步（docs/02 §4.9）。
class LanPanel extends StatelessWidget {
  final List<LanPeerVm> peers;
  final bool hosting;
  final VoidCallback onToggleHosting;
  final void Function(LanPeerVm peer) onPushPlay;
  final void Function(LanPeerVm peer) onPullBackup;
  final void Function(LanPeerVm peer) onPushBackup;
  final VoidCallback onRefresh;
  /// docs/13 E1：配对口令（展示用；两端需一致才可 /play /backup）。
  final String? pairingToken;

  const LanPanel({
    super.key,
    required this.peers,
    required this.hosting,
    required this.onToggleHosting,
    required this.onPushPlay,
    required this.onPullBackup,
    required this.onPushBackup,
    required this.onRefresh,
    this.pairingToken,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('局域网互联',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: StarColors.ink)),
            const Spacer(),
            Switch(
              value: hosting,
              onChanged: (_) => onToggleHosting(),
            ),
            Text(hosting ? '本机可被发现' : '发现已关闭',
                style: const TextStyle(
                    fontSize: 12, color: StarColors.ink3)),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18, color: StarColors.ink3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (pairingToken != null && pairingToken!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('配对口令',
                    style: TextStyle(
                        fontSize: 12,
                        color: StarColors.ink3)),
                const SizedBox(width: 8),
                Text(pairingToken!,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4C9AFF),
                        fontFamily: 'Consolas',
                        letterSpacing: 1.5)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: pairingToken!));
                  },
                  icon: const Icon(Icons.copy, size: 14, color: StarColors.ink4),
                  tooltip: '复制口令',
                ),
              ],
            ),
          ),
        if (peers.isEmpty)
          const Text('同一局域网内打开星映的设备会出现在这里',
              style: TextStyle(fontSize: 12, color: StarColors.ink4))
        else
          for (final p in peers)
            Card(
              color: StarColors.surface,
              child: ListTile(
                leading:
                    const Icon(Icons.devices, color: Color(0xFF4C9AFF), size: 20),
                title: Text(p.name,
                    style: const TextStyle(
                        fontSize: 13, color: StarColors.ink)),
                subtitle: Text('${p.ip}:${p.port}',
                    style: const TextStyle(
                        fontSize: 11, color: StarColors.ink3)),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => onPushPlay(p),
                      child: const Text('推片',
                          style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => onPullBackup(p),
                      child: const Text('拉同步',
                          style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => onPushBackup(p),
                      child: const Text('推同步',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class LanPeerVm {
  final String name;
  final String ip;
  final int port;
  final String deviceId;

  const LanPeerVm({
    required this.name,
    required this.ip,
    required this.port,
    required this.deviceId,
  });
}

/// 下载列表（docs/02 §4.3）。
class DownloadList extends StatelessWidget {
  final List<DownloadVm> items;
  final void Function(DownloadVm item)? onRemove;
  final void Function(DownloadVm item)? onOpen;
  final VoidCallback? onClear;

  const DownloadList({
    super.key,
    required this.items,
    this.onRemove,
    this.onOpen,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('下载',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: StarColors.ink)),
            const Spacer(),
            if (onClear != null)
              TextButton(
                onPressed: onClear,
                child: const Text('清空',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFFFF6B6B))),
              ),
          ],
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('暂无下载任务',
                style: TextStyle(fontSize: 12, color: StarColors.ink4)),
          )
        else
          for (final i in items)
            ListTile(
              dense: true,
              title: Text(i.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: StarColors.ink)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.statusText ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: StarColors.ink3)),
                  if (i.progress != null)
                    LinearProgressIndicator(
                      value: i.progress,
                      backgroundColor: const Color(0x22FFFFFF),
                      color: const Color(0xFF4C9AFF),
                      minHeight: 3,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onOpen != null && i.done)
                    IconButton(
                      icon: const Icon(Icons.play_arrow,
                          size: 18, color: Color(0xFF4C9AFF)),
                      onPressed: () => onOpen!(i),
                    ),
                  if (onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: StarColors.ink4),
                      onPressed: () => onRemove!(i),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class DownloadVm {
  final String id;
  final String title;
  final String? statusText;
  final double? progress;
  final bool done;
  final String? savePath;

  const DownloadVm({
    required this.id,
    required this.title,
    this.statusText,
    this.progress,
    this.done = false,
    this.savePath,
  });
}