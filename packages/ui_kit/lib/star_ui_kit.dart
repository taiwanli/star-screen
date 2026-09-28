import 'package:flutter/material.dart';
import 'src/colors.dart';
import 'src/network_image.dart';

export 'src/cast_ui.dart';
export 'src/colors.dart';
export 'src/epg_ui.dart';
export 'src/lan_ui.dart';
export 'src/library_ui.dart';
export 'src/liquid_neu.dart';
export 'src/playback_ui.dart';
export 'src/network_image.dart';
export 'src/player_chrome.dart';
export 'src/player_extras_ui.dart';
export 'src/subtitle_ui.dart';

/// 端形态 —— 决定令牌取值（docs/07 §2.2 端覆盖）。
enum StarFormFactor { desktop, mobile, tv }

/// 尺寸令牌（sys-*，端覆盖发生在工厂构造处，组件禁止硬编码）。
class StarSizeSpec {
  final double bodyFontSize;
  final double controlHeightSm;
  final double controlHeightMd;
  final double controlHeightLg;
  final double pageMargin;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double iconStroke;
  final double focusStroke;
  final double gap;
  final double safeArea; // TV=48（5% overscan），其余端 0
  final Duration durationBase;

  const StarSizeSpec({
    required this.bodyFontSize,
    required this.controlHeightSm,
    required this.controlHeightMd,
    required this.controlHeightLg,
    required this.pageMargin,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.iconStroke,
    required this.focusStroke,
    required this.gap,
    required this.safeArea,
    required this.durationBase,
  });

  /// 桌面端（docs/07 §2.2 表）。
  static const desktop = StarSizeSpec(
    bodyFontSize: 14,
    controlHeightSm: 32,
    controlHeightMd: 36,
    controlHeightLg: 40,
    pageMargin: 24,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 12,
    iconStroke: 1.5,
    focusStroke: 2,
    gap: 16,
    safeArea: 0,
    durationBase: Duration(milliseconds: 200),
  );

  /// 手机端（sp 值按 1.0 基准由系统字体缩放处理）。
  static const mobile = StarSizeSpec(
    bodyFontSize: 16,
    controlHeightSm: 40,
    controlHeightMd: 48,
    controlHeightLg: 56,
    pageMargin: 16,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 12,
    iconStroke: 2,
    focusStroke: 0,
    gap: 16,
    safeArea: 0,
    durationBase: Duration(milliseconds: 200),
  );

  /// TV 端：所有视觉属性等比放大（规范 5.3 换算表），圆角 ×1.5、描边 ×3。
  static const tv = StarSizeSpec(
    bodyFontSize: 24,
    controlHeightSm: 72,
    controlHeightMd: 88,
    controlHeightLg: 88,
    pageMargin: 96, // 48px 安全区 + 48px 布局边距
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 18,
    iconStroke: 3,
    focusStroke: 3,
    gap: 32,
    safeArea: 48,
    durationBase: Duration(milliseconds: 300),
  );
}

/// 令牌包 —— 组件只引用 StarTokens，不感知端。
class StarTokens {
  final StarFormFactor formFactor;
  final StarSizeSpec sizes;

  const StarTokens({required this.formFactor, required this.sizes});

  factory StarTokens.forFormFactor(StarFormFactor f) => StarTokens(
        formFactor: f,
        sizes: switch (f) {
          StarFormFactor.desktop => StarSizeSpec.desktop,
          StarFormFactor.mobile => StarSizeSpec.mobile,
          StarFormFactor.tv => StarSizeSpec.tv,
        },
      );
}

/// 主题注入。UI 树任意位置 `StarTheme.of(context)` 取令牌。
class StarTheme extends InheritedWidget {
  final StarTokens tokens;

  const StarTheme({super.key, required this.tokens, required super.child});

  static StarTokens of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StarTheme>()!.tokens;

  static StarFormFactor formFactorOf(BuildContext context) =>
      of(context).formFactor;

  @override
  bool updateShouldNotify(StarTheme oldWidget) =>
      oldWidget.tokens.formFactor != tokens.formFactor ||
      oldWidget.tokens.sizes != tokens.sizes;
}

/// 星映 MaterialApp 预设：液态玻璃 + 新拟态浅色（docs/15）。
ThemeData starThemeData(StarTokens tokens, {Brightness brightness = Brightness.light}) {
  final s = tokens.sizes;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: StarColors.page,
    colorScheme: const ColorScheme.light(
      primary: StarColors.brand,
      onPrimary: Colors.white,
      secondary: StarColors.brandHi,
      surface: StarColors.surface,
      onSurface: StarColors.ink,
      error: StarColors.bad,
    ),
    fontFamily: tokens.formFactor == StarFormFactor.desktop
        ? 'Segoe UI'
        : null,
    textTheme: Typography.material2021(platform: TargetPlatform.android)
        .englishLike
        .apply(
          bodyColor: StarColors.ink,
          displayColor: StarColors.ink,
        )
        .copyWith(
          bodyMedium: TextStyle(
              fontSize: s.bodyFontSize,
              height: 1.6,
              color: StarColors.ink,
              fontWeight: FontWeight.w400),
        ),
    dividerColor: StarColors.line,
    splashFactory: tokens.formFactor == StarFormFactor.mobile
        ? InkSparkle.splashFactory
        : NoSplash.splashFactory,
  );
}

