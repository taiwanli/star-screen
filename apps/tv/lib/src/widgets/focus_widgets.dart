import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import 'tv_focus_engine.dart';

/// TV 端焦点组件（三重信号：缩放 1.06 + 3px 描边 + 阴影，规范 F5）。
/// 提供 [focusId] 时接入焦点记忆（F3，TvFocusScope）。

class TvFocusChip extends StatelessWidget {
  final String label;
  final bool isNavSelected;
  final VoidCallback onSelect;
  final String? focusId;

  const TvFocusChip({
    super.key,
    required this.label,
    required this.isNavSelected,
    required this.onSelect,
    this.focusId,
  });

  @override
  Widget build(BuildContext context) {
    final node = focusId == null
        ? null
        : TvFocusScope.maybeOf(context)?.register(focusId!);
    return Focus(
      focusNode: node,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedScale(
            scale: hasFocus ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: hasFocus ? StarColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFocus
                      ? StarColors.brandHi
                      : (isNavSelected ? StarColors.lineStrong : Colors.transparent),
                  width: 3,
                ),
                boxShadow: hasFocus
                    ? const [BoxShadow(blurRadius: 40, color: Color(0x8C000000))]
                    : null,
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: hasFocus ? StarColors.ink : StarColors.ink2)),
            ),
          );
        },
      ),
    );
  }
}

/// 横版卡（TV 专用 16:9）+ 聚焦展开副信息。
class TvFocusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? progress;
  final int hueSeed;
  final String? imageUrl;
  final VoidCallback? onTap;
  final String? focusId;

  const TvFocusCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.progress,
    this.hueSeed = 0,
    this.imageUrl,
    this.onTap,
    this.focusId,
  });

  static const _gradients = <List<Color>>[
    [Color(0xFFD6E4F7), Color(0xFFB8CCE8)],
    [Color(0xFFDCEFF7), Color(0xFFB0D0E0)],
    [Color(0xFFF7E8DC), Color(0xFFE8C9B5)],
    [Color(0xFFE8DFF7), Color(0xFFC9B8E8)],
  ];

  @override
  Widget build(BuildContext context) {
    final g = _gradients[hueSeed.clamp(0, _gradients.length - 1)];
    final node = focusId == null
        ? null
        : TvFocusScope.maybeOf(context)?.register(focusId!);
    return Focus(
      focusNode: node,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) &&
            onTap != null) {
          onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return SizedBox(
            width: 480,
            child: AnimatedScale(
              scale: hasFocus ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: g,
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (imageUrl != null)
                                  Positioned.fill(
                                    child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0',
                  },
                  cacheWidth: 480,
                  filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, _, _) => _fallbackChar(),
                                    ),
                                  )
                                else
                                  _fallbackChar(),
                                if (progress != null)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: ColoredBox(
                                      color: const Color(0x38FFFFFF),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress!.clamp(0.0, 1.0),
                                        child: Container(
                                            height: 6, color: StarColors.brandHi),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (hasFocus)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: StarColors.brandHi, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 40, color: Color(0x8C000000)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 24, color: StarColors.ink)),
                    // 聚焦时展开副信息（docs/07 §4.1）
                    AnimatedOpacity(
                      opacity: hasFocus ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 20, color: StarColors.ink3)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackChar() => Center(
        child: Text(title.characters.first,
            style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w500,
                color: Color(0x8CF7F8FA))),
      );
}
