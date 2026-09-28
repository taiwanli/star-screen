import 'package:flutter/material.dart';

import 'colors.dart';
import 'interaction.dart';

/// 选集胶囊（iOS Segmented 风格，docs/2.0 §2）。
///
/// 三态：默认 / 悬停抬起 / 选中品牌蓝填充 + 圆点；按下 0.96。
/// 续播集加「继」角标；已看完降透明 + 对勾。
class EpisodeChip extends StatefulWidget {
  const EpisodeChip({
    super.key,
    required this.label,
    required this.selected,
    this.resuming = false,
    this.watched = false,
    this.onTap,
    this.autofocus = false,
  });

  final String label;
  final bool selected;
  final bool resuming;
  final bool watched;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  State<EpisodeChip> createState() => _EpisodeChipState();
}

class _EpisodeChipState extends State<EpisodeChip> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = selected
        ? StarColors.brand
        : _hover
            ? Colors.white
            : StarColors.glass;
    final fg = selected
        ? Colors.white
        : _hover
            ? StarColors.brand
            : StarColors.ink2;

    return Focus(
      autofocus: widget.autofocus,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) {
            setState(() => _down = false);
            StarFeedback.selection();
            widget.onTap?.call();
          },
          child: AnimatedScale(
            scale: StarFeedback.reduceMotion ? 1.0 : _down
                ? Ix.scalePress
                : (_hover && !selected ? Ix.scaleHover : 1.0),
            duration: Ix.micro,
            curve: Ix.easeOut,
            child: AnimatedContainer(
              duration: Ix.micro,
              curve: Ix.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? StarColors.brand
                      : _hover
                          ? StarColors.brand.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.75),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: StarColors.brand.withValues(alpha: 0.35),
                      offset: const Offset(0, 8),
                      blurRadius: 18,
                    )
                  else if (_hover)
                    BoxShadow(
                      color: StarColors.neuDark.withValues(alpha: 0.25),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.watched && !selected
                          ? StarColors.ink4
                          : fg,
                    ),
                  ),
                  if (widget.resuming && !selected) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: StarColors.brandSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('继',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: StarColors.brand)),
                    ),
                  ],
                  if (widget.watched && !selected) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, size: 12, color: StarColors.ink4),
                  ],
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选集条：横滑 + 胶囊 + 悬停/选中反馈。
class EpisodeStrip extends StatelessWidget {
  const EpisodeStrip({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    this.watchedCount = 0,
    this.resumeIndex,
  });

  final List<String> labels;
  final int selectedIndex;
  final void Function(int index) onSelect;
  final int watchedCount;
  final int? resumeIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return EpisodeChip(
            label: labels[i],
            selected: i == selectedIndex,
            resuming: i == resumeIndex && i != selectedIndex,
            watched: i < watchedCount,
            onTap: () => onSelect(i),
          );
        },
      ),
    );
  }
}
