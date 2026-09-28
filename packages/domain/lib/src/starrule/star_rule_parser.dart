import 'dart:convert';

import '../config/parse_report.dart';
import 'star_rule.dart';

/// StarRule 解析 + 校验（docs/17 §10）。
///
/// 致命问题抛 [StarRuleParseException]；警告进 [StarRuleParseResult.issues]，
/// 绝不静默吞错。
class StarRuleParser {
  const StarRuleParser._();

  /// 识别是否为 StarRule 文档（含规则包）。
  static bool looksLikeStarRule(String raw) {
    final trimmed = raw.trimLeft().replaceFirst('﻿', '');
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return false;
    return trimmed.contains('"starrule"');
  }

  /// 解析单站点规则；规则包请用 [parsePack]。
  static StarRuleParseResult parse(String raw, {Uri? baseUrl}) {
    final doc = _decode(raw);
    if (doc is List) {
      throw const StarRuleParseException('顶层是数组，请用规则包解析（sites[]）');
    }
    if (doc is! Map<String, dynamic>) {
      throw const StarRuleParseException('StarRule 顶层必须是 JSON 对象');
    }
    return _parseSite(doc, baseUrl);
  }

  /// 解析规则包：返回站点列表 + 包级 issue。
  static StarRulePackResult parsePack(String raw, {Uri? baseUrl}) {
    final doc = _decode(raw);
    if (doc is Map<String, dynamic> &&
        doc['sites'] is List &&
        doc['pack'] is Map) {
      final packName = (doc['pack'] as Map)['name']?.toString() ?? '规则包';
      final issues = <ParseIssue>[];
      final rules = <StarRule>[];
      for (final item in doc['sites'] as List) {
        if (item is! Map<String, dynamic>) {
          issues.add(const ParseIssue('规则包条目不是对象，已跳过'));
          continue;
        }
        try {
          final r = _parseSite(item, baseUrl);
          issues.addAll(r.issues);
          rules.add(r.rule);
        } on StarRuleParseException catch (e) {
          issues.add(ParseIssue('规则包条目被拒：${e.message}'));
        }
      }
      return StarRulePackResult(packName: packName, rules: rules, issues: issues);
    }
    // 单站点也允许包成数组
    if (doc is List) {
      final issues = <ParseIssue>[];
      final rules = <StarRule>[];
      for (final item in doc) {
        if (item is! Map<String, dynamic>) continue;
        try {
          final r = _parseSite(item, baseUrl);
          issues.addAll(r.issues);
          rules.add(r.rule);
        } on StarRuleParseException catch (e) {
          issues.add(ParseIssue('规则包条目被拒：${e.message}'));
        }
      }
      return StarRulePackResult(packName: '规则包', rules: rules, issues: issues);
    }
    // 单站点
    final single = parse(raw, baseUrl: baseUrl);
    return StarRulePackResult(
      packName: single.rule.meta.name,
      rules: [single.rule],
      issues: single.issues,
    );
  }

  static Object _decode(String raw) {
    final cleaned = raw.trimLeft().replaceFirst('﻿', '');
    try {
      return jsonDecode(cleaned) as Object;
    } on FormatException catch (e) {
      throw StarRuleParseException('JSON 解析失败：${e.message}');
    }
  }

