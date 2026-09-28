/// `starrule://import?url=...` 深链协议（docs/18 §8 P2）。
///
/// 形态：
///   starrule://import?url=https%3A%2F%2F...%2Fpack.json
///   starrule://import?src=https://.../pack.json
///   starrule://import?url=<已粘贴的 JSON 原文>（不推荐，体量大）
library;

class StarRuleDeepLink {
  const StarRuleDeepLink._();

  static const scheme = 'starrule';
  static const host = 'import';

  /// 是否为星映导入深链。
  static bool isImportLink(String text) {
    final t = text.trim();
    return t.toLowerCase().startsWith('$scheme://$host');
  }

  /// 解析出订阅地址 / 规则原文。
  ///
  /// 返回 `url`（远程地址）或 `inline`（JSON 原文）；两者皆空则非法。
  static ({String? url, String? inline}) parse(String text) {
    final t = text.trim();
    if (!isImportLink(t)) return (url: null, inline: null);
    final uri = Uri.tryParse(t);
    if (uri == null) return (url: null, inline: null);
    final url = uri.queryParameters['url'] ??
        uri.queryParameters['src'] ??
        uri.queryParameters['href'];
    final inline = uri.queryParameters['inline'] ??
        uri.queryParameters['json'] ??
        uri.queryParameters['data'];
    return (url: url, inline: inline);
  }

  /// 组装深链（分享/导出用）。
  static String build(String target, {bool isInline = false}) {
    if (isInline) {
      return Uri(
        scheme: scheme,
        host: host,
        queryParameters: {'inline': target},
      ).toString();
    }
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {'url': target},
    ).toString();
  }
}
