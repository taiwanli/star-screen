import 'dart:async';
import 'dart:io';

import 'package:star_storage/star_storage.dart';

/// 下载执行器：HttpClient 落盘 + 进度 + Range 断点续传（docs/02 §4.3）。
class DownloadService {
  DownloadService(this.store);

  final DownloadStore store;
  final Map<String, HttpClient> _active = {};

  /// 开始或续传；同 id 幂等。
  Future<void> start(DownloadItem item, {required String dir}) async {
    if (_active.containsKey(item.id)) return;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    _active[item.id] = client;

    final path = item.savePath ??
        '$dir${Platform.pathSeparator}${item.id}_${_safeName(item.title)}';
    final file = File(path);
    var received = item.savePath != null && await file.exists()
        ? await file.length()
        : 0;

    var current = item.copyWith(
      status: DownloadStatus.running,
      savePath: path,
      receivedBytes: received,
    );
    await store.update(current);

    RandomAccessFile? raf;
    try {
      final uri = Uri.parse(item.url);
      final req = await client.getUrl(uri);
      if (received > 0) {
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=$received-');
      }
      final res = await req.close();
      final resumeOk = received > 0 && res.statusCode == 206;
      if (res.statusCode >= 400 && res.statusCode != 416) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      if (received > 0 && !resumeOk) {
        // 服务器不支持 Range：从头开始
        received = 0;
        current = current.copyWith(receivedBytes: 0);
        // docs/13 A4：重置进度先落库一次，避免首段 256KB 节流前 UI 读到旧值
        await store.update(current);
      }

      final total = res.contentLength >= 0
          ? (resumeOk ? received + res.contentLength : res.contentLength)
          : null;
      await file.create(recursive: true);
      raf = await file.open(
          mode: resumeOk ? FileMode.writeOnlyAppend : FileMode.write);
      await raf.setPosition(resumeOk ? received : 0);

      var sinceSave = 0;
      await for (final chunk in res) {
        await raf.writeFrom(chunk);
        received += chunk.length;
        sinceSave += chunk.length;
        // 节流写库，降低 KV 竞态与 IO
        if (sinceSave >= 256 * 1024) {
          sinceSave = 0;
          current = current.copyWith(
            receivedBytes: received,
            totalBytes: total,
          );
          await store.update(current);
        }
      }
      await raf.flush();
      await raf.close();
      raf = null;
      await store.update(current.copyWith(
        status: DownloadStatus.done,
        receivedBytes: received,
        totalBytes: total ?? received,
        savePath: path,
      ));
    } on Object catch (e) {
      try {
        await raf?.close();
      } on Object {}
      // 保留半截文件以便续传；仅在取消时由 cancel 清理
      await store.update(current.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
      ));
    } finally {
      _active.remove(item.id)?.close(force: true);
    }
  }

  /// 启动队列中全部 queued / 可续传 failed 任务。
  Future<void> drainQueue(String dir) async {
    final items = await store.list();
    for (final i in items) {
      if (i.status == DownloadStatus.queued ||
          (i.status == DownloadStatus.failed &&
              i.error != '已取消' &&
              i.savePath != null)) {
        unawaited(start(i, dir: dir));
      }
    }
  }

  Future<void> cancel(String id) async {
    _active.remove(id)?.close(force: true);
    final items = await store.list();
    final item = items.where((e) => e.id == id).firstOrNull;
    if (item != null && item.status != DownloadStatus.done) {
      // 取消时清掉半截文件
      final p = item.savePath;
      if (p != null) {
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } on Object {}
      }
      await store.update(item.copyWith(
        status: DownloadStatus.failed,
        error: '已取消',
      ));
    }
  }

  static String _safeName(String title) {
    final cleaned = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'video' : cleaned;
  }
}
