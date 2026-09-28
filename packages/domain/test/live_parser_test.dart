import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('LiveParser —— TXT 格式（fixture：qist tvlive 同构）', () {
    test('分组/频道/同名多址轮换', () {
      final body = fixture('live_tv.txt').readAsStringSync();
      final result = LiveParser.parse(body);

      expect(result.channels, hasLength(4)); // CCTV-1..CCTV-2×2 + 湖南 = 4 地址行
      expect(result.channels.first.group, '央视频道');
      expect(result.channels.first.name, 'CCTV-1');
      // 同名多址：CCTV-2 一行两个地址 → 两条频道记录
      expect(
        result.channels.where((c) => c.name == 'CCTV-2').length,
        2,
      );
      expect(
        result.channels.any((c) => c.group == '卫视频道'),
        isTrue,
      );
    });
  });

  group('LiveParser —— M3U 格式（fixture：fanmingming 同构）', () {
    test('EXTINF 属性解析 + EPG 捕获', () {
      final body = fixture('live.m3u').readAsStringSync();
      final result = LiveParser.parse(body);

      expect(result.epgUrl, 'https://epg.example.com/e.xml');
      expect(result.channels, hasLength(2));
      expect(result.channels.first.name, 'CCTV-1综合');
      expect(result.channels.first.group, '央视频道');
      expect(result.channels.first.tvgId, 'CCTV1');
      expect(result.channels.first.logo, 'https://logo.example.com/CCTV1.png');
      expect(result.channels.first.url, 'http://[2408:8540::1]/pltv/cctv1.m3u8');
    });
  });

  group('LiveParser —— JSON 直播表（社区结构，宽松解析）', () {
    test('groups[].channels[].urls', () {
      const body = '{"groups":[{"name":"央视频道","channels":['
          '{"name":"CCTV-1","urls":["http://a/1.m3u8","http://b/1.m3u8"]},'
          '{"name":"CCTV-2","urls":"http://a/2.m3u8"}]}]}';
      final result = LiveParser.parse(body);
      expect(result.channels, hasLength(3));
      expect(result.channels.first.group, '央视频道');
      expect(result.channels[1].url, 'http://b/1.m3u8');
      expect(result.channels[2].url, 'http://a/2.m3u8');
    });
  });

  group('LiveParser —— 容错', () {
    test('未知格式抛 FormatException', () {
      expect(() => LiveParser.parse('<html>not live</html>'),
          throwsA(isA<FormatException>()));
    });

    test('TXT 忽略空行与 // 注释行', () {
      const body = '// 注释\n\n央视频道,#genre#\n\nCCTV-1,http://a/1.m3u8\n';
      final result = LiveParser.parse(body);
      expect(result.channels, hasLength(1));
    });
  });
}
