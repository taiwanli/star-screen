/// StarRule → SourceDef 归一（导入管线用，docs/17）。
library;

import 'dart:convert';

import '../config/parse_report.dart';
import '../models/models.dart';
import 'star_rule.dart';
import 'star_rule_parser.dart';

class StarRuleImporter {
  const StarRuleImporter._();

  /// 把一条 StarRule 转成注册表可用的 [SourceDef]。
  static SourceDef toSourceDef(StarRule rule, {String? groupId}) {
    final isCms = rule.sourceType == StarSourceType.cms;
    final hasSearch = rule.search != null || isCms;
    final hasCategory = rule.category != null || isCms;
    final caps = SourceCaps(
      searchable: hasSearch && (rule.caps?.searchable ?? true),
      quickSearch: hasSearch && (rule.caps?.quickSearch ?? true),
      filterable: rule.caps?.filterable ??
          (rule.home?.filters.isNotEmpty ?? false) ||
          isCms,
      changeable: true,
    );
    return SourceDef(
      key: rule.meta.id,
      name: rule.meta.name,
      kind: SourceKind.starRule,
      endpoint: rule.site.host,
      // 保留 raw 原文（含未知字段），StarRuleSource.fromDef 可直接解析
      extRaw: rule.raw.isEmpty ? jsonEncode(_toMap(rule)) : jsonEncode(rule.raw),
      sourceUrl: rule.site.homeUrl,
      caps: caps,
      headers: rule.site.effectiveHeaders(),
      timeoutSec: rule.site.timeoutSec,
      enabled: rule.enabled && (hasCategory || hasSearch),
      groupId: groupId,
    );
  }

  static Map<String, dynamic> _toMap(StarRule rule) {
    return {
      'starrule': rule.version,
      'meta': {
        'id': rule.meta.id,
        'name': rule.meta.name,
        'version': rule.meta.version,
        if (rule.meta.author != null) 'author': rule.meta.author,
        if (rule.meta.logo != null) 'logo': rule.meta.logo,
        if (rule.meta.description != null) 'description': rule.meta.description,
      },
      'site': {
        'host': rule.site.host,
        if (rule.site.headers.isNotEmpty) 'headers': rule.site.headers,
        'timeout': rule.site.timeoutSec,
      },
      'sourceType': rule.sourceType.name,
      if (rule.category != null) 'category': {'url': rule.category!.url},
    };
  }

  /// 批量：规则包 → SourceDef 列表 + issues。
  static ({List<SourceDef> defs, List<ParseIssue> issues}) importPack(
    String raw, {
    Uri? baseUrl,
    String? groupId,
  }) {
    final pack = StarRuleParser.parsePack(raw, baseUrl: baseUrl);
    final defs = <SourceDef>[];
    for (final rule in pack.rules) {
      defs.add(toSourceDef(rule, groupId: groupId ?? pack.packName));
    }
    return (defs: defs, issues: pack.issues);
  }

  /// 单站点导入。
  static ({SourceDef def, List<ParseIssue> issues}) importOne(
    String raw, {
    Uri? baseUrl,
    String? groupId,
  }) {
    final r = StarRuleParser.parse(raw, baseUrl: baseUrl);
    return (
      def: toSourceDef(r.rule, groupId: groupId),
      issues: r.issues,
    );
  }

  /// 包装成 [ParseReport]，便于与 TVBox 导入共用 [SourceRegistry.applyReport]。
  static ParseReport toParseReport(
    String raw, {
    Uri? baseUrl,
    String? groupId,
  }) {
    final pack = StarRuleParser.parsePack(raw, baseUrl: baseUrl);
    final defs = [
      for (final rule in pack.rules)
        toSourceDef(rule, groupId: groupId ?? pack.packName),
    ];
    return ParseReport(
      warehouses: const [],
      sources: defs,
      lives: const [],
      issues: pack.issues,
    );
  }
}
