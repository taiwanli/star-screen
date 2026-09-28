import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// 局域网 HTTP 服务（推送播放 / 备份同步）。
///
/// | 路径 | 方法 | 语义 |
/// |---|---|---|
/// | `/ping` | GET | 存活探测 |
/// | `/play` | POST | 推送播放（PlayPush JSON） |
/// | `/backup` | GET/POST | 拉取/推送备份 JSON |
class LanServer {
  LanServer({
    this.port = 47891,
    required this.deviceName,
    required this.onPlayPush,
    required this.onBackupPull,
    this.onBackupPush,
    this.authToken,
    this.maxBodyBytes = 8 * 1024 * 1024,
  });

  final int port;
  final String deviceName;
  final Future<void> Function(PlayPush push) onPlayPush;

  /// 对端 GET /backup 时返回本机备份 JSON。
  final Future<String> Function() onBackupPull;

  /// 对端 POST /backup 时写入；返回是否接受。
  final Future<bool> Function(String jsonText)? onBackupPush;

  /// 可选共享口令；非空则 /play、/backup 必须带 `X-Star-Token`。
  final String? authToken;

  /// 请求体上限（防超大备份打爆内存）。
  final int maxBodyBytes;

  HttpServer? _server;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handle, onError: (_) {});
  }

  bool _authed(HttpRequest req) {
    // 默认未配置口令也拒绝敏感端口，仅 /ping 开放（P04）
    if (authToken == null || authToken!.isEmpty) return false;
    return req.headers.value('X-Star-Token') == authToken;
  }

  /// 读取请求体并按 [maxBodyBytes] 截断（docs/13 A2：原 maxBodyBytes 字段从未生效）。
  /// 超限返回 null 并已回复 413，调用方直接 return。
  Future<String?> _limitedBody(HttpRequest req) async {
    var total = 0;
    final chunks = <List<int>>[];
    await for (final chunk in req) {
      total += chunk.length;
      if (total > maxBodyBytes) {
        await _json(req, 413, {'error': 'body too large'});
        return null;
      }
      chunks.add(chunk);
    }
    final bytes = <int>[];
    for (final c in chunks) {
      bytes.addAll(c);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _handle(HttpRequest req) async {
    try {
      final path = req.uri.path;
      if (path == '/ping') {
        await _json(req, 200, {
          'app': 'StarScreen',
          'name': deviceName,
          'port': port,
        });
        return;
      }
      if (!_authed(req)) {
        await _json(req, 401, {'error': 'unauthorized'});
        return;
      }
      if (path == '/play' && req.method == 'POST') {
        final body = await _limitedBody(req);
        if (body == null) return;
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          await _json(req, 400, {'error': 'invalid json'});
          return;
        }
        final m = decoded;
        final push = PlayPush.fromJson(m);
        if (push.url.isEmpty) {
          await _json(req, 400, {'error': 'missing url'});
          return;
        }
        await onPlayPush(push);
        await _json(req, 200, {'ok': true});
        return;
      }
      if (path == '/backup') {
        if (req.method == 'GET') {
          final text = await onBackupPull();
          req.response.headers.contentType = ContentType.json;
          req.response.write(text);
          await req.response.close();
          return;
        }
        if (req.method == 'POST') {
          final body = await _limitedBody(req);
          if (body == null) return;
          final ok = onBackupPush == null ? false : await onBackupPush!(body);
          await _json(req, ok ? 200 : 409, {'ok': ok});
          return;
        }
      }
      await _json(req, 404, {'error': 'not found'});
    } on Object catch (e) {
      try {
        await _json(req, 500, {'error': e.toString()});
      } on Object {}
    }
  }

  Future<void> _json(HttpRequest req, int code, Map<String, Object?> body) async {
    final res = req.response;
    res.statusCode = code;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
    await res.close();
  }

  Future<void> dispose() async {
    await _server?.close(force: true);
    _server = null;
  }
}
