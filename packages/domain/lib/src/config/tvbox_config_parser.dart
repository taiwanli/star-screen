import '../models/models.dart';
import 'config_cleaner.dart';
import 'exceptions.dart';
import 'parse_report.dart';

/// TVBox 系订阅配置解析器（docs/05 §5 管线：清洗 → JSON → storeHouse 展开 →
/// 站点归一 → 相对路径解析 → 注册模型）。
///
/// 规范依据：docs/04 §3（字段级规范，源码级验证）。
/// 本解析器只做"结构归一 + 分类"，不做网络请求；ext 为 URL 时仅记录地址，
/// 由 feed_fetcher 在注册后按需拉取。
class TvBoxConfigParser {
  const TvBoxConfigParser._();

  /// XPath 系规则源 —— 可被原生规则引擎转译（docs/05 §6.3）。
  static const _xpathApis = <String>{
    'csp_xpath',
    'csp_xpathmac',
    'csp_xpathfilter',
    'csp_xpathmacfilter',
  };

  /// 解析订阅原文。[baseUrl] 为订阅地址，用于解析 `./`、`../` 相对路径
  ///（规范：相对路径以配置 URL 自身为基准，docs/04 §3.1）。
  static ParseReport parse({required String raw, Uri? baseUrl}) {
    final doc = ConfigCleaner.decode(raw, source: baseUrl);
    if (doc is! Map<String, dynamic>) {
      throw const _NotAMap();
    }
    return _parseMap(doc, baseUrl);
  }

  static ParseReport _parseMap(Map<String, dynamic> doc, Uri? baseUrl) {
    // 多仓（storeHouse）：逐条展开，子仓由调用方递归解析。
    final warehouses = <WarehouseEntry>[];
    final storeHouse = doc['storeHouse'];
    if (storeHouse is List) {
      for (final item in storeHouse) {
        if (item is! Map<String, dynamic>) continue;
        final url = item['sourceUrl'];
        if (url is! String || url.isEmpty) continue;
        warehouses.add(WarehouseEntry(
          name: (item['sourceName'] as String?) ?? url,
          url: resolveRef(baseUrl, url) ?? url,
        ));
      }
    }
    // 多仓变体 `{"urls":[{"name","url"}...]}`（实测 c00·wh0515 / gao·0707）
    final urlsRaw = doc['urls'];
    if (urlsRaw is List) {
      for (final item in urlsRaw) {
        if (item is! Map<String, dynamic>) continue;
        final url = item['url'];
        if (url is! String || url.isEmpty) continue;
        warehouses.add(WarehouseEntry(
          name: (item['name'] as String?) ?? url,
          url: resolveRef(baseUrl, url) ?? url,
        ));
      }
    }

    final sites = doc['sites'];
    final livesRaw = doc['lives'];
    final spiderRef = doc['spider'] is String ? doc['spider'] as String : null;
    final spiderResolved = resolveRef(baseUrl, spiderRef);

    final sources = <SourceDef>[];
    final issues = <ParseIssue>[];

    if (sites is List) {
      for (final site in sites) {
        if (site is! Map<String, dynamic>) {
          issues.add(const ParseIssue('站点条目不是对象，已跳过'));
          continue;
        }
        try {
          _parseSite(site, baseUrl, spiderResolved, sources, issues);
        } on Object catch (e) {
          // 单站解析失败不拖垮整份配置
          final key = site['key']?.toString();
          issues.add(ParseIssue('站点解析异常已跳过：$e', siteKey: key));
        }
      }
    }

    final lives = <LiveGroup>[];
    if (livesRaw is List) {
      for (final item in livesRaw) {
        if (item is! Map<String, dynamic>) continue;
        final url = item['url'];
        if (url is! String || url.isEmpty) continue;
        lives.add(LiveGroup(
          name: (item['name'] as String?) ?? '直播',
          url: resolveRef(baseUrl, url) ?? url,
          epg: item['epg'] is String ? item['epg'] as String : null,
          logo: item['logo'] is String ? item['logo'] as String : null,
        ));
      }
    }

    // CMS 响应形状的顶层（class+list）—— 该地址应作为 CMS 源接入而非订阅
    if (warehouses.isEmpty &&
        sources.isEmpty &&
        doc['list'] is List &&
        doc['class'] is List) {
      issues.add(const ParseIssue(
          '顶层是 CMS 响应结构（list/class）—— 该地址应作为「CMS 接口源」添加，而不是 TVBox 订阅'));
    }

    return ParseReport(
      warehouses: warehouses,
      sources: sources,
      lives: lives,
      issues: issues,
      spiderRef: spiderResolved,
      adFilters: [
        if (doc['ads'] is List)
          for (final x in doc['ads'] as List) x.toString(),
      ],
      playFlags: [
        if (doc['flags'] is List)
          for (final x in doc['flags'] as List) x.toString(),
      ],
      homeSiteKey: doc['home']?.toString(),
    );
  }

