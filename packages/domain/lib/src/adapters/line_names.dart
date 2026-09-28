/// 播放组标识 → 展示名对照（docs/05 §6.1「线路名映射为人话 + 原样兜底」）。
///
/// `vod_play_from` 的值是 CMS 后台的播放器编码；这里维护常见编码的对照表，
/// 未收录的编码原样展示。
abstract final class LineNames {
  static const _map = <String, String>{
    'bfzym3u8': '暴风m3u8',
    'bfm3u8': '暴风m3u8',
    'snm3u8': '索尼m3u8',
    'zuidam3u8': '最大m3u8',
    'ffm3u8': '非凡m3u8',
    'kuaikanm3u8': '快看m3u8',
    'wolongm3u8': '卧龙m3u8',
    'lem3u8': '乐m3u8',
    'sdm3u8': '闪电m3u8',
    'xlm3u8': '新浪m3u8',
    'dbm3u8': '豆瓣m3u8',
    'm3u8': 'm3u8',
    'mp4': 'mp4',
  };

  static String display(String raw) {
    final key = raw.trim().toLowerCase();
    return _map[key] ?? raw.trim();
  }
}
