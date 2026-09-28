/// 星映领域层（StarScreen Domain）。
///
/// 架构红线（docs/03 §2）：本包禁止依赖任何 Flutter/UI 库，仅允许纯 Dart；
/// 上游（catalog/search/detail/playback）只依赖本包导出的契约，不感知源的真实形态。
library;

export 'src/adapters/cms_json_source.dart';
export 'src/adapters/cms_xml_source.dart';
export 'src/adapters/jar_spider_source.dart';
export 'src/adapters/line_names.dart';
export 'src/config/config_cleaner.dart';
export 'src/config/exceptions.dart';
export 'src/config/parse_report.dart';
export 'src/config/tvbox_config_parser.dart';
export 'src/contracts/video_source.dart';
export 'src/detail/detail_service.dart';
export 'src/epg/epg_client.dart';
export 'src/epg/epg_loader.dart';
export 'src/health/health_monitor.dart';
export 'src/live/live_parser.dart';
export 'src/models/models.dart';
export 'src/net/feed_fetcher.dart';
export 'src/net/http_fetch.dart';
export 'src/net/local_feed_policy.dart';
export 'src/playback/play_url_filter.dart';
export 'src/playback/playback_session.dart';
export 'src/playback/player_engine_pref.dart';
export 'src/player_events.dart';
export 'src/registry/source_registry.dart';
export 'src/search/search_engine.dart';
export 'src/source_check/source_checker.dart';
export 'src/starrule/converters/drpy_to_star_rule.dart';
export 'src/starrule/converters/xpath_to_star_rule.dart';
export 'src/starrule/star_rule.dart';
export 'src/starrule/star_rule_deep_link.dart';
export 'src/starrule/star_rule_importer.dart';
export 'src/starrule/star_rule_parser.dart';
export 'src/util/semaphore.dart';
export 'src/util/ttl_cache.dart';
