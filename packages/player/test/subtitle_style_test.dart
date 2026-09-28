import 'package:star_player/star_player.dart';
import 'package:test/test.dart';

void main() {
  group('SubtitleStyle —— M3-3 样式', () {
    test('copyWith 保留未指定字段；tv 默认 ≥32', () {
      const s = SubtitleStyle();
      final t = s.copyWith(fontSize: 36);
      expect(t.fontSize, 36);
      expect(t.backgroundOpacity, s.backgroundOpacity);
      expect(SubtitleStyle.tv.fontSize, greaterThanOrEqualTo(32));
    });
  });

  group('normalizeSubtitleUri / subtitleTitleFromUri', () {
    test('http/https/file 原样', () {
      expect(normalizeSubtitleUri('https://x/s.srt'), 'https://x/s.srt');
      expect(normalizeSubtitleUri('file:///C:/a.srt'), 'file:///C:/a.srt');
    });

    test('本地路径转 file://', () {
      final u = normalizeSubtitleUri(r'C:\subs\a.srt');
      expect(u, startsWith('file://'));
      expect(subtitleTitleFromUri(u), 'a.srt');
    });
  });
}
