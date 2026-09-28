import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// UPnP AVTransport（DLNA 投屏发送端骨架，docs/02 §4.3 P1）。
///
/// 仅覆盖「发现 MediaRenderer → SetAVTransportURI → Play」主路径；
/// 不实现完整 DLNA 协议栈（Seek/Stop/GetTransportInfo 可后续加）。
class DlnaDevice {
  final String name;
  final String location;
  final String? avTransportUrl;
  final String? controlUrl;

  const DlnaDevice({
    required this.name,
    required this.location,
    this.avTransportUrl,
    this.controlUrl,
  });
}

class DlnaCastClient {
  static const _ssdpPort = 1900;
  static const _searchTarget =
      'urn:schemas-upnp-org:device:MediaRenderer:1';

  /// SSDP 发现局域网 MediaRenderer（[timeout] 内收齐应答）。
  Future<List<DlnaDevice>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final devices = <String, DlnaDevice>{};
    final completer = Completer<void>();
    late StreamSubscription<RawSocketEvent> sub;

    sub = socket.listen((event) async {
      if (event != RawSocketEvent.read) return;
      final dg = socket.receive();
      if (dg == null) return;
      final text = utf8.decode(dg.data, allowMalformed: true);
      final location = RegExp(r'LOCATION:\s*(.+)', caseSensitive: false)
          .firstMatch(text)
          ?.group(1)
          ?.trim();
      if (location == null || location.isEmpty) return;
      if (devices.containsKey(location)) return;
      try {
        final dev = await _describe(location);
        if (dev != null) devices[location] = dev;
      } on Object {
        // 描述文件拉失败：忽略该设备
      }
    });

    final msg = utf8.encode('M-SEARCH * HTTP/1.1\r\n'
        'HOST: 239.255.255.250:$_ssdpPort\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: 2\r\n'
        'ST: $_searchTarget\r\n'
        '\r\n');
    socket.send(msg, InternetAddress('239.255.255.250'), _ssdpPort);

    await Future<void>.delayed(timeout);
    await sub.cancel();
    socket.close();
    if (!completer.isCompleted) completer.complete();
    return devices.values.toList();
  }

  Future<DlnaDevice?> _describe(String location) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.getUrl(Uri.parse(location)).timeout(
            const Duration(seconds: 3),
          );
      final res = await req.close();
      final xml = await res.transform(utf8.decoder).join();
      final name = RegExp(r'<friendlyName>([^<]+)</friendlyName>')
              .firstMatch(xml)
              ?.group(1) ??
          location;
      // 服务列表里找 AVTransport 控制 URL（相对路径补全）
      final avMatch = RegExp(
        r'<serviceType>\s*urn:schemas-upnp-org:service:AVTransport:1\s*</serviceType>[\s\S]*?<controlURL>\s*([^<]+)\s*</controlURL>',
      ).firstMatch(xml);
      String? control;
      if (avMatch != null) {
        final raw = avMatch.group(1)!.trim();
        try {
          control = Uri.parse(location).resolve(raw).toString();
        } on Object {
          control = raw;
        }
      }
      return DlnaDevice(
        name: name.trim(),
        location: location,
        avTransportUrl: control,
        controlUrl: control,
      );
    } finally {
      client.close(force: true);
    }
  }

  /// 停止播放。
  Future<bool> stop(DlnaDevice device) async {
    final endpoint = device.controlUrl;
    if (endpoint == null || endpoint.isEmpty) return false;
    final body = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
    </u:Stop>
  </s:Body>
</s:Envelope>''';
    return _soap(
      endpoint,
      'urn:schemas-upnp-org:service:AVTransport:1#Stop',
      body,
    );
  }

  /// 暂停 / 继续。
  Future<bool> pause(DlnaDevice device) =>
      _avAction(device, 'Pause', '<InstanceID>0</InstanceID>');
  /// 继续播放（不重新 SetURI）。
  Future<bool> resume(DlnaDevice device) =>
      _avAction(device, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');

  /// seek（秒）。
  Future<bool> seek(DlnaDevice device, int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final target =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return _avAction(
      device,
      'Seek',
      '<InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>$target</Target>',
    );
  }

  Future<bool> _avAction(DlnaDevice device, String action, String inner) async {
    final endpoint = device.controlUrl;
    if (endpoint == null || endpoint.isEmpty) return false;
    final body = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:$action xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      $inner
    </u:$action>
  </s:Body>
</s:Envelope>''';
    return _soap(
      endpoint,
      'urn:schemas-upnp-org:service:AVTransport:1#$action',
      body,
    );
  }

  /// 把 [mediaUrl] 推到 [device] 并开播。
  Future<bool> play(DlnaDevice device, String mediaUrl, {String? title}) async {
    final endpoint = device.controlUrl;
    if (endpoint == null || endpoint.isEmpty) return false;
    final escaped = _xmlEscape(mediaUrl);
    final meta = _xmlEscape(_didlLite(title ?? '星映推片', mediaUrl));
    final body = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
      <CurrentURI>$escaped</CurrentURI>
      <CurrentURIMetaData>$meta</CurrentURIMetaData>
    </u:SetAVTransportURI>
  </s:Body>
</s:Envelope>''';
    final okUri = await _soap(
      endpoint,
      'urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI',
      body,
    );
    if (!okUri) return false;
    final playBody = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
      <Speed>1</Speed>
    </u:Play>
  </s:Body>
</s:Envelope>''';
    return _soap(
      endpoint,
      'urn:schemas-upnp-org:service:AVTransport:1#Play',
      playBody,
    );
  }

  Future<bool> _soap(String endpoint, String action, String body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.postUrl(Uri.parse(endpoint));
      req.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
      req.headers.set('SOAPAction', '"$action"');
      req.write(body);
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain<void>();
      return res.statusCode >= 200 && res.statusCode < 300;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  static String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _didlLite(String title, String url) =>
      '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">'
      '<item id="1" parentID="0" restricted="1">'
      '<dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">${_xmlEscape(title)}</dc:title>'
      '<upnp:class xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">object.item.videoItem</upnp:class>'
      '<res>${_xmlEscape(url)}</res>'
      '</item></DIDL-Lite>';
}

/// 版本检查（docs/02 §4.6 检查更新）。
class UpdateChecker {
  UpdateChecker({required this.getText});

  final Future<String> Function(String url) getText;

  /// [manifestUrl] 返回 JSON：`{"version":"1.0.0","url":"...","notes":"..."}`。
  Future<UpdateInfo?> check(String manifestUrl, String currentVersion) async {
    try {
      final body = await getText(manifestUrl);
      final m = jsonDecode(body) as Map<String, dynamic>;
      final version = m['version']?.toString();
      if (version == null || version.isEmpty) return null;
      if (_isNewer(version, currentVersion)) {
        return UpdateInfo(
          version: version,
          url: m['url']?.toString(),
          notes: m['notes']?.toString(),
        );
      }
      return null;
    } on Object {
      return null;
    }
  }

  /// 简单点号版本比较（1.0.0-dev.2 < 1.0.0）。
  static bool _isNewer(String remote, String local) {
    List<int> parse(String v) => v
        .split(RegExp(r'[.+-]'))
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final r = parse(remote);
    final l = parse(local);
    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv > lv) return true;
      if (rv < lv) return false;
    }
    return false;
  }
}

class UpdateInfo {
  final String version;
  final String? url;
  final String? notes;

  const UpdateInfo({required this.version, this.url, this.notes});
}
