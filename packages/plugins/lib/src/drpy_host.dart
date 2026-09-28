import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:star_domain/star_domain.dart';

import 'drpy_js_runtime.dart';
import 'drpy_rule_parser.dart';
import 'pdfh_engine.dart';

/// drpy 注入 API 宿主（docs/04 §4.3 注入 API 表的原生实现，docs/09 M3-4）。
///
/// 把 Dart 能力（HTTP / PdfhEngine / 日志）安装进 [JsRuntime]：
/// - `req/request(url,{headers,method,body})` / `post(url,…)` → `{content, headers, status}`
///   （dr_py 契约：req 返回响应对象，`fetch(url,params)` 直接返回正文文本）；
/// - `pdfa(html,parse)` → 元素 outerHTML 数组；`pdfh(html,parse)` → 取值；`pd` → 取值并补全 URL；
/// - `setResult/setResult2(d)` → 捕获为片段结果；`print/log` → 捕获为日志；
/// - `buildUrl(url,params)` → 合并查询串；`getProxyUrl()` → 空串（星映不做本地代理）。
///
/// js: 片段以 async IIFE 包裹执行：片段内 `await req(...)`、`setResult(...)`
/// 均可用。全局变量（input/HOST/MY_* 等）由 [runSnippet] 的 globals 注入，
/// `rule`/`oheaders` 在 [defineGlobals] 一次性定义。
///
/// 全部宿主函数受 [budget] 约束 —— 超限即抛 FetchException 熔断，绝不崩溃。
class DrpyHost {
  final JsRuntime runtime;
  final HttpFetch http;

  /// 请求头基准（SourceDef.headers + rule.headers 合并结果；install 时可写入 rule.headers）。
  Map<String, String> baseHeaders;

  /// rule.host（pd 补全 URL 的最终兜底基准）。
  final String? ruleHost;

  final DrpyBudget budget;

  final List<Object?> _captured = [];
  final List<String> logs = [];
  bool _installed = false;

  /// pd 的默认补全基准（= 当前正在解析的页面 URL，由源适配器按操作更新）。
  String? currentUrl;

  DrpyHost({
    required this.runtime,
    required this.http,
    Map<String, String> baseHeaders = const {},
    this.ruleHost,
    DrpyBudget? budget,
  })  : baseHeaders = {...baseHeaders},
        budget = budget ?? DrpyBudget();

  /// 安装注入 API 与 rule 全局（幂等；每次换源文件须新建 [DrpyHost]）。
  Future<void> install(DrpyRule rule) async {
    if (_installed) return;
    _installed = true;

    void host(String name, Future<Object?> Function(List<Object?> args) fn) {
      runtime.installFunction(name, fn);
    }

    host('req', (a) => _request(a, 'GET'));
    host('request', (a) => _request(a, 'GET'));
    host('post', (a) => _request(a, 'POST'));
    host('fetch', (a) async => (await _request(a, 'GET'))['content']);
    host('pdfa', _pdfa);
    host('pdfh', _pdfh);
    host('pd', _pd);
    host('setResult', (a) async {
      _capture(a);
      return null;
    });
    host('setResult2', (a) async {
      _capture(a);
      return null;
    });
    host('log', _log);
    host('print', _log);
    host('buildUrl', _buildUrl);
    host('getProxyUrl', (a) async => '');

    defineGlobals(rule);
  }

  /// 定义 rule 对象与常驻全局（HOST/oheaders）。
  void defineGlobals(DrpyRule rule) {
    final ruleHeaders = rule.mapField('headers');
    if (ruleHeaders != null) {
      for (final e in ruleHeaders.entries) {
        if (e.value != null) baseHeaders[e.key] = e.value.toString();
      }
    }
    final fieldsJson = jsonEncode(rule.fields);
    final headersJson = jsonEncode(baseHeaders);
    runtime.evalSync(
      'var rule = $fieldsJson;\n'
      'var HOST = (rule && rule.host) ? rule.host : "";\n'
      'var oheaders = $headersJson;\n',
    );
  }

  void _capture(List<Object?> args) {
    final v = args.isEmpty ? null : args.first;
    if (v is String) budget.chargeOutput(v.length);
    _captured.add(v);
  }

  Future<Object?> _log(List<Object?> args) async {
    if (logs.length < 200) {
      logs.add(args.map((e) => e?.toString() ?? 'null').join(' '));
    }
    return null;
  }

  // ---------------- HTTP ----------------

  Future<Map<String, Object?>> _request(List<Object?> args, String fallbackMethod) async {
    budget.chargeRequest();
    final url = args.isEmpty ? null : _asStr(args[0]);
    if (url == null || url.isEmpty) {
      throw const FetchException('drpy req：缺少请求地址');
    }
    final opts = args.length > 1 ? _asMap(args[1]) : null;
    final headers = {...baseHeaders};
    var method = fallbackMethod;
    var body = '';
    if (opts != null) {
      final h = _asMap(opts['headers']);
      if (h != null) {
        for (final e in h.entries) {
          if (e.value != null) headers[e.key] = e.value.toString();
        }
      }
      final m = _asStr(opts['method']);
      if (m != null && m.isNotEmpty) method = m.toUpperCase();
      final data = opts['body'] ?? opts['data'];
      if (data != null) {
        if (data is String) {
          body = data;
        } else if (data is Map) {
          body = data.entries
              .map((e) =>
                  '${Uri.encodeComponent(e.key.toString())}=${Uri.encodeComponent(e.value.toString())}')
              .join('&');
        }
      }
    }
    final timeout = budget.remaining;
    final res = switch (method) {
      'POST' => await http.post(
          Uri.parse(url),
          body: body,
          headers: headers,
          timeout: timeout,
        ),
      _ => await http.get(Uri.parse(url), headers: headers, timeout: timeout),
    };
    return {
      'content': res.body,
      'headers': res.headers,
      'status': res.statusCode,
    };
  }