  static StarRuleParseResult _parseSite(
    Map<String, dynamic> doc,
    Uri? baseUrl,
  ) {
    final issues = <ParseIssue>[];
    final version = _asInt(doc['starrule']) ?? -1;
    if (version != 1) {
      throw StarRuleParseException(
          '不支持的 starrule 版本：${doc['starrule'] ?? '缺失'}（当前仅支持 1）');
    }

    final metaRaw = doc['meta'];
    if (metaRaw is! Map) {
      throw const StarRuleParseException('缺少 meta 对象');
    }
    final id = metaRaw['id']?.toString().trim() ?? '';
    if (!_idPattern.hasMatch(id)) {
      throw StarRuleParseException('meta.id 非法：「$id」（需 [a-z0-9][a-z0-9._-]{1,63}）');
    }
    final name = metaRaw['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const StarRuleParseException('meta.name 不能为空');
    }
    final meta = StarMeta(
      id: id,
      name: name,
      version: metaRaw['version']?.toString() ?? '1.0.0',
      author: metaRaw['author']?.toString(),
      logo: metaRaw['logo']?.toString(),
      description: metaRaw['description']?.toString(),
      homepage: metaRaw['homepage']?.toString(),
    );

    final siteRaw = doc['site'];
    if (siteRaw is! Map) {
      throw const StarRuleParseException('缺少 site 对象');
    }
    final hostRaw = siteRaw['host']?.toString().trim() ?? '';
    final host = _resolve(baseUrl, hostRaw);
    if (host == null ||
        !(host.startsWith('http://') || host.startsWith('https://'))) {
      throw StarRuleParseException('site.host 必须是 http(s) 地址：「$hostRaw」');
    }
    final headers = <String, String>{};
    final h = siteRaw['headers'];
    if (h is Map) {
      h.forEach((k, v) => headers[k.toString()] = v.toString());
    }
    final site = StarSite(
      host: host.endsWith('/') ? host.substring(0, host.length - 1) : host,
      headers: headers,
      timeoutSec: _asInt(siteRaw['timeout']) ?? 15,
      encoding: siteRaw['encoding']?.toString() ?? 'utf-8',
      homeUrl: siteRaw['homeUrl']?.toString() ?? '/',
      cookie: siteRaw['cookie']?.toString(),
    );

    final sourceType = switch (doc['sourceType']?.toString()) {
      'json' => StarSourceType.json,
      'xml' => StarSourceType.xml,
      'cms' => StarSourceType.cms,
      _ => StarSourceType.html,
    };

    StarHome? home;
    final homeRaw = doc['home'];
    if (homeRaw is Map) {
      home = StarHome(
        url: homeRaw['url']?.toString() ?? '/',
        recommend: StarItemMap.parse(homeRaw['recommend'] is Map
            ? homeRaw['recommend'] as Map
            : null),
        categories: _parseCategories(homeRaw['categories']),
        filters: _parseFilters(homeRaw['filters']),
      );
    }

    StarBlock? category;
    final catRaw = doc['category'];
    if (catRaw is Map) {
      final items = StarItemMap.parse(catRaw);
      if (items != null) {
        category = StarBlock(
          url: catRaw['url']?.toString() ?? '',
          items: items,
        );
      } else {
        issues.add(const ParseIssue('category 块缺 list/title/id，已忽略'));
      }
    }

    StarBlock? search;
    final searchRaw = doc['search'];
    if (searchRaw is Map) {
      final items = StarItemMap.parse(searchRaw);
      if (items != null) {
        search = StarBlock(
          url: searchRaw['url']?.toString() ?? '',
          items: items,
          searchable: searchRaw['searchable'] != false,
          quickSearch: searchRaw['quickSearch'] != false,
        );
      } else {
        issues.add(const ParseIssue('search 块缺 list/title/id，已忽略'));
      }
    }

    if (category == null && search == null && sourceType != StarSourceType.cms) {
      throw const StarRuleParseException('category 与 search 不能同时缺失（无入口）');
    }

    StarDetail? detail;
    final detailRaw = doc['detail'];
    if (detailRaw is Map) {
      detail = _parseDetail(detailRaw);
    } else if (sourceType != StarSourceType.cms) {
      throw const StarRuleParseException('缺少 detail 块');
    }

    StarPlay? play;
    final playRaw = doc['play'];
    if (playRaw is Map) {
      play = StarPlay(
        url: playRaw['url']?.toString() ?? '{playUrl}',
        headers: {
          if (playRaw['headers'] is Map)
            for (final e in (playRaw['headers'] as Map).entries)
              e.key.toString(): e.value.toString(),
        },
        parseMode: playRaw['parse']?.toString() ?? 'auto',
        filterAds: [
          if (playRaw['filterAds'] is List)
            for (final x in playRaw['filterAds'] as List) x.toString(),
        ],
      );
    }

    StarCapsOverride? caps;
    final capsRaw = doc['caps'];
    if (capsRaw is Map) {
      caps = StarCapsOverride(
        searchable: capsRaw['searchable'] is bool
            ? capsRaw['searchable'] as bool
            : null,
        quickSearch: capsRaw['quickSearch'] is bool
            ? capsRaw['quickSearch'] as bool
            : null,
        filterable: capsRaw['filterable'] is bool
            ? capsRaw['filterable'] as bool
            : null,
      );
    }

    if (search == null && sourceType != StarSourceType.cms) {
      issues.add(const ParseIssue('未声明 search，搜索将置灰'));
    }
    if (doc['script'] != null) {
      issues.add(const ParseIssue('包含 script 块：需 QuickJS（三端均已接入）'));
    }

    final rule = StarRule(
      version: version,
      meta: meta,
      site: site,
      sourceType: sourceType,
      home: home,
      category: category,
      detail: detail,
      search: search,
      play: play,
      caps: caps,
      tags: [
        if (doc['tags'] is List)
          for (final t in doc['tags'] as List) t.toString(),
      ],
      enabled: doc['enabled'] != false,
      convertedFrom: doc['convertedFrom']?.toString(),
      raw: doc,
    );
    return StarRuleParseResult(rule: rule, issues: issues);
  }

