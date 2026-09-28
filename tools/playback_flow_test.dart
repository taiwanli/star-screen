import 'dart:io';

import 'package:star_domain/star_domain.dart';

/// 测试源播放流程：导入 CMS → 首页 → 搜索 → 详情 → 解析播放地址（docs/06）。
Future<void> main() async {
  const endpoint = 'https://bfzyapi.com/api.php/provide/vod';
  final def = SourceDef(
    key: 'bfzy',
    name: '暴风测试源',
    kind: SourceKind.cmsJson,
    endpoint: endpoint,
    headers: const {'User-Agent': 'StarScreen/0.1'},
    timeoutSec: 15,
  );
  final source = CmsJsonSource(def: def);

  stdout.writeln('== 1. 首页推荐 ==');
  final home = await source.home();
  stdout.writeln('推荐数: ${home.recommend.length}');
  if (home.recommend.isEmpty) {
    stderr.writeln('FAIL: 首页为空');
    exit(1);
  }
  final first = home.recommend.first;
  stdout.writeln('样例: ${first.title} id=${first.workId}');

  stdout.writeln('== 2. 搜索 ==');
  final search = await source.search('爱');
  stdout.writeln('搜索命中: ${search.items.length} (page=${search.page})');
  final hit = search.items.isNotEmpty ? search.items.first : first;
  stdout.writeln('选用: ${hit.title} id=${hit.workId}');

  stdout.writeln('== 3. 详情 ==');
  final detail = await source.detail(hit.workId);
  stdout.writeln('标题: ${detail.card.title}');
  stdout.writeln('线路: ${detail.lines.map((l) => '${l.name}(${l.episodes.length})').join(', ')}');
  if (detail.lines.isEmpty || detail.lines.first.episodes.isEmpty) {
    stderr.writeln('FAIL: 无播放线路');
    exit(1);
  }
  final ep = detail.lines.first.episodes.first;
  stdout.writeln('选集: ${ep.name} ${ep.url}');

  stdout.writeln('== 4. 解析播放地址 ==');
  final play = await source.resolve(PlayRequest(workId: hit.workId, episodeIndex: 0));
  stdout.writeln('url: ${play.url}');
  stdout.writeln('needsParse: ${play.needsParse}');
  if (play.url.isEmpty) {
    stderr.writeln('FAIL: 无播放地址');
    exit(1);
  }
  if (play.needsParse) {
    stdout.writeln('提示: 非直链，合规默认过滤');
  } else {
    stdout.writeln('直链媒体，可交给播放器');
    // 尝试 HTTP HEAD 验证地址可达
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final req = await client.headUrl(Uri.parse(play.url));
      req.headers.set('User-Agent', 'VLC/3.0.0');
      final res = await req.close().timeout(const Duration(seconds: 10));
      stdout.writeln('媒体 HEAD: ${res.statusCode} ${res.headers.contentType ?? ''}');
      await res.drain<void>();
      client.close(force: true);
    } on Object catch (e) {
      stdout.writeln('媒体 HEAD 失败（不影响流程）: $e');
    }
  }
  stdout.writeln('== 流程跑通 ==');
}
