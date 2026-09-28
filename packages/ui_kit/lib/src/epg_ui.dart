import 'package:flutter/material.dart';
import 'colors.dart';

/// EPG 节目单条目（UI 层，与 domain EpgProgramme 解耦）。
class EpgItemVm {
  final String title;
  final DateTime start;
  final DateTime stop;
  final bool playing;

  const EpgItemVm({
    required this.title,
    required this.start,
    required this.stop,
    required this.playing,
  });
}

/// 今日节目单（docs/02 §4.5 EPG）。
class EpgPanel extends StatelessWidget {
  final String channelName;
  final List<EpgItemVm> items;
  final bool loading;
  final String? error;
  final VoidCallback? onRefresh;

  const EpgPanel({
    super.key,
    required this.channelName,
    required this.items,
    this.loading = false,
    this.error,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StarColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('节目单 · $channelName',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: StarColors.ink)),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh,
                      size: 16, color: StarColors.ink3),
                ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(color: Color(0xFF4C9AFF)),
            )
          else if (error != null)
            Text(error!,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFFFF6B6B)))
          else if (items.isEmpty)
            const Text('暂无今日节目',
                style: TextStyle(fontSize: 12, color: StarColors.ink4))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(_hhmm(e.start),
                            style: TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: 11,
                                color: e.playing
                                    ? const Color(0xFF4C9AFF)
                                    : StarColors.ink3)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: e.playing
                                      ? const Color(0xFF4C9AFF)
                                      : StarColors.ink)),
                        ),
                        if (e.playing)
                          const Icon(Icons.play_arrow,
                              size: 14, color: Color(0xFF4C9AFF)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }
}