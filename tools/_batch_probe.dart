// 批量探测 docs/06 源清单中的可用源
// 直接调用 domain 包，不经过 UI。
import 'dart:io';

import 'package:star_domain/star_domain.dart';

Future<void> main() async {
  print('=== 星映源清单批量探测 ===\n');

  // 按 docs/06 清单：可用 CMS JSON 源
  final cmsSources = [
    ('暴風', 'https://bfzyapi.com/api.php/provide/vod'),
    ('索尼', 'https://suoniapi.com/api.php/provide/vod'),
    ('快帆', 'https://api.kuaifan.tv/api.php/provide/vod'),
    ('乐视网', 'https://leshiapi.com/api.php/provide/vod'),
  ];

  for (final (name, endpoint) in cmsSources) {
    print('[$name] $endpoint');
    final def = SourceDef(
      key: 'test_${Uri.encodeComponent(name)}',
      name: name,
      kind: SourceKind.cmsJson,
      endpoint: endpoint,
      enabled: true,
    );
    final source = CmsJsonSource(def: def);
    try {
      final feed = await source.home().timeout(const Duration(seconds: 15));
      final cards = feed.recommend;
      print('  ✓ 首页 ${cards.length} 张卡片');
      if (cards.isNotEmpty) {
        final detail =
            await source.detail(cards.first.workId).timeout(const Duration(seconds: 15));
        final lines = detail.lines;
        print('  ✓ 详情：${detail.card.title}，线路 ${lines.length} 条');
        if (lines.isNotEmpty && lines.first.episodes.isNotEmpty) {
          final ep = lines.first.episodes.first;
          if (ep.url.isNotEmpty) {
            final client = HttpClient()
              ..connectionTimeout = const Duration(seconds: 8);
            final req = await client.getUrl(Uri.parse(ep.url));
            final res = await req.close().timeout(const Duration(seconds: 12));
            await res.drain();
            client.close(force: true);
            final ok = res.statusCode == 200;
            print('  ${ok ? '✓' : '✗'} m3u8: HTTP ${res.statusCode} '
                '${res.headers.contentType?.mimeType}');
          } else {
            print('  ⚠ 第1集无地址（needsParse 或空 url）');
          }
        } else {
          print('  ⚠ 无线路或无选集');
        }
      }
    } catch (e) {
      print('  ✗ 失败：$e');
    }
    print('');
  }

  // 直播源（m3u 格式）
  print('[直播] https://live.fanmingming.com/tv/m3u/ipv6.m3u');
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final req = await client.getUrl(Uri.parse('https://live.fanmingming.com/tv/m3u/ipv6.m3u'));
    final res = await req.close().timeout(const Duration(seconds: 15));
    final body = await res.transform(SystemEncoding().decoder).join();
    final lines = body.split('\n').where((l) => l.startsWith('#EXTINF')).toList();
    final sample = lines.isNotEmpty ? lines.first.split(',').last : '(无)';
    print('  HTTP ${res.statusCode}，共 ${lines.length} 条频道，示例：$sample');
    client.close(force: true);
  } catch (e) {
    print('  ✗ 失败：$e');
  }
}
