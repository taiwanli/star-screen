import 'package:star_domain/star_domain.dart';

export 'src/drpy_host.dart';
export 'src/drpy_js_runtime.dart';
export 'src/drpy_rule_parser.dart';
export 'src/drpy_template_source.dart';
export 'src/pdfh_engine.dart';
export 'src/starrule/star_rule_source.dart';

/// JS 沙箱限额（docs/05 §6.2）—— 违反任一项即熔断置灰，不提示崩溃。
class SandboxLimits {
  /// 单次调用 CPU 片段预算。
  static const int cpuSliceMs = 200;

  /// 单源堆内存上限。
  static const int maxHeapMb = 32;

  /// 单源并发 = 1（JS 源串行，保护低端盒子）。
  static const int maxConcurrencyPerSource = 1;

  /// ext 拉取体积上限。
  static const int maxExtBytes = 256 * 1024;

  /// 默认调用总超时（站点 timeout 缺省时）。
  static const int defaultTimeoutSec = 15;

  const SandboxLimits._();
}

/// drpy JS 源的函数契约（docs/04 §4.3，宿主方法 ↔ JS 函数映射）。
///
/// M3 里程碑以 QuickJS 实现 [JsSourceRuntime]；实现方注入的 API 面以
/// docs/04 §4.3 注入 API 表为准（request/pdfa/pdfh/pd/setResult/MY_*）。
abstract interface class JsSourceRuntime {
  /// 装载运行时（如 drpy2.min.js）与源文件，初始化 Spider 契约。
  Future<void> load({required String runtimeUrl, required String sourceUrl});

  /// `init(extend)`。
  Future<void> init(String? extend);

  /// `home(filter)` → homeContent JSON。
  Future<SpiderJson> home(bool filter);

  /// `homeVod()`。
  Future<SpiderJson> homeVod();

  /// `category(tid, pg, filter, extend)`。
  Future<SpiderJson> category(String tid, String pg, bool filter, String extend);

  /// `detail(id)`。
  Future<SpiderJson> detail(String id);

  /// `play(flag, id, vipFlags)`。
  Future<SpiderJson> play(String flag, String id, String vipFlags);

  /// `search(key, quick, pg)`。
  Future<SpiderJson> search(String key, bool quick, String pg);

  Future<void> dispose();
}

/// Spider 契约的 JSON 返回（与 csp jar 同构，复用同一归一器）。
typedef SpiderJson = Map<String, dynamic>;

/// TVBox 配置导入器接口（M0 由 domain 的 TvBoxConfigParser 提供默认实现；
/// 本接口留给「远程订阅 + 增量刷新」场景扩展）。
abstract interface class TvBoxImporter {
  Future<ParseReport> import({required String raw, Uri? baseUrl});
}
