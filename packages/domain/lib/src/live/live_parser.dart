import 'dart:convert';

/// 直播频道解析（docs/04 §6.2；docs/09 M3-5）。
///
/// 支持三种格式：TXT（`组名,#genre#` / `频道名,url`，同名多址 `#` 轮换）、
/// M3U（`#EXTINF` + tvg 属性 + catchup 扩展保留）、JSON 直播表（groups/channels）。
class ParsedLiveChannel {
  final String group;
  final String name;
  final String url;

  /// M3U 的 tvg-id（EPG 关联）
  final String? tvgId;

  /// M3U 的 tvg-logo / TXT 无 logo
  final String? logo;

  const ParsedLiveChannel({
    required this.group,
    required this.name,
    required this.url,
    this.tvgId,
    this.logo,
  });
}

/// 解析结果：频道列表 + （M3U）x-tvg-url 声明的 EPG 地址。
class LiveParseResult {
  final List<ParsedLiveChannel> channels;
  final String? epgUrl;

  const LiveParseResult({required this.channels, this.epgUrl});
}

abstract final class LiveParser {
  /// 自动识别格式并解析。
  static LiveParseResult parse(String body) {
    final head = body.trimLeft();
    if (head.startsWith('#EXTM3U')) return parseM3u(body);
    if (body.contains('#genre#')) return parseTxt(body);
    if (head.startsWith('{')) return parseJson(body);
    throw const FormatException('无法识别的直播源格式');
  }

  /// TXT 格式：`组名,#genre#` 开组，`频道名,url` 行；同名多址 `#` 分隔轮换。
  static LiveParseResult parseTxt(String body) {
    final channels = <ParsedLiveChannel>[];
    var group = '未分组';
    for (var line in body.split('\n')) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('//')) continue;
      if (line.endsWith('#genre#')) {
        group = line.substring(0, line.length - '#genre#'.length).replaceAll('，', ',').split(',').first.trim();
        continue;
      }
      final comma = line.indexOf(',');
      if (comma <= 0) continue;
      final name = line.substring(0, comma).trim();
      final urlPart = line.substring(comma + 1).trim();
      if (name.isEmpty || urlPart.isEmpty) continue;
      for (final url in urlPart.split('#')) {
        final u = url.trim();
        if (u.isEmpty || !u.contains('://')) continue;
        channels.add(ParsedLiveChannel(group: group, name: name, url: u));
      }
    }
    return LiveParseResult(channels: channels);
  }

  /// M3U 格式：#EXTINF 属性 + 下一行地址；x-tvg-url 捕获 EPG。
  static LiveParseResult parseM3u(String body) {
    final epg = RegExp(r'x-tvg-url="([^"]+)"').firstMatch(body)?.group(1);
    final channels = <ParsedLiveChannel>[];
    String? pendingName;
    String? pendingGroup;
    String? pendingId;
    String? pendingLogo;
    for (var raw in body.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTINF')) {
        pendingId = RegExp(r'tvg-id="([^"]*)"').firstMatch(line)?.group(1);
        pendingLogo = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1);
        pendingGroup =
            RegExp(r'group-title="([^"]*)"').firstMatch(line)?.group(1) ??
                '未分组';
        // 显示名 = 逗号后的名称（逗号前为属性区）；回退 tvg-name
        final titlePart = line.split(',').last.trim();
        pendingName = titlePart.isNotEmpty
            ? titlePart
            : RegExp(r'tvg-name="([^"]*)"').firstMatch(line)?.group(1);
        continue;
      }
      if (line.startsWith('#')) continue;
      if (pendingName == null) continue;
      channels.add(ParsedLiveChannel(
        group: pendingGroup!,
        name: pendingName,
        url: line,
        tvgId: (pendingId == null || pendingId.isEmpty) ? null : pendingId,
        logo: (pendingLogo == null || pendingLogo.isEmpty) ? null : pendingLogo,
      ));
      pendingName = null;
      pendingGroup = null;
      pendingId = null;
      pendingLogo = null;
    }
    return LiveParseResult(channels: channels, epgUrl: epg);
  }

  /// JSON 直播表（groups[].channel[] 或 channels[]，社区结构，宽松解析）。
  static LiveParseResult parseJson(String body) {
    final channels = <ParsedLiveChannel>[];
    // 结构 A：{"groups":[{"name"/"group","channels"/"channel":[{"name","urls"/"url"}]}]}
    // 结构 B：{"lives":[{"name","url"}]} —— 由 config_parser 处理，此处不重复
    final doc = _tryDecode(body);
    final groups = doc['groups'] as Object?;
    if (groups is List<Object?>) {
      for (final g in groups) {
        if (g is! Map<String, dynamic>) continue;
        final group = g['name']?.toString() ?? '未分组';
        final list = g['channels'] ?? g['channel'];
        if (list is! List) continue;
        for (final c in list) {
          if (c is! Map<String, dynamic>) continue;
          final name = c['name']?.toString() ?? '';
          final urls = c['urls'] ?? c['url'];
          for (final u in _urlList(urls)) {
            channels.add(ParsedLiveChannel(group: group, name: name, url: u));
          }
        }
      }
    }
    return LiveParseResult(channels: channels);
  }

  static Map<String, dynamic> _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    } on Object {
      return const <String, dynamic>{};
    }
  }

  static List<String> _urlList(Object? urls) {
    if (urls is String) {
      return [for (final u in urls.split('#')) if (u.trim().isNotEmpty) u.trim()];
    }
    if (urls is List) {
      return [for (final u in urls) if (u != null) u.toString()];
    }
    return const [];
  }
}