  // ---------------- pdfh/pdfa/pd ----------------

  Future<List<String>> _pdfa(List<Object?> args) async {
    final html = args.isEmpty ? '' : (_asStr(args[0]) ?? '');
    final rule = args.length > 1 ? (_asStr(args[1]) ?? '') : '';
    if (html.isEmpty || rule.isEmpty) return const [];
    // docs/13 D1：一次解析后在内存 DOM 上求值
    final root = html_parser.parse(html).documentElement;
    return PdfhEngine.pdfaIn(root, rule).map((e) => e.outerHtml).toList();
  }

  Future<String?> _pdfh(List<Object?> args) async {
    final html = args.isEmpty ? '' : (_asStr(args[0]) ?? '');
    final rule = args.length > 1 ? (_asStr(args[1]) ?? '') : '';
    if (html.isEmpty) return null;
    if (rule.isEmpty) return html;
    final root = html_parser.parse(html).documentElement;
    return root == null ? null : PdfhEngine.pdfh(root, rule);
  }

  Future<String?> _pd(List<Object?> args) async {
    final value = await _pdfh(args);
    if (value == null || value.isEmpty) return null;
    final base = (args.length > 2 ? _asStr(args[2]) : null) ??
        currentUrl ??
        ruleHost;
    return completeUrl(value, base);
  }

  Future<Object?> _buildUrl(List<Object?> args) async {
    final url = args.isEmpty ? '' : (_asStr(args[0]) ?? '');
    if (url.isEmpty) return url;
    final params = args.length > 1 ? _asMap(args[1]) : null;
    if (params == null || params.isEmpty) return url;
    final uri = Uri.parse(url);
    final merged = <String, String>{
      ...uri.queryParameters,
      for (final e in params.entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    return uri.replace(queryParameters: merged).toString();
  }

  // ---------------- 片段执行 ----------------

  /// 执行一段 js: 片段（已剥去 `js:` 前缀）。[globals] 注入为全局变量
  /// （input/MY_CATE/MY_FL/MY_PAGE/TYPE/fetch_params…）；结果取
  /// setResult 载荷，片段直接 return 时取 IIFE 返回值。
  Future<Object?> runSnippet(
    String code, {
    Map<String, Object?> globals = const {},
    Duration? timeout,
  }) async {
    _captured.clear();
    final buf = StringBuffer();
    globals.forEach((k, v) {
      buf.writeln('globalThis[${jsonEncode(k)}] = ${jsonEncode(v)};');
    });
    final wrapped = '(async () => {\n$buf$code\n})();';
    final returned = await runtime.evalAsync(
      wrapped,
      timeout: timeout ?? budget.remaining,
    );
    return _captured.isNotEmpty ? _captured.last : returned;
  }

  // ---------------- 结果归一 ----------------

  /// 片段结果 → 列表（容错：list 包裹 / JSON 字符串 / 单对象 / data.list）。
  List<Map<String, dynamic>> resultAsList(Object? result) {
    if (result == null) return const [];
    Object? cur = result;
    if (cur is String) {
      final s = cur.trim();
      if (s.isEmpty) return const [];
      try {
        cur = jsonDecode(s);
      } on FormatException {
        return const [];
      }
    }
    if (cur is Map<String, dynamic>) {
      final list = cur['list'];
      if (list is List) return _mapsOf(list);
      final data = cur['data'];
      if (data is List) return _mapsOf(data);
      if (data is Map<String, dynamic> && data['list'] is List) {
        return _mapsOf(data['list'] as List);
      }
      return [cur];
    }
    if (cur is List) return _mapsOf(cur);
    return const [];
  }

  static List<Map<String, dynamic>> _mapsOf(List<Object?> raw) => [
        for (final item in raw)
          if (item is Map<String, dynamic>) item,
      ];

  /// 片段结果 → 单对象（detail/lazy：JSON 字符串 / 对象容错）。
  Map<String, dynamic>? resultAsMap(Object? result) {
    if (result == null) return null;
    Object? cur = result;
    if (cur is String) {
      final s = cur.trim();
      if (s.isEmpty) return null;
      try {
        cur = jsonDecode(s);
      } on FormatException {
        return null;
      }
    }
    final list = cur is List && cur.isNotEmpty ? cur.first : cur;
    return list is Map<String, dynamic> ? list : null;
  }

  // ---------------- 工具 ----------------

  /// 补全相对地址（协议相对 //、相对路径、宿主缺省）。
  static String? completeUrl(String value, String? base) {
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (base == null || base.isEmpty) return v;
    try {
      return Uri.parse(base).resolve(v).toString();
    } on FormatException {
      return v;
    }
  }

  static String? _asStr(Object? v) => v is String ? v : (v == null ? null : v.toString());

  static Map<String, dynamic>? _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;
}

/// 惰性解析并缓存首页/详情 HTML 的根元素（pdfh 注入函数与 Dart 侧共用）。
Element? parseRoot(String html) => html_parser.parse(html).documentElement;