/// 内容卡片的两种素材比例（规范 6.1：2:3 海报 / 16:9 横版）。
enum StarCardShape { poster, landscape }

/// 海报/横版卡 —— 内置规范 6.9 的「缺失图兜底」：
/// 品牌色系底 + 标题首字 + 类型标签；可选角标与进度条（TV 6px / 其余 2px）。
class StarPoster extends StatelessWidget {
  final String title;
  final String? subtitle; // 副信息：年份 · 地区 · 分类 / 第 N 集 · 剩余 M 分钟
  final StarCardShape shape;
  final int hueSeed; // 兜底渐变色族（0-7）
  final String? typeLabel; // 影片 / 剧集 / 综艺…
  final String? badgeText; // 角标（≤2，规范 6.1）
  final bool badgeTrailing; // true=右上（状态类），false=左上（来源类）
  final double? progress; // 0-1，仅继续观看卡
  final VoidCallback? onTap;

  /// 真实海报地址；加载失败自动回退「缺失图兜底」（规范 6.9）。
  final String? imageUrl;

  /// 固定宽度。横滑列表中必须提供（AspectRatio 在双向无界约束下无法布局）；
  /// 竖排网格可省略（由父级栅格约束）。
  final double? width;

  const StarPoster({
    super.key,
    required this.title,
    this.subtitle,
    this.shape = StarCardShape.poster,
    this.hueSeed = 0,
    this.typeLabel,
    this.badgeText,
    this.badgeTrailing = true,
    this.progress,
    this.onTap,
    this.width,
    this.imageUrl,
  });

  static const _gradients = <List<Color>>[
    [Color(0xFFD6E4F7), Color(0xFFB8CCE8)],
    [Color(0xFFDCEEF8), Color(0xFFB5D4E8)],
    [Color(0xFFE8DFF7), Color(0xFFC9B8E8)],
    [Color(0xFFF7E8DC), Color(0xFFE8C9B5)],
    [Color(0xFFF7DCDC), Color(0xFFE8B8B8)],
    [Color(0xFFDCEFF7), Color(0xFFB0D0E0)],
    [Color(0xFFF7F0DC), Color(0xFFE0D0A8)],
    [Color(0xFFDCF7E8), Color(0xFFB0E0C8)],
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = StarTheme.of(context);
    final s = tokens.sizes;
    final g = _gradients[hueSeed.clamp(0, _gradients.length - 1)];

    Widget cover = AspectRatio(
      aspectRatio: shape == StarCardShape.poster ? 2 / 3 : 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: g,
          ),
          borderRadius: BorderRadius.circular(s.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: StarColors.neuDark.withValues(alpha: 0.45),
              offset: const Offset(4, 6),
              blurRadius: 16,
            ),
            BoxShadow(
              color: StarColors.neuLight.withValues(alpha: 0.9),
              offset: const Offset(-3, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            if (imageUrl != null)
              Positioned.fill(
                child: StarNetworkImage(
                  url: imageUrl!,
                  fit: BoxFit.cover,
                  // 缩略图解码上限，避免全尺寸位图进内存（性能）
                  cacheWidth: shape == StarCardShape.poster ? 400 : 640,
                  fallback: _fallbackChar(shape),
                ),
              )
            else
              _fallbackChar(shape),
            if (typeLabel != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: _Badge(
                  label: typeLabel!,
                  background: StarColors.scrim,
                  color: StarColors.ink3,
                  radius: s.radiusSm,
                ),
              ),
            if (badgeText != null)
              Positioned(
                top: 8,
                right: badgeTrailing ? 8 : null,
                left: badgeTrailing ? null : 8,
                child: _Badge(
                  label: badgeText!,
                  background: StarColors.scrim,
                  color: StarColors.ink,
                  radius: s.radiusSm,
                ),
              ),
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
                      height: tokens.formFactor == StarFormFactor.tv ? 6 : 2,
                      color: StarColors.brandHi,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // 横滑列表：以固定宽度解析封面（docs/07 §4.1 横版/海报卡宽度即规范值）
    if (width != null) {
      cover = SizedBox(width: width, child: cover);
    }

    final titleStyle = TextStyle(
      fontSize: s.bodyFontSize,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: StarColors.ink,
    );
    final subStyle = TextStyle(
      fontSize: s.bodyFontSize - 2,
      color: StarColors.ink3,
    );

    // 悬停放大 / 移开还原（docs/19 P0）
    return HoverScale(
      onTap: onTap,
      scaleUp: 1.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(title,
                style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(subtitle!, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }

  Widget _fallbackChar(StarCardShape shape) => Center(
        child: Text(
          title.characters.first,
          style: TextStyle(
            fontSize: shape == StarCardShape.poster ? 44 : 34,
            fontWeight: FontWeight.w600,
            color: const Color(0x8CF7F8FA),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;
  final double radius;

  const _Badge({
    required this.label,
    required this.background,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

/// 悬停缩放：进入放大 [scaleUp]，离开恢复（docs/19 P0 · 海报微交互）。
class HoverScale extends StatefulWidget {
  const HoverScale({
    super.key,
    required this.child,
    this.scaleUp = 1.03,
    this.duration = const Duration(milliseconds: 160),
    this.onTap,
  });

  final Widget child;
  final double scaleUp;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? widget.scaleUp : 1.0,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