  static final _idPattern = RegExp(r'^[a-z0-9][a-z0-9._-]{1,63}$');

  static StarCategories? _parseCategories(Object? raw) {
    if (raw is! Map<Object?, Object?>) return null;
    final mode = raw['mode']?.toString() ?? 'manual';
    final manual = <String, String>{};
    final m = raw['manual'];
    if (m is Map) {
      m.forEach((k, v) => manual[k.toString()] = v.toString());
    }
    StarCategoryParse? parse;
    final p = raw['parse'];
    if (p is Map) {
      final list = StarField.parse(p['list']);
      if (list != null) {
        parse = StarCategoryParse(
          list: list,
          name: StarField.parse(p['name'] ?? 'Text'),
          id: StarField.parse(p['id'] ?? 'href'),
        );
      }
    }
    return StarCategories(mode: mode, manual: manual, parse: parse);
  }

  static Map<String, List<StarFilterGroup>> _parseFilters(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, List<StarFilterGroup>>{};
    raw.forEach((key, value) {
      if (value is! List) return;
      final groups = <StarFilterGroup>[];
      for (final g in value) {
        if (g is! Map) continue;
        final options = <StarFilterOption>[];
        final opts = g['options'];
        if (opts is List) {
          for (final o in opts) {
            if (o is Map) {
              options.add(StarFilterOption(
                label: o['label']?.toString() ?? '',
                value: o['value']?.toString() ?? '',
              ));
            }
          }
        }
        groups.add(StarFilterGroup(
          key: g['key']?.toString() ?? '',
          name: g['name']?.toString() ?? '',
          options: options,
        ));
      }
      out[key.toString()] = groups;
    });
    return out;
  }

  static StarDetail _parseDetail(Map<Object?, Object?> raw) {
    StarLines? lines;
    final linesRaw = raw['lines'];
    if (linesRaw is Map) {
      final epRaw = linesRaw['episodes'];
      StarEpisodes? episodes;
      if (epRaw is Map) {
        final list = StarField.parse(epRaw['list']);
        final name = StarField.parse(epRaw['name']);
        final url = StarField.parse(epRaw['url']);
        if (list != null && name != null && url != null) {
          episodes = StarEpisodes(list: list, name: name, url: url);
        }
      }
      lines = StarLines(
        list: StarField.parse(linesRaw['list']),
        name: StarField.parse(linesRaw['name']),
        episodes: episodes,
        flat: linesRaw['flat'] == true,
        fromField: StarField.parse(linesRaw['fromField']),
        urlField: StarField.parse(linesRaw['urlField']),
      );
    }
    return StarDetail(
      url: raw['url']?.toString(),
      title: StarField.parse(raw['title']),
      cover: StarField.parse(raw['cover']),
      desc: StarField.parse(raw['desc'] ?? raw['content']),
      year: StarField.parse(raw['year']),
      area: StarField.parse(raw['area']),
      type: StarField.parse(raw['type']),
      actor: StarField.parse(raw['actor']),
      director: StarField.parse(raw['director']),
      remarks: StarField.parse(raw['remarks']),
      lines: lines,
    );
  }

  static String? _resolve(Uri? base, String ref) {
    if (ref.isEmpty) return null;
    if (ref.startsWith('http://') || ref.startsWith('https://')) return ref;
    if (base == null) return ref;
    try {
      return base.resolve(ref).toString();
    } on Object {
      return ref;
    }
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

class StarRuleParseException implements Exception {
  final String message;
  const StarRuleParseException(this.message);
  @override
  String toString() => 'StarRuleParseException: $message';
}

class StarRuleParseResult {
  final StarRule rule;
  final List<ParseIssue> issues;
  const StarRuleParseResult({required this.rule, this.issues = const []});
}

class StarRulePackResult {
  final String packName;
  final List<StarRule> rules;
  final List<ParseIssue> issues;
  const StarRulePackResult({
    required this.packName,
    required this.rules,
    this.issues = const [],
  });
}
