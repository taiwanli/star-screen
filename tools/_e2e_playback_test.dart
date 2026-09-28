// 端到端播放链路验证（docs/06 暴風 CMS 源）
// 直接调用 CmsJsonSource，不经过 UI；验证 list → detail → m3u8 可达。
import 'dart:io';

import 'package:star_domain/star_domain.dart';

Future<void> main() async {
  print('=== 星映端到端播放链路测试（暴風 CMS）===\n');

  final def = SourceDef(
    key: 'bf_test',
    name: '暴風测试',
    kind: SourceKind.cmsJson,
    endpoint: 'https://bfzyapi.com/api.php/provide/vod',
    enabled: true,
  );

  final source = CmsJsonSource(def: def);

  // 1. home / list
  print('[1/3] 首页 list …');
  HomeFeed feed;
  try {
    feed = await source.home();
    final cards = feed.recommend;
    print('  ✓ 首页 ${cards.length} 张卡片');
    if (cards.isEmpty) {
      print('  ⚠ 首页无卡片，终止');
      exit(1);
      return;
    }
    print('  首张：${cards.first.title}');
  } catch (e, st) {
    print('  ✗ 首页失败：$e\n$st');
    exit(1);
    return;
  }

  // 2. detail
  print('\n[2/3] 详情 …');
  WorkDetail detail;
  try {
    final card = feed.recommend.first;
    detail = await source.detail(card.workId);
    print('  ✓ 详情：${detail.card.title}（${detail.card.year ?? '?'}）');
    print('  线路数：${detail.lines.length}');
    for (final line in detail.lines.take(3)) {
      print('  - ${line.name}：${line.episodes.length} 集');
      if (line.episodes.isNotEmpty) {
        final ep = line.episodes.first;
        print('    第1集：${ep.name}');
        final short = ep.url.length > 80 ? '${ep.url.substring(0, 80)}…' : ep.url;
        print('    地址：$short');
      }
    }
  } catch (e, st) {
    print('  ✗ 详情失败：$e\n$st');
    exit(1);
    return;
  }

  // 3. m3u8 可达性（GET 取前 512B）
  print('\n[3/3] 播放地址可达性 …');
  try {
    final lines = detail.lines;
    if (lines.isEmpty || lines.first.episodes.isEmpty) {
      print('  ⚠ 无线路或无选集，终止');
      exit(1);
      return;
    }
    final ep = lines.first.episodes.first;
    if (ep.url.isEmpty) {
      print('  ⚠ 第1集无地址，终止');
      exit(1);
      return;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    final req = await client.getUrl(Uri.parse(ep.url));
    final res = await req.close().timeout(const Duration(seconds: 15));
    final chunk = await res.take(512).join();
    print('  HTTP ${res.statusCode} ${res.headers.contentType?.mimeType ?? '?'}');
    client.close(force: true);

    if (res.statusCode == 200 && chunk.isNotEmpty) {
      print('\n✅ 全链路通过：list → detail → m3u8 可达（取到 ${chunk.length} 字节）');
      exit(0);
    } else {
      print('  ⚠ 状态码 ${res.statusCode}，m3u8 直连验证失败');
      exit(1);
    }
  } catch (e, st) {
    print('  ✗ m3u8 验证失败：$e\n$st');
    exit(1);
  }
}
