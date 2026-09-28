import 'dart:io';

import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';

Future<void> main() async {
  stdout.writeln('== TVBox 导入流程 ==');
  const ref = 'http://home.jundie.top:81/top98.json';
  final fetcher = FeedFetcher();
  final raw = await fetcher.fetchSubscription(ref);
  final report = TvBoxConfigParser.parse(raw: raw.body, baseUrl: raw.url);
  stdout.writeln('sites=${report.sources.length} lives=${report.lives.length}');
  final db = StarDatabase.memory();
  final registry = SourceRegistry(store: DriftSourceDefStore(db));
  await registry.applyReport(report);
  final enabled = await registry.enabled();
  stdout.writeln('enabled=${enabled.length}');
  final adaptable = enabled.where((s) => s.kind.hasAdapter).toList();
  for (final s in adaptable) {
    try {
      final src = switch (s.kind) {
        SourceKind.cmsJson => CmsJsonSource(def: s),
        SourceKind.cmsXml => CmsXmlSource(def: s),
        SourceKind.drpyJs => null,
        _ => null,
      };
      if (src == null) {
        stdout.writeln('${s.name}: drpy 需沙箱，跳过');
        continue;
      }
      final home = await src.home();
      stdout.writeln('${s.name}: 首页 ${home.recommend.length} 条');
      if (home.recommend.isNotEmpty) {
        final d = await src.detail(home.recommend.first.workId);
        final play = await src.resolve(PlayRequest(workId: home.recommend.first.workId, episodeIndex: 0));
        stdout.writeln('  播放: ${play.url} needsParse=${play.needsParse}');
      }
    } on Object catch (e) {
      stdout.writeln('${s.name}: 浏览失败（源侧）: $e');
    }
  }
  stdout.writeln('== 导入+浏览流程完成 ==');
}
