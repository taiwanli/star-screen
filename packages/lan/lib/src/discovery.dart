import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// UDP 广播发现（docs/02 §4.9 mDNS 轻量替代：星映自研信标，无第三方依赖）。
///
/// - 服务端周期广播 `STARS` 信标（JSON）；
/// - 客户端监听同端口解析信标，按 deviceId 去重。
class LanDiscovery {
  LanDiscovery({
    this.port = 47890,
    this.httpPort = 47891,
    this.broadcastInterval = const Duration(seconds: 3),
  });

  final int port;
  final int httpPort;
  final Duration broadcastInterval;

  final Map<String, LanPeer> _peers = {};
  StreamController<List<LanPeer>> _controller =
      StreamController<List<LanPeer>>.broadcast();
  RawDatagramSocket? _socket;
  Timer? _beacon;
  StreamSubscription<RawSocketEvent>? _sockSub;
  String _name = '星映设备';
  String _deviceId = '';

  Stream<List<LanPeer>> get peers => _controller.stream;

  List<LanPeer> get current => _peers.values.toList();

  /// 启动：监听 + 周期广播本机信标（信标里的 port = HTTP 服务端口）。
  Future<void> start({required String name, required String deviceId}) async {
    _name = name;
    _deviceId = deviceId;
    // 支持 stop 后再 start：重建 stream、清理旧 socket
    if (_controller.isClosed) {
      _controller = StreamController<List<LanPeer>>.broadcast();
    }
    await _stopSocket();
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
    );
    _socket!.broadcastEnabled = true;
    _sockSub = _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = _socket?.receive();
      if (dg == null) return;
      _onDatagram(dg);
    });
    _beacon = Timer.periodic(broadcastInterval, (_) => _broadcast());
    _broadcast();
  }

  Future<void> _stopSocket() async {
    _beacon?.cancel();
    _beacon = null;
    await _sockSub?.cancel();
    _sockSub = null;
    _socket?.close();
    _socket = null;
  }

  void _broadcast() {
    final socket = _socket;
    if (socket == null) return;
    final payload = utf8.encode(jsonEncode({
      'app': 'StarScreen',
      'name': _name,
      'deviceId': _deviceId,
      // 广告 HTTP 服务端口，供对端 /ping /play /backup（不是 UDP 发现端口）
      'port': httpPort,
    }));
    try {
      socket.send(payload, InternetAddress('255.255.255.255'), port);
      socket.send(payload, InternetAddress.loopbackIPv4, port);
    } on Object {
      // 部分网络禁广播：忽略
    }
  }

  void _onDatagram(Datagram dg) {
    try {
      final m = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
      if (m['app'] != 'StarScreen') return;
      final deviceId = m['deviceId']?.toString() ?? '';
      if (deviceId.isEmpty || deviceId == _deviceId) return;
      final peer = LanPeer(
        name: m['name']?.toString() ?? '星映设备',
        deviceId: deviceId,
        ip: dg.address.address,
        port: (m['port'] as num?)?.toInt() ?? httpPort,
      );
      _peers[deviceId] = peer;
      if (!_controller.isClosed) _controller.add(current);
    } on Object {
      // 非星映包忽略
    }
  }

  Future<void> dispose() async {
    await _stopSocket();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
