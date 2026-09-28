/// StarRule v1 领域模型（docs/17-源写规范）。
///
/// 纯声明式 JSON 规则：三端共用同一解释器，不依赖 jar / 外部脚本即可覆盖
/// 绝大多数站点。选择器语法与 plugins 的 PdfhEngine 同构（`&&` 下钻 + 取值后缀）。
library;

/// 规则文档（单站点）。
class StarRule {
  final int version;
  final StarMeta meta;
  final StarSite site;
  final StarSourceType sourceType;
  final StarHome? home;
  final StarBlock? category;
  final StarDetail? detail;
  final StarBlock? search;
  final StarPlay? play;
  final StarCapsOverride? caps;
  final List<String> tags;
  final bool enabled;
  final String? convertedFrom;
  final Map<String, dynamic> raw;

  const StarRule({
    this.version = 1,
    required this.meta,
    required this.site,
    this.sourceType = StarSourceType.html,
    this.home,
    this.category,
    this.detail,
    this.search,
    this.play,
    this.caps,
    this.tags = const [],
    this.enabled = true,
    this.convertedFrom,
    this.raw = const {},
  });

  /// 是否仅靠声明字段即可运行（无 script）。
  bool get isDeclarative => true;
}

/// 识别的响应/文档形态。
enum StarSourceType {
  /// 静态页 / 模板站，CSS 链选择器。
  html,

  /// JSON API，`json:` 前缀选择器。
  json,

  /// XML / RSS，`xml:` 前缀选择器。
  xml,

  /// 苹果 CMS JSON 快捷模式（协议内建，规则块可省略）。
  cms,
}

class StarMeta {
  final String id;
  final String name;
  final String version;
  final String? author;
  final String? logo;
  final String? description;
  final String? homepage;

  const StarMeta({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.author,
    this.logo,
    this.description,
    this.homepage,
  });
}

class StarSite {
  final String host;
  final Map<String, String> headers;
  final int timeoutSec;
  final String encoding;
  final String homeUrl;
  final String? cookie;

  const StarSite({
    required this.host,
    this.headers = const {},
    this.timeoutSec = 15,
    this.encoding = 'utf-8',
    this.homeUrl = '/',
    this.cookie,
  });

  /// 合并 Cookie：site.cookie 与 headers.Cookie，headers 优先。
  Map<String, String> effectiveHeaders() {
    final out = {...headers};
    if (cookie != null && cookie!.isNotEmpty && !out.containsKey('Cookie')) {
      out['Cookie'] = cookie!;
    }
    return out;
  }
}

/// 字段规则：字符串形态 ≡ `{"sel": "..."}`。
class StarField {
  final String sel;
  final String? regex;
  final String? replace;
  final String? fallback;
  final bool trim;
  final bool? absUrl;

  const StarField({
    required this.sel,
    this.regex,
    this.replace,
    this.fallback,
    this.trim = true,
    this.absUrl,
  });

  /// 解析字符串或对象形态；非法返回 null。
  static StarField? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      return StarField(sel: s);
    }
    if (raw is Map<Object?, Object?>) {
      final sel = raw['sel']?.toString().trim() ?? '';
      if (sel.isEmpty) return null;
      return StarField(
        sel: sel,
        regex: raw['regex']?.toString(),
        replace: raw['replace']?.toString(),
        fallback: raw['default']?.toString(),
        trim: raw['trim'] is bool ? raw['trim'] as bool : true,
        absUrl: raw['absUrl'] is bool ? raw['absUrl'] as bool : null,
      );
    }
    return null;
  }
}

/// 首页。
class StarHome {
  final String url;
  final StarItemMap? recommend;
  final StarCategories? categories;
  final Map<String, List<StarFilterGroup>> filters;

  const StarHome({
    this.url = '/',
    this.recommend,
    this.categories,
    this.filters = const {},
  });
}

/// 分类入口。
class StarCategories {
  /// `manual` | `parse` | `json` | `cms`
  final String mode;
  final Map<String, String> manual;
  final StarCategoryParse? parse;

