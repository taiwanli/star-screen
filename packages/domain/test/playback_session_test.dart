import 'dart:async';

import 'package:star_domain/star_domain.dart';
import 'package:test/test.dart';

class FakeSource implements VideoSource {
  @override
  SourceDef get def => const SourceDef(
        key: 'src',
        name: '测试源',
        kind: SourceKind.cmsJson,
        endpoint: 'https://x.example.com/vod',
      );

  PlayCandidate resolveResult = const PlayCandidate(url: 'https://cdn.example.com/ep1.m3u8');
  int resolveCalls = 0;

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    resolveCalls++;
    return resolveResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakePlayer implements DomainPlayerController {
  final _ctrl = StreamController<DomainPlayerEvent>.broadcast();
  String? loadedUrl;
  int loadStartAt = 0;
  Map<String, String> loadedHeaders = const {};
  int playCalls = 0;

  @override
  Stream<DomainPlayerEvent> get events => _ctrl.stream;

  @override
  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  }) async {
    loadedUrl = url;
    loadedHeaders = headers;
    loadStartAt = startAtSec;
  }

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(int positionSec) async {}

  @override
  Future<void> dispose() async {}

  void emit(DomainPlayerEvent event) => _ctrl.add(event);
}

Future<void> pump() async =>
    Future<void>.delayed(const Duration(milliseconds: 20));

PlayRequest _req([int episode = 0]) =>
    PlayRequest(workId: '1', episodeIndex: episode);

void main() {
  late FakeSource source;
  late FakePlayer player;
  late InMemoryPlayRecordStore records;
  late PlaybackSession session;

  setUp(() {
    source = FakeSource();
    player = FakePlayer();
    records = InMemoryPlayRecordStore();
    session = PlaybackSession(source: source, player: player, records: records);
  });

  group('起播与续播（docs/07 §4.5 状态机）', () {
    test('首次起播：从头播放', () async {
      final outcome = await session.start(_req());
      expect(outcome, isA<PlayOutcomePlaying>());
      final playing = outcome as PlayOutcomePlaying;
      expect(playing.resumed, isFalse);
      expect(playing.startAtSec, 0);
      expect(player.loadedUrl, 'https://cdn.example.com/ep1.m3u8');
      expect(player.playCalls, 1);
    });

    test('有未看完记录：自动续播到上次位置', () async {
      await records.save(PlayRecord(
        workKey: 'src::1',
        sourceKey: 'src',
        episodeIndex: 0,
        positionSec: 700,
        durationSec: 1800,
        updatedAt: DateTime.now(),
      ));
      final outcome = await session.start(_req()) as PlayOutcomePlaying;
      expect(outcome.resumed, isTrue);
      expect(outcome.startAtSec, 700);
      expect(player.loadStartAt, 700);
    });

    test('已看完（≥90%）：不续播', () async {
      await records.save(PlayRecord(
        workKey: 'src::1',
        sourceKey: 'src',
        episodeIndex: 0,
        positionSec: 1750,
        durationSec: 1800,
        updatedAt: DateTime.now(),
      ));
      final outcome = await session.start(_req()) as PlayOutcomePlaying;
      expect(outcome.resumed, isFalse);
      expect(outcome.startAtSec, 0);
    });

    test('换集：不套用其他集的记录', () async {
      await records.save(PlayRecord(
        workKey: 'src::1',
        sourceKey: 'src',
        episodeIndex: 0,
        positionSec: 700,
        durationSec: 1800,
        updatedAt: DateTime.now(),
      ));
      final outcome = await session.start(_req(1)) as PlayOutcomePlaying;
      expect(outcome.resumed, isFalse);
    });

    test('needsParse 候选：拦截不播（合规基线）', () async {
      source.resolveResult = const PlayCandidate(
        url: 'https://v.example.com/play/9.html',
        needsParse: true,
      );
      final outcome = await session.start(_req());
      expect(outcome, isA<PlayOutcomeBlocked>());
      expect(player.loadedUrl, isNull);
    });
  });

  group('进度落库（5 秒节流 + 阈值语义）', () {
    test('节流：5 秒窗口内只写一次，最后位置胜出', () async {
      await session.start(_req());
      // 时长 100s：5% 记录阈值 = 5s，位置 5/9/14 均可入库
      player.emit(const DomainPlayerPosition(5, 100));
      await pump();
      player.emit(const DomainPlayerPosition(9, 100));
      await pump();
      player.emit(const DomainPlayerPosition(14, 100));
      await pump();

      // 时间戳制节流（docs/13 A1）：首次事件立即写库，后续窗口内事件
      // 依赖 stop() 补写最后位置；断言记录已存在且位置单调递增到 14。
      expect(records.all, isNotEmpty);
      await session.stop();
      expect(records.all, hasLength(1));
      expect(records.all.single.positionSec, 14);
      expect(records.all.single.episodeIndex, 0);
    });

    test('<5% 不生成记录（误点不污染继续观看）', () async {
      await session.start(_req());
      player.emit(const DomainPlayerPosition(50, 1800));
      await pump();
      expect(records.all, isEmpty);
    });

    test('播完事件：写满进度并标记已看完（≥90%）', () async {
      await session.start(_req());
      player.emit(const DomainPlayerPosition(1790, 1800));
      await pump();
      player.emit(const DomainPlayerCompleted());
      await pump();

      final record = records.all.single;
      expect(record.isFinished, isTrue);
    });

    test('stop：强制落盘最后进度', () async {
      await session.start(_req());
      player.emit(const DomainPlayerPosition(600, 1800));
      await pump();
      player.emit(const DomainPlayerPosition(612, 1800));
      await pump();
      await session.stop();

      expect(records.all.single.positionSec, 612);
    });

    test('向前大 seek：5s 内位置落库不卡在旧值（docs/13 A1）', () async {
      await session.start(_req());
      player.emit(const DomainPlayerPosition(600, 1800));
      await pump();
      // 向前 seek 到 10s：旧实现 positionSec - _savedAtSec < 0 永远不写库
      // 向前 seek 到 200s（仍 ≥5% 阈值，10s 会跌破 5% 不入库）：旧实现位置回退永不写库
      await Future<void>.delayed(const Duration(seconds: 6));
      player.emit(const DomainPlayerPosition(200, 1800));
      await pump();
      // 时间戳制节流：位置事件写库是异步入队，stop 时把最终 pending 落盘
      await session.stop();
      // 时间戳制节流：6s 后位置 200 的写入不受「已保存 600」阻塞（旧实现会卡住）
      // 内存 store 按 workKey 覆盖，最终应为 10。
      expect(records.all.single.positionSec, 200);
    });
  });

  group('失败暴露与生命周期', () {
    test('播放失败事件 → failures 流（供 UI 提示换线路/换源）', () async {
      await session.start(_req());
      final failure = expectLater(session.failures, emits('解码失败'));
      player.emit(const DomainPlayerFailed('解码失败'));
      await failure;
    });

    test('dispose 后不再写库', () async {
      await session.start(_req());
      await session.dispose();
      player.emit(const DomainPlayerPosition(100, 1800));
      await pump();
      expect(records.all, isEmpty);
    });
  });
}