  static void _parseSite(
    Map<String, dynamic> site,
    Uri? baseUrl,
    String? spiderResolved,
    List<SourceDef> sink,
    List<ParseIssue> issues,
  ) {
    final key = site['key']?.toString() ?? '';
    final name = site['name']?.toString() ?? key;
    if (key.isEmpty) {
      issues.add(const ParseIssue('站点缺少 key，已跳过'));
      return;
    }

    final type = _readInt(site['type']) ?? 0;
    final api = site['api']?.toString() ?? '';
    final ext = site['ext']?.toString();
    final jarRaw = site['jar']?.toString();
    final jarRef = jarRaw == null || jarRaw.isEmpty
        ? spiderResolved
        : resolveRef(baseUrl, jarRaw);

    var caps = SourceCaps(
      searchable: (_readInt(site['searchable']) ?? 1) != 0,
      quickSearch: (_readInt(site['quickSearch']) ?? 1) != 0,
      filterable: (_readInt(site['filterable']) ?? 1) != 0,
      changeable: (_readInt(site['changeable']) ?? 1) != 0,
    );

    final headers = <String, String>{};
    final rawHeaders = site['header'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
    }

    String? unsupported;
    var kind = SourceKind.unsupported;
    var variant = CmsVariant.none;
    String? endpoint;
    String? extUrl;
    String? sourceUrl;

    // ext 形态判定：内联 JSON（{ 或 [ 开头）保留原文；否则视为 URL/路径并解析。
    final extIsInlineJson =
        ext != null && (ext.startsWith('{') || ext.startsWith('['));
    if (ext != null && ext.isNotEmpty && !extIsInlineJson) {
      extUrl = resolveRef(baseUrl, ext);
    }

    switch (type) {
      case 0:
        kind = SourceKind.cmsXml;
        endpoint = resolveRef(baseUrl, _cmsBase(api));
      case 1:
        kind = SourceKind.cmsJson;
        endpoint = resolveRef(baseUrl, _cmsBase(api));
      case 3:
        final lowered = api.toLowerCase();
        if (lowered.startsWith('csp_')) {
          final classApi = lowered;
          if (_xpathApis.contains(classApi)) {
            kind = SourceKind.xpathRule;
            if (ext == null || ext.isEmpty) {
              kind = SourceKind.unsupported;
              unsupported = 'XPath 规则源缺少 ext 规则文件';
              caps = const SourceCaps.disabled();
            }
          } else if (classApi == 'csp_appysv2') {
            // ext 形如 `API地址###附加信息`（docs/04 §4.2）。
            kind = SourceKind.cmsJson;
            variant = CmsVariant.appysV2;
            final apiPart = ext?.split('###').first ?? '';
            endpoint = apiPart.isEmpty ? _cmsBase(api) : _cmsBase(apiPart);
          } else if (classApi == 'csp_alist') {
            kind = SourceKind.alist;
          } else if (_looksLikeCmsEndpoint(ext) || _looksLikeCmsEndpoint(api)) {
            // 蜘蛛声明但 ext/api 像苹果 CMS 接口 —— 按 CMS JSON 直连（docs/05 §7）
            kind = SourceKind.cmsJson;
            final raw = _looksLikeCmsEndpoint(ext) ? ext! : api;
            endpoint = resolveRef(baseUrl, _cmsBase(raw));
          } else {
            // 其余 csp_* 走 jar 蜘蛛执行桥（Android DexClassLoader）
            kind = SourceKind.spiderJar;
            endpoint = api;
          }
        } else if (lowered.endsWith('.js')) {
          kind = SourceKind.drpyJs;
          endpoint = resolveRef(baseUrl, api);
          // ext 以 .js 结尾时视为源文件路径；否则是运行时参数（如实测 "18+"）。
          if (ext != null && ext.isNotEmpty && ext.toLowerCase().endsWith('.js')) {
            sourceUrl = resolveRef(baseUrl, ext);
          }
        } else if (lowered.endsWith('.py')) {
          unsupported = 'py 源暂不支持';
          caps = const SourceCaps.disabled();
        } else if (lowered.startsWith('http')) {
          unsupported = '服务器化源暂不支持';
          caps = const SourceCaps.disabled();
        } else {
          unsupported = '无法识别的蜘蛛声明';
          caps = const SourceCaps.disabled();
        }
      case 4:
        unsupported = 'hipy t4 服务器源暂不支持';
        caps = const SourceCaps.disabled();
      default:
        issues.add(ParseIssue('未知站点类型 type=$type，按不支持处理', siteKey: key));
        unsupported = '未知站点类型 type=$type';
        caps = const SourceCaps.disabled();
    }

    sink.add(SourceDef(
      key: key,
      name: name,
      kind: kind,
      cmsVariant: variant,
      endpoint: endpoint,
      extRaw: ext,
      extUrl: extUrl,
      sourceUrl: sourceUrl,
      jarRef: jarRef,
      caps: caps,
      headers: headers,
      timeoutSec: _readInt(site['timeout']),
      unsupportedReason: kind.isSupported ? null : unsupported,
    ));
  }

  /// CMS 基地址归一：剥离 `?ac=list` 之类的查询尾巴（docs/05 §6.1）。
  static String _cmsBase(String api) {
    final q = api.indexOf('?');
    return q < 0 ? api : api.substring(0, q);
  }

  /// ext/api 是否像苹果 CMS 接口（provide/vod / api.php）。
  static bool _looksLikeCmsEndpoint(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    final s = raw.toLowerCase();
    return (s.startsWith('http://') || s.startsWith('https://')) &&
        (s.contains('provide/vod') || s.contains('api.php'));
  }

  /// 相对路径解析（`./`、`../` 以订阅 URL 为基准；绝对地址原样返回）。
  /// 非 URL 形态（如 `分类url:http://…` 规则串）原样返回，绝不抛 FormatException。
  static String? resolveRef(Uri? baseUrl, String? ref) {
    if (ref == null || ref.isEmpty) return null;
    if (ref.startsWith('http://') || ref.startsWith('https://')) return ref;
    if (baseUrl == null) return ref;
    try {
      return baseUrl.resolve(ref).toString();
    } on FormatException {
      return ref;
    } on ArgumentError {
      return ref;
    }
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _NotAMap extends ConfigParseException {
  const _NotAMap() : super('订阅内容顶层不是 JSON 对象');
}
