// StarRule 写源校验 CLI（docs/17 §12）。
//
// 用法：
//   dart run tools/starrule_lint <file.star.json> [more.json ...]
//   dart run tools/starrule_lint --dir docs/samples
//
// 退出码：0=通过（可有警告）；1=有致命错误；2=参数错误。
import 'dart:convert';
import 'dart:io';

import 'package:star_domain/star_domain.dart';

void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln('用法: dart run tools/starrule_lint <file.json> ...');
    stdout.writeln('      dart run tools/starrule_lint --dir <目录>');
    exit(args.isEmpty ? 2 : 0);
  }

  final files = <File>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--dir') {
      final dir = Directory(i + 1 < args.length ? args[i + 1] : '.');
      if (!dir.existsSync()) {
        stderr.writeln('目录不存在: ${dir.path}');
        exit(2);
      }
      files.addAll(dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json')));
      i++;
      continue;
    }
    final f = File(args[i]);
    if (!f.existsSync()) {
      stderr.writeln('文件不存在: ${f.path}');
      exit(2);
    }
    files.add(f);
  }

  var fatal = 0;
  var warn = 0;
  for (final f in files) {
    final ok = _lintFile(f);
    if (!ok) fatal++;
  }
  stdout.writeln('');
  stdout.writeln('共 ${files.length} 个文件 · 致命 $fatal · 警告 $_gWarn');
  exit(fatal > 0 ? 1 : 0);
}

int _gWarn = 0;

bool _lintFile(File f) {
  final name = f.path.split(Platform.pathSeparator).last;
  stdout.writeln('── $name');
  final raw = f.readAsStringSync();
  // 规则包（顶层 pack + sites）优先走 parsePack。
  // 注意：looksLikeStarRule 只要正文含 "starrule" 即返回 true，会把规则包误判成单站点。
  final looksLikePack = raw.contains('"sites"') && raw.contains('"pack"');
  if (looksLikePack || !StarRuleParser.looksLikeStarRule(raw)) {
    // 允许规则包
    try {
      final pack = StarRuleParser.parsePack(raw);
      if (pack.rules.isEmpty) {
        stdout.writeln('  ✗ 未识别为 StarRule，且规则包为空');
        return false;
      }
      var ok = true;
      for (var i = 0; i < pack.rules.length; i++) {
        ok = _lintRule(pack.rules[i], i == 0 ? pack.issues : const []) && ok;
      }
      return ok;
    } on Object catch (e) {
      stdout.writeln('  ✗ $e');
      return false;
    }
  }

  try {
    final r = StarRuleParser.parse(raw);
    return _lintRule(r.rule, r.issues);
  } on StarRuleParseException catch (e) {
    stdout.writeln('  ✗ 致命: ${e.message}');
    return false;
  } on Object catch (e) {
    stdout.writeln('  ✗ $e');
    return false;
  }
}

bool _lintRule(StarRule rule, List<ParseIssue> issues) {
  var ok = true;

  void fatal(String msg) {
    stdout.writeln('  ✗ 致命: $msg');
    ok = false;
  }

  void warn(String msg) {
    _gWarn++;
    stdout.writeln('  ⚠ 警告: $msg');
  }

  void info(String msg) => stdout.writeln('  · $msg');

  info('id=${rule.meta.id}  name=${rule.meta.name}  type=${rule.sourceType.name}');
  info('host=${rule.site.host}');

  if (rule.category == null && rule.search == null && rule.sourceType != StarSourceType.cms) {
    fatal('category 与 search 不能同时缺失');
  }
  if (rule.detail == null && rule.sourceType != StarSourceType.cms) {
    fatal('缺少 detail');
  }
  if (rule.search == null) {
    if (rule.sourceType != StarSourceType.cms) {
      warn('未声明 search，搜索将置灰');
    }
  }
  if (rule.category != null && !rule.category!.url.contains('{catePg}')) {
    if (rule.category!.items.hasMore == 'auto') {
      warn('category.url 缺 {catePg}，hasMore=auto 时可能只有一页');
    }
  }
  if (rule.detail?.url == null &&
      rule.detail?.lines?.episodes != null &&
      rule.sourceType == StarSourceType.html) {
    warn('detail.url 为空：workId 必须是可直接请求的路径/URL');
  }

  // 条目字段完整性
  void checkItems(String label, StarItemMap? m) {
    if (m == null) return;
    if (m.title.sel.isEmpty) warn('$label.title 为空');
    if (m.id.sel.isEmpty) warn('$label.id 为空');
    if (m.cover == null) info('$label 无 cover');
  }

  checkItems('home.recommend', rule.home?.recommend);
  checkItems('category', rule.category?.items);
  checkItems('search', rule.search?.items);

  if (rule.raw['script'] != null) {
    warn('含 script 块：需 QuickJS（三端均已接入，但建议尽量纯声明）');
  }

  for (final i in issues) {
    warn(i.message);
  }

  if (ok) {
    final isCms = rule.sourceType == StarSourceType.cms;
    final caps = [
      if (isCms || rule.home?.recommend != null) 'home',
      if (isCms || rule.category != null) 'category',
      if (isCms || rule.search != null) 'search',
      if (isCms || rule.detail != null) 'detail',
      if (isCms) 'cms协议',
    ];
    info('能力: ${caps.join(' / ')}');
    stdout.writeln('  ✓ 通过');
  }
  return ok;
}
