import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

void main() {
  test('copyProgressTo 跨源迁移进度', () async {
    final store = InMemoryPlayRecordStore();
    final from = WorkCard(sourceKey: 'a', workId: '1', title: '片');
    final to = WorkCard(sourceKey: 'b', workId: '9', title: '片');
    await store.save(PlayRecord(
      workKey: from.workKey,
      sourceKey: 'a',
      episodeIndex: 3,
      positionSec: 600,
      durationSec: 1800,
      updatedAt: DateTime.now(),
    ));
    final out = await store.copyProgressTo(
      fromKey: from.workKey,
      toCard: to,
      maxEpisodeIndex: 2,
    );
    expect(out, isNotNull);
    expect(out!.workKey, to.workKey);
    expect(out.episodeIndex, 2); // 钳制
    expect(out.positionSec, 600);
    expect(out.durationSec, 1800);
    final loaded = await store.get(to.workKey);
    expect(loaded?.episodeIndex, 2);
  });

  test('copyProgressTo 时长缩放并钳制 position', () async {
    final store = InMemoryPlayRecordStore();
    final from = WorkCard(sourceKey: 'a', workId: '1', title: '片');
    final to = WorkCard(sourceKey: 'b', workId: '9', title: '片');
    await store.save(PlayRecord(
      workKey: from.workKey,
      sourceKey: 'a',
      episodeIndex: 0,
      positionSec: 5000,
      durationSec: 6000,
      updatedAt: DateTime.now(),
    ));
    final out = await store.copyProgressTo(
      fromKey: from.workKey,
      toCard: to,
      durationScale: 0.5, // 新源时长一半
    );
    expect(out!.durationSec, 3000);
    expect(out.positionSec, 2999); // 钳到时长-1
  });
}
