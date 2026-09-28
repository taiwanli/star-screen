/// 星映局域网互联（docs/02 §4.4/§4.9）：
/// - UDP 广播发现同网段星映设备；
/// - HTTP 推送播放（手机 → TV/桌面）；
/// - HTTP 备份同步（收藏/历史/配置 JSON 互传，无云）。
library;

export 'src/cast_dlna.dart';
export 'src/discovery.dart';
export 'src/lan_bridge.dart';
export 'src/lan_client.dart';
export 'src/lan_server.dart';
export 'src/models.dart';
