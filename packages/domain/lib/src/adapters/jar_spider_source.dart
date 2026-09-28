import 'dart:convert';

import '../contracts/video_source.dart';
import '../models/models.dart';
import '../playback/play_url_filter.dart';

/// jar 蜘蛛执行桥（Android DexClassLoader / 本地 Java 进程）。
///
/// 端上注入实现；不可用时 [available] 为 false。
/// 安全：仅加载用户导入的 jar；不自动下载未知包（docs/05 §7 修订）。
abstract class JarSpiderHost {
  bool get available;

  /// 加载 jar（本地路径）；[className] 蜘蛛短名（如 `Douban`）。
  Future<void> load({
    required String jarPath,
    required String className,
    String? md5,
  });

  /// 调用 Spider 方法，返回 JSON 文本。
  Future<String> call(String method, Map<String, Object?> args);

  Future<void> dispose();
}

/// TVBox csp jar 蜘蛛适配器（docs/04 §4.3）。
class JarSpiderSource implements VideoSource {
  JarSpiderSource({required this.def, required this.host});

  @override
  final SourceDef def;
  final JarSpiderHost host;

  String get className {
    final api = def.endpoint ?? def.sourceUrl ?? def.key;
    final raw = api.startsWith('csp_') ? api.substring(4) : api;
    return raw.split('.').last;
  }

  Future<void> ensureLoaded() async {
    final jar = def.jarRef;
    if (jar == null || jar.isEmpty) {
      throw StateError('源未声明 jar 路径');
    }
    await host.load(jarPath: jar, className: className);
  }

  Future<Map<String, dynamic>> _invoke(
      String method, Map<String, Object?> args) async {
    await ensureLoaded();
    final raw = await host.call(method, args);
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  @override
  Future<HomeFeed> home() async {
    final vod = await _invoke('homeVod', {});
    final filter = vod.isEmpty ? await _invoke('home', {'filter': false}) : vod;
    return HomeFeed(recommend: _cards(_listOf(filter)));
  }

  @override
  Future<PageResult<WorkCard>> category(CategoryQuery query) async {
    final doc = await _invoke('category', {
      'tid': query.typeId ?? '',
      'pg': query.page,
      'filter': true,
      'extend': query.filters,
    });
    return PageResult(items: _cards(_listOf(doc)), page: query.page);
  }

  @override
  Future<PageResult<WorkCard>> search(String keyword, {int page = 1}) async {
    final doc = await _invoke('search', {
      'key': keyword,
      'quick': false,
      'pg': page,
    });
    return PageResult(items: _cards(_listOf(doc)), page: page);
  }

  @override
  Future<WorkDetail> detail(String workId) async {
    final doc = await _invoke('detail', {
      'ids': [workId],
    });
    final list = _listOf(doc);
    if (list.isEmpty) throw StateError('未找到影片（$workId）');
    final v = list.first;
    final card = _cards([v]).first;
    return WorkDetail(
      card: card,
      actor: _str(v['vod_actor']),
      director: _str(v['vod_director']),
      content: _str(v['vod_content']),
      lines: _lines(v),
    );
  }

  @override
  Future<PlayCandidate> resolve(PlayRequest request) async {
    final d = await detail(request.workId);
    final lines = d.lines
        .where((l) => PlayUrlFilter.lineAllowed(l.lineId) || PlayUrlFilter.lineAllowed(l.name))
        .toList();
    final line = request.lineId == null
        ? lines.firstOrNull
        : lines.where((l) => l.lineId == request.lineId).firstOrNull;
    if (line == null || line.episodes.isEmpty) {
      throw StateError('无可用播放线路');
    }
    final idx = request.episodeIndex.clamp(0, line.episodes.length - 1);
    final ep = line.episodes[idx];
    final doc = await _invoke('player', {
      'flag': line.lineId,
      'id': ep.url,
      'vipFlags': <String>[],
    });
    final url = _str(doc['url']) ?? ep.url;
    final parseFlag = doc['parse'];
    final needsParse = parseFlag == 1 ||
        parseFlag == true ||
        !(url.contains('.m3u8') ||
            url.contains('.mp4') ||
            url.contains('.flv') ||
            url.contains('.ts'));
    final header = <String, String>{};
    final h = doc['header'];
    if (h is Map) {
      for (final e in h.entries) {
        header[e.key.toString()] = e.value.toString();
      }
    }
    return PlayCandidate(url: url, headers: header, needsParse: needsParse);
  }

  static List<Map<String, dynamic>> _listOf(Map<String, dynamic> doc) {
    final list = doc['list'] ?? doc['data'];
    if (list is List) {
      return [
        for (final x in list)
          if (x is Map<String, dynamic>) x,
      ];
    }
    return const [];
  }

  List<WorkCard> _cards(List<Map<String, dynamic>> raw) => [
        for (final v in raw)
          WorkCard(
            sourceKey: def.key,
            workId: _str(v['vod_id']) ?? _str(v['id']) ?? '',
            title: _str(v['vod_name']) ?? _str(v['name']) ?? '',
            posterUrl: _str(v['vod_pic']) ?? _str(v['pic']),
            remarks: _str(v['vod_remarks']) ?? _str(v['note']),
            year: _str(v['vod_year']),
            area: _str(v['vod_area']),
            genre: _str(v['vod_class']),
          ),
      ];

  List<PlayLine> _lines(Map<String, dynamic> v) {
    final from = _str(v['vod_play_from']) ?? '';
    final urls = _str(v['vod_play_url']) ?? '';
    if (from.isEmpty || urls.isEmpty) return const [];
    final fromParts = from.split(r'$$$');
    final urlParts = urls.split(r'$$$');
    final lines = <PlayLine>[];
    final n =
        fromParts.length < urlParts.length ? fromParts.length : urlParts.length;
    for (var i = 0; i < n; i++) {
      final name = fromParts[i].trim();
      final eps = <Episode>[];
      final parts = urlParts[i].split('#');
      for (var j = 0; j < parts.length; j++) {
        final part = parts[j].trim();
        final dollar = part.indexOf(r'$');
        final epName = dollar < 0 ? part : part.substring(0, dollar).trim();
        final epUrl = dollar < 0 ? '' : part.substring(dollar + 1).trim();
        if (epUrl.isEmpty) continue;
        eps.add(Episode(
          index: j,
          name: epName.isEmpty ? '第${j + 1}集' : epName,
          url: epUrl,
        ));
      }
      if (eps.isEmpty) continue;
      lines.add(PlayLine(lineId: name, name: name, episodes: eps));
    }
    return lines;
  }

  static String? _str(Object? v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }
}
