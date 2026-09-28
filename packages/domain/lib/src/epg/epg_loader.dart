import 'epg_client.dart';

/// EPG 节目单加载（docs/02 §4.5）：模板 URL + 频道名/日期替换。
class EpgLoader {
  EpgLoader({required this.getText});

  /// 拉取文本（HTTP 实现由端注入）。
  final Future<String> Function(String url) getText;

  /// [template] 形如 `https://epg.example/e.xml?ch={name}&date={date}`。
  Future<List<EpgProgramme>> loadToday({
    required String template,
    required String channelName,
    String? channelId,
    DateTime? day,
  }) async {
    final d = day ?? DateTime.now();
    final date =
        '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final url = template
        .replaceAll('{name}', Uri.encodeComponent(channelName))
        .replaceAll('{date}', date);
    final body = await getText(url);
    return EpgClient.parse(body, channelId: channelId ?? channelName, day: d);
  }
}

/// 同目录外挂字幕自动匹配（docs/02 §4.3 P1）：
/// 对本地视频路径找同名 `.srt/.ass/.ssa/.vtt`。
String? matchSidecarSubtitle(String videoPath) {
  const exts = ['.srt', '.ass', '.ssa', '.vtt'];
  final dot = videoPath.lastIndexOf('.');
  final slash = videoPath.lastIndexOf(RegExp(r'[/\\]'));
  if (dot <= slash) return null;
  final stem = videoPath.substring(0, dot);
  for (final e in exts) {
    final candidate = '$stem$e';
    // 仅返回路径约定，是否存在由调用方/播放器判断
    return candidate;
  }
  return null;
}

/// 列出候选同名字幕（供 UI 选择）。
List<String> sidecarSubtitleCandidates(String videoPath) {
  const exts = ['.srt', '.ass', '.ssa', '.vtt'];
  final dot = videoPath.lastIndexOf('.');
  final slash = videoPath.lastIndexOf(RegExp(r'[/\\]'));
  if (dot <= slash) return const [];
  final stem = videoPath.substring(0, dot);
  return [for (final e in exts) '$stem$e'];
}
