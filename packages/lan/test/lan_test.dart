import 'dart:io';

import 'package:star_lan/star_lan.dart';
import 'package:test/test.dart';

void main() {
  group('LanPeer / PlayPush 序列化', () {
    test('往返', () {
      const peer =
          LanPeer(name: 'TV', deviceId: 'tv-1', ip: '192.168.1.8', port: 47891);
      final p2 = LanPeer.fromJson(peer.toJson());
      expect(p2.baseUrl, 'http://192.168.1.8:47891');

      const push = PlayPush(url: 'http://a/b.mp4', title: '测试');
      expect(PlayPush.fromJson(push.toJson()).url, push.url);
    });
  });

  group('LanServer + LanClient 回环', () {
    test('ping / play / backup', () async {
      PlayPush? got;
      final server = LanServer(
        port: 47999,
        deviceName: '测试设备',
        authToken: 'test-token',
        onPlayPush: (p) async => got = p,
        onBackupPull: () async => '{"version":1}',
        onBackupPush: (text) async => text.contains('version'),
      );
      await server.start();
      final peer = LanPeer(
        name: '本机',
        deviceId: 'local',
        ip: InternetAddress.loopbackIPv4.address,
        port: 47999,
      );
      final client = LanClient(authToken: 'test-token');
      expect(await client.ping(peer), isTrue);
      expect(
        await client.pushPlay(peer, const PlayPush(url: 'http://x/y', title: 'T')),
        isTrue,
      );
      expect(got?.url, 'http://x/y');
      expect(await client.pullBackup(peer), '{"version":1}');
      expect(await client.pushBackup(peer, '{"version":1}'), isTrue);
      await server.dispose();
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
