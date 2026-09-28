import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:star_storage/star_storage.dart';

import 'discovery.dart';
import 'lan_client.dart';
import 'lan_server.dart';
import 'models.dart';

/// 局域网互联装配（发现 + 本机服务 + 客户端 + 下载）。
class LanBridge {
  LanBridge({
    required this.deviceName,
    required this.deviceId,
    required this.backup,
    required this.downloads,
    required this.onPlayPush,
    this.authToken,
    this.kv,
    this.kvKey = 'lanToken',
  });

  final String deviceName;
  final String deviceId;
  final DriftBackupCodec backup;
  final DownloadStore downloads;
  final Future<void> Function(PlayPush push) onPlayPush;

  /// 显式共享口令（非空则直接采用，跳过 KV 自动生成）。
  final String? authToken;

  /// docs/13 E1：出厂默认互信是漏洞（同网段任意设备可拉走 /backup 全量用户数据）。
  /// 未显式传入 authToken 且注入了 [kv] 时，首次运行自动生成随机口令并持久化；
  /// 之后每次启动复用同一口令，UI 需展示该口令供两台设备手动配对。
  final KeyValueStore? kv;
  final String kvKey;
  static const _tokenAlphabet =
      'ABCDEFGHJKMNPQRSTUVWXYZ23456789abcdefghjkmnpqrstuvwxyz';

  String? _activeToken;
  String? get activeToken => authToken ?? _activeToken;

  /// 生效口令（懒解析：已传入 [authToken] 原样返回；否则查 [kv]；
  /// 都没有则生成 16 位随机口令（去易混字符）并落 KV，配对 UI 展示用）。
  Future<String> resolveToken() async {
    if (authToken != null) return authToken!;
    if (_activeToken != null) return _activeToken!;
    final store = kv;
    if (store != null) {
      final stored = await store.getString(kvKey);
      if (stored != null && stored.isNotEmpty) {
        _activeToken = stored;
        return stored;
      }
    }
    final rng = Random.secure();
    final token = List.generate(
        16, (_) => _tokenAlphabet[rng.nextInt(_tokenAlphabet.length)]).join();
    _activeToken = token;
    await store?.setString(kvKey, token);
    return token;
  }

  final discovery = LanDiscovery();
  late LanClient client = LanClient();
  late final DownloadService downloadService = DownloadService(downloads);

  LanServer? _server;
  StreamSubscription<List<LanPeer>>? _peerSub;
  StreamController<List<LanPeer>> _peersController =
      StreamController<List<LanPeer>>.broadcast();

  Stream<List<LanPeer>> get peers => _peersController.stream;

  bool get hosting => _server != null;

  Future<void> startHosting() async {
    if (_server != null) return;
    if (_peersController.isClosed) {
      _peersController = StreamController<List<LanPeer>>.broadcast();
    }
    final token = await resolveToken();
    await discovery.start(name: deviceName, deviceId: deviceId);
    client = LanClient(authToken: token);
    final server = LanServer(
      deviceName: deviceName,
      authToken: token,
      onPlayPush: onPlayPush,
      onBackupPull: backup.exportAll,
      onBackupPush: (text) async {
        await backup.importAll(text);
        return true;
      },
    );
    try {
      await server.start();
    } on Object {
      await discovery.dispose();
      rethrow;
    }
    _server = server;
    await _peerSub?.cancel();
    _peerSub = discovery.peers.listen((p) {
      if (!_peersController.isClosed) _peersController.add(p);
    });
  }

  Future<void> stopHosting() async {
    await _peerSub?.cancel();
    _peerSub = null;
    await _server?.dispose();
    _server = null;
    await discovery.dispose();
  }

  Future<void> dispose() async {
    await stopHosting();
    if (!_peersController.isClosed) {
      await _peersController.close();
    }
  }

  /// 入队并立刻下载（队列由 [DownloadService.drainQueue] 兜底）。
  Future<void> enqueueDownload({
    required String title,
    required String url,
    required String dir,
  }) async {
    final item = await downloads.enqueue(title: title, url: url);
    unawaited(downloadService.start(item, dir: dir));
  }
}

/// 下载目录。
String downloadDirFor(String base) {
  final dir = Directory('$base${Platform.pathSeparator}downloads')
    ..createSync(recursive: true);
  return dir.path;
}
