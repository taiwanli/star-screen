import 'package:xml/xml.dart';

/// EPG 节目单条目（XMLTV，docs/04 §6.2：`e.xml?ch={name}&date={date}`）。
class EpgProgramme {
  final String channelId;
  final String title;
  final DateTime start;
  final DateTime stop;

  const EpgProgramme({
    required this.channelId,
    required this.title,
    required this.start,
    required this.stop,
  });

  bool playingAt(DateTime at) => !at.isBefore(start) && at.isBefore(stop);
}

/// XMLTV EPG 客户端（实测样本：fanmingming e.xml，generator taksssss/iptv-tool）。
abstract final class EpgClient {
  /// 解析 XMLTV 文本；[channelId] 过滤（如 `CCTV-1`）；[day] 过滤当天节目。
  static List<EpgProgramme> parse(
    String body, {
    String? channelId,
    DateTime? day,
  }) {
    final doc = XmlDocument.parse(body);
    final out = <EpgProgramme>[];
    for (final node in doc.findAllElements('programme')) {
      final id = node.getAttribute('channel') ?? '';
      if (channelId != null && id != channelId) continue;
      final title =
          node.findElements('title').isEmpty ? '' : node.findElements('title').first.innerText.trim();
      final start = _parseTime(node.getAttribute('start'));
      final stop = _parseTime(node.getAttribute('stop'));
      if (start == null || stop == null) continue;
      if (day != null) {
        final local = start.toLocal();
        if (local.year != day.year || local.month != day.month || local.day != day.day) {
          continue;
        }
      }
      out.add(EpgProgramme(channelId: id, title: title, start: start, stop: stop));
    }
    return out;
  }

  /// XMLTV 时间：`20260926000000 +0800`（时区偏移可省略，缺省按本地）。
  static DateTime? _parseTime(String? raw) {
    if (raw == null) return null;
    final digits = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?').firstMatch(raw.trim());
    if (digits == null) return null;
    final offsetMatch = RegExp(r'([+-])(\d{2})(\d{2})?$').firstMatch(raw);
    var value = DateTime.utc(
      int.parse(digits.group(1)!),
      int.parse(digits.group(2)!),
      int.parse(digits.group(3)!),
      int.parse(digits.group(4) ?? '0'),
      int.parse(digits.group(5) ?? '0'),
      int.parse(digits.group(6) ?? '0'),
    );
    if (offsetMatch != null) {
      final sign = offsetMatch.group(1) == '-' ? -1 : 1;
      final hours = int.parse(offsetMatch.group(2) ?? '0');
      final minutes = int.parse(offsetMatch.group(3) ?? '0');
      value = value.subtract(Duration(hours: sign * hours, minutes: sign * minutes));
    }
    return value.toLocal();
  }
}