  const StarCategories({
    this.mode = 'manual',
    this.manual = const {},
    this.parse,
  });
}

class StarCategoryParse {
  final StarField list;
  final StarField? name;
  final StarField? id;

  const StarCategoryParse({
    required this.list,
    this.name,
    this.id,
  });
}

class StarFilterGroup {
  final String key;
  final String name;
  final List<StarFilterOption> options;

  const StarFilterGroup({
    required this.key,
    required this.name,
    required this.options,
  });
}

class StarFilterOption {
  final String label;
  final String value;

  const StarFilterOption({required this.label, required this.value});
}

/// 条目字段映射（recommend / category / search 共用）。
class StarItemMap {
  final StarField list;
  final StarField title;
  final StarField id;
  final StarField? cover;
  final StarField? badge;
  final StarField? year;
  final StarField? area;
  final StarField? type;
  final StarField? score;
  final bool idIsUrl;
  final StarField? pageCount;
  final String hasMore; // auto | pageCount | none

  const StarItemMap({
    required this.list,
    required this.title,
    required this.id,
    this.cover,
    this.badge,
    this.year,
    this.area,
    this.type,
    this.score,
    this.idIsUrl = false,
    this.pageCount,
    this.hasMore = 'auto',
  });

  static StarItemMap? parse(Map<Object?, Object?>? raw) {
    if (raw == null) return null;
    final list = StarField.parse(raw['list']);
    final title = StarField.parse(raw['title']);
    final id = StarField.parse(raw['id']);
    if (list == null || title == null || id == null) return null;
    return StarItemMap(
      list: list,
      title: title,
      id: id,
      cover: StarField.parse(raw['cover']),
      badge: StarField.parse(raw['badge']),
      year: StarField.parse(raw['year']),
      area: StarField.parse(raw['area']),
      type: StarField.parse(raw['type']),
      score: StarField.parse(raw['score']),
      idIsUrl: raw['idIsUrl'] == true,
      pageCount: StarField.parse(raw['pageCount']),
      hasMore: raw['hasMore']?.toString() ?? 'auto',
    );
  }
}

/// 分类 / 搜索块（条目映射 + URL 模板）。
class StarBlock {
  final String url;
  final StarItemMap items;
  final bool searchable;
  final bool quickSearch;

  const StarBlock({
    required this.url,
    required this.items,
    this.searchable = true,
    this.quickSearch = true,
  });
}

/// 详情块。
class StarDetail {
  final String? url;
  final StarField? title;
  final StarField? cover;
  final StarField? desc;
  final StarField? year;
  final StarField? area;
  final StarField? type;
  final StarField? actor;
  final StarField? director;
  final StarField? remarks;
  final StarLines? lines;

  const StarDetail({
    this.url,
    this.title,
    this.cover,
    this.desc,
    this.year,
    this.area,
    this.type,
    this.actor,
    this.director,
    this.remarks,
    this.lines,
  });
}

/// 线路 + 选集。
class StarLines {
  final StarField? list;
  final StarField? name;
  final StarEpisodes? episodes;

  /// true：无线路，全部集数进默认线路。
  final bool flat;

  /// CMS 形态：`vod_play_from` / `vod_play_url` 直取。
  final StarField? fromField;
  final StarField? urlField;

  const StarLines({
    this.list,
    this.name,
    this.episodes,
    this.flat = false,
    this.fromField,
    this.urlField,
  });
}

class StarEpisodes {
  final StarField list;
  final StarField name;
  final StarField url;

  const StarEpisodes({
    required this.list,
    required this.name,
    required this.url,
  });
}

/// 播放块。
class StarPlay {
  final String url;
  final Map<String, String> headers;

  /// auto | 0 | 1
  final String parseMode;
  final List<String> filterAds;

  const StarPlay({
    this.url = '{playUrl}',
    this.headers = const {},
    this.parseMode = 'auto',
    this.filterAds = const [],
  });
}

/// 能力覆盖。
class StarCapsOverride {
  final bool? searchable;
  final bool? quickSearch;
  final bool? filterable;

  const StarCapsOverride({this.searchable, this.quickSearch, this.filterable});
}
