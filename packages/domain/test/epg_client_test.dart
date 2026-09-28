

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('EpgClient —— XMLTV 解析（M3-5 EPG 客户端）', () {
    late String body;

    setUp(() {
      body = fixture('epg_sample.xml').readAsStringSync();
    });

    test('全量解析：标题/起止时间/频道', () {
      final all = EpgClient.parse(body);
      expect(all, hasLength(3));
      expect(all.first.channelId, 'CCTV-1');
      expect(all.first.title, '新闻30分');
      // +0800 偏移换算为本地时间
      expect(all.first.start.hour, 12);
    });

    test('按频道过滤', () {
      final hn = EpgClient.parse(body, channelId: 'HNWS');
      expect(hn, hasLength(1));
      expect(hn.single.title, '黄金剧场');
    });

    test('按日期过滤', () {
      final list = EpgClient.parse(body, day: DateTime(2026, 9, 26));
      expect(list, hasLength(3));
      final none = EpgClient.parse(body, day: DateTime(2026, 9, 1));
      expect(none, isEmpty);
    });

    test('playingAt 判断当前播出', () {
      final list = EpgClient.parse(body, channelId: 'CCTV-1');
      final within = list[1].playingAt(DateTime(2026, 9, 26, 13, 30));
      expect(within, isTrue);
      expect(list[0].playingAt(DateTime(2026, 9, 26, 13, 30)), isFalse);
    });
  });
}
