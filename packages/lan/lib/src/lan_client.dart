import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// 局域网客户端：推送播放 / 拉取与推送备份。
class LanClient {
  final Duration timeout;
  final String? authToken;

  LanClient({this.timeout = const Duration(seconds: 5), this.authToken});

  void _auth(HttpClientRequest req) {
    if (authToken != null && authToken!.isNotEmpty) {
      req.headers.set('X-Star-Token', authToken!);
    }
  }

  Future<bool> ping(LanPeer peer) async {
    final client = HttpClient();
    try {
      final req =
          await client.getUrl(Uri.parse('${peer.baseUrl}/ping')).timeout(timeout);
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join();
      return body.contains('StarScreen');
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// 推送播放到目标设备（docs/02 §4.9 手机 → TV）。
  Future<bool> pushPlay(LanPeer peer, PlayPush push) async {
    final client = HttpClient();
    try {
      final req = await client
          .postUrl(Uri.parse('${peer.baseUrl}/play'))
          .timeout(timeout);
      req.headers.contentType = ContentType.json;
      _auth(req);
      req.write(jsonEncode(push.toJson()));
      final res = await req.close().timeout(timeout);
      await res.drain<void>();
      return res.statusCode == 200;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// 拉取对方备份 JSON。
  Future<String?> pullBackup(LanPeer peer) async {
    final client = HttpClient();
    try {
      final req =
          await client.getUrl(Uri.parse('${peer.baseUrl}/backup')).timeout(timeout);
      _auth(req);
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join();
      return res.statusCode == 200 ? text : null;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// 推送备份 JSON 到对方。
  Future<bool> pushBackup(LanPeer peer, String jsonText) async {
    final client = HttpClient();
    try {
      final req = await client
          .postUrl(Uri.parse('${peer.baseUrl}/backup'))
          .timeout(timeout);
      req.headers.contentType = ContentType.json;
      _auth(req);
      req.write(jsonText);
      final res = await req.close().timeout(timeout);
      await res.drain<void>();
      return res.statusCode == 200;
    } on Object {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
