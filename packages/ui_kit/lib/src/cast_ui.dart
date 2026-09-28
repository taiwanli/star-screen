import 'package:flutter/material.dart';
import 'colors.dart';

/// 迷你播放窗（小窗/画中画的桌面替身，docs/02 §4.3）。
/// 紧凑浮层：标题 + 播放/暂停 + 关闭；真正 OS PiP 由 v1.0+ 系统壳接入。
class MiniPlayerBar extends StatelessWidget {
  final String title;
  final bool playing;
  final VoidCallback onTogglePlay;
  final VoidCallback onExpand;
  final VoidCallback onClose;
  final double progress;

  const MiniPlayerBar({
    super.key,
    required this.title,
    required this.playing,
    required this.onTogglePlay,
    required this.onExpand,
    required this.onClose,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StarColors.glass,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 3,
              backgroundColor: const Color(0x22FFFFFF),
              color: const Color(0xFF4C9AFF),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: StarColors.ink)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onTogglePlay,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF4C9AFF)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onExpand,
                  icon: const Icon(Icons.open_in_full,
                      size: 16, color: StarColors.ink3),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onClose,
                  icon: const Icon(Icons.close,
                      size: 16, color: StarColors.ink3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 投屏设备列表（DLNA）。
class CastDeviceList extends StatelessWidget {
  final List<CastDeviceVm> devices;
  final bool scanning;
  final void Function(CastDeviceVm device) onCast;
  final VoidCallback onScan;

  const CastDeviceList({
    super.key,
    required this.devices,
    required this.scanning,
    required this.onCast,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('投屏设备',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StarColors.ink)),
            const Spacer(),
            if (scanning)
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF4C9AFF)))
            else
              TextButton(
                onPressed: onScan,
                child: const Text('扫描',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4C9AFF))),
              ),
          ],
        ),
        if (!scanning && devices.isEmpty)
          const Text('未发现 MediaRenderer（同一局域网）',
              style: TextStyle(fontSize: 11, color: StarColors.ink4))
        else
          for (final d in devices)
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.cast, size: 18, color: Color(0xFF4C9AFF)),
              title: Text(d.name,
                  style: const TextStyle(
                      fontSize: 12, color: StarColors.ink)),
              trailing: TextButton(
                onPressed: () => onCast(d),
                child: const Text('推送',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4C9AFF))),
              ),
            ),
      ],
    );
  }
}

class CastDeviceVm {
  final String id;
  final String name;

  const CastDeviceVm({required this.id, required this.name});
}