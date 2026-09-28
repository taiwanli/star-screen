import 'package:flutter/material.dart';

/// 统一网络图片（海报/头图）：补全请求头、加载态、失败可重试。
///
/// 解决：部分图床无 Referer/浏览器 UA 拒绝；协议相对地址 `//cdn/...`；
/// 失败后只剩色块无法诊断。
class StarNetworkImage extends StatefulWidget {
  const StarNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.referer,
    this.borderRadius,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// 解码宽度上限，避免 4K 原图进内存。
  final int? cacheWidth;

  /// 默认用 url 的 origin 作 Referer。
  final String? referer;

  final BorderRadius? borderRadius;
  final Widget? fallback;

  /// 归一：协议相对 / 空白。
  static String? normalize(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('//')) s = 'https:$s';
    return s;
  }

  @override
  State<StarNetworkImage> createState() => _StarNetworkImageState();
}

class _StarNetworkImageState extends State<StarNetworkImage> {
  int _retry = 0;

  Map<String, String> get _headers {
    final url = widget.url;
    String? referer = widget.referer;
    if (referer == null) {
      try {
        final u = Uri.parse(url);
        if (u.host.isNotEmpty) {
          referer = '${u.scheme}://${u.host}/';
        }
      } on Object {
        referer = null;
      }
    }
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      if (referer != null) 'Referer': referer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final normalized = StarNetworkImage.normalize(widget.url);
    if (normalized == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    final image = Image.network(
      normalized,
      key: ValueKey('$_retry|$normalized'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      cacheWidth: widget.cacheWidth,
      filterQuality: FilterQuality.medium,
      headers: _headers,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        final fb = widget.fallback;
        return GestureDetector(
          onTap: () => setState(() => _retry++),
          child: fb ??
              const ColoredBox(
                color: Color(0xFF20262E),
                child: Center(
                  child: Icon(Icons.refresh, size: 22, color: Colors.white38),
                ),
              ),
        );
      },
    );
    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }
}
