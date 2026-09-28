import 'package:flutter/material.dart';
import 'colors.dart';

/// 播放增强控制条：倍速 / 清晰度 / 音轨 / 线路 / 跳片头片尾（docs/02 §4.3）。
class PlayerExtrasBar extends StatelessWidget {
  final double rate;
  final ValueChanged<double> onRateChanged;
  final List<String> qualityNames;
  final String? qualityName;
  final ValueChanged<String?> onQualityChanged;
  final List<TrackOption> audioTracks;
  final String? audioTrackId;
  final ValueChanged<String?> onAudioChanged;
  final List<TrackOption> lines;
  final String? lineId;
  final ValueChanged<String?>? onLineChanged;
  final VoidCallback? onSkipIntro;
  final VoidCallback? onSkipOutro;
  final bool compact;

  const PlayerExtrasBar({
    super.key,
    required this.rate,
    required this.onRateChanged,
    this.qualityNames = const [],
    this.qualityName,
    required this.onQualityChanged,
    this.audioTracks = const [],
    this.audioTrackId,
    required this.onAudioChanged,
    this.lines = const [],
    this.lineId,
    this.onLineChanged,
    this.onSkipIntro,
    this.onSkipOutro,
    this.compact = true,
  });

  static const rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<double>(
          tooltip: '倍速',
          color: StarColors.surface,
          child: _chip('倍速 ${rate}x'),
          itemBuilder: (_) => [
            for (final r in rates)
              PopupMenuItem(
                value: r,
                child: Text('${r}x',
                    style: TextStyle(
                        fontSize: 12,
                        color: r == rate
                            ? const Color(0xFF4C9AFF)
                            : StarColors.ink)),
              ),
          ],
          onSelected: onRateChanged,
        ),
        // v0.1 适配器未填充清晰度轨（P08）—— 有真实数据才显示
        if (qualityNames.isNotEmpty)
          PopupMenuButton<String?>(
            tooltip: '清晰度',
            color: StarColors.surface,
            child: _chip('清晰度 ${qualityName ?? '自动'}'),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('自动',
                    style: TextStyle(fontSize: 12, color: StarColors.ink)),
              ),
              for (final q in qualityNames)
                PopupMenuItem(
                  value: q,
                  child: Text(q,
                      style: const TextStyle(
                          fontSize: 12, color: StarColors.ink)),
                ),
            ],
            onSelected: onQualityChanged,
          ),
        if (audioTracks.isNotEmpty)
          PopupMenuButton<String?>(
            tooltip: '音轨',
            color: StarColors.surface,
            child: _chip('音轨'),
            itemBuilder: (_) => [
              for (final t in audioTracks)
                PopupMenuItem(
                  value: t.id,
                  child: Text(t.title,
                      style: TextStyle(
                          fontSize: 12,
                          color: t.id == audioTrackId
                              ? const Color(0xFF4C9AFF)
                              : StarColors.ink)),
                ),
            ],
            onSelected: onAudioChanged,
          ),
        if (lines.length > 1)
          PopupMenuButton<String?>(
            tooltip: '线路',
            color: StarColors.surface,
            child: _chip('线路'),
            itemBuilder: (_) => [
              for (final l in lines)
                PopupMenuItem(
                  value: l.id,
                  child: Text(l.title,
                      style: TextStyle(
                          fontSize: 12,
                          color: l.id == lineId
                              ? const Color(0xFF4C9AFF)
                              : StarColors.ink)),
                ),
            ],
            onSelected: onLineChanged,
          ),
        if (onSkipIntro != null)
          TextButton(
            onPressed: onSkipIntro,
            child: const Text('跳过片头',
                style: TextStyle(fontSize: 12, color: StarColors.ink3)),
          ),
        if (onSkipOutro != null)
          TextButton(
            onPressed: onSkipOutro,
            child: const Text('跳过片尾',
                style: TextStyle(fontSize: 12, color: StarColors.ink3)),
          ),
      ],
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: StarColors.ink)),
      );
}

class TrackOption {
  final String id;
  final String title;

  const TrackOption({required this.id, required this.title});
}