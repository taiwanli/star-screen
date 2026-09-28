import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  test('sidecar 候选列表', () {
    final list = sidecarSubtitleCandidates(r'C:\v\movie.mp4');
    expect(list, hasLength(4));
    expect(list.first, endsWith('movie.srt'));
  });

  test('EpgLoader 模板替换', () async {
    String? got;
    final loader = EpgLoader(getText: (url) async {
      got = url;
      return '<tv></tv>';
    });
    await loader.loadToday(
      template: 'https://e.x/e.xml?ch={name}&date={date}',
      channelName: 'CCTV1',
      day: DateTime(2026, 9, 26),
    );
    expect(got, contains('CCTV1'));
    expect(got, contains('20260926'));
  });
}
