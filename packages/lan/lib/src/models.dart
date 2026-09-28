/// 局域网设备与推送消息。
class LanPeer {
  final String name;
  final String deviceId;
  final String ip;
  final int port;

  const LanPeer({
    required this.name,
    required this.deviceId,
    required this.ip,
    required this.port,
  });

  String get baseUrl => 'http://$ip:$port';

  Map<String, dynamic> toJson() => {
        'name': name,
        'deviceId': deviceId,
        'ip': ip,
        'port': port,
      };

  factory LanPeer.fromJson(Map<String, dynamic> m) => LanPeer(
        name: m['name']?.toString() ?? '未知设备',
        deviceId: m['deviceId']?.toString() ?? '',
        ip: m['ip']?.toString() ?? '',
        port: (m['port'] as num?)?.toInt() ?? 0,
      );
}

/// 推送播放载荷。
class PlayPush {
  final String url;
  final String title;
  final Map<String, String> headers;

  const PlayPush({
    required this.url,
    required this.title,
    this.headers = const {},
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'headers': headers,
      };

  factory PlayPush.fromJson(Map<String, dynamic> m) => PlayPush(
        url: m['url']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        headers: m['headers'] is Map
            ? Map<String, String>.from((m['headers'] as Map)
                .map((k, v) => MapEntry(k.toString(), v.toString())))
            : const {},
      );
}
