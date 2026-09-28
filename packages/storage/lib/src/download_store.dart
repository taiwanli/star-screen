import 'dart:convert';

import 'package:star_storage/star_storage.dart';

/// 下载任务状态（docs/02 §4.3 缓存下载）。
enum DownloadStatus { queued, running, done, failed }

class DownloadItem {
  final String id;
  final String title;
  final String url;
  final String? savePath;
  final int receivedBytes;
  final int? totalBytes;
  final DownloadStatus status;
  final String? error;
  final DateTime createdAt;

  const DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    this.savePath,
    this.receivedBytes = 0,
    this.totalBytes,
    this.status = DownloadStatus.queued,
    this.error,
    required this.createdAt,
  });

  double? get progress =>
      totalBytes == null || totalBytes == 0
          ? null
          : receivedBytes / totalBytes!;

  DownloadItem copyWith({
    String? savePath,
    int? receivedBytes,
    int? totalBytes,
    DownloadStatus? status,
    String? error,
  }) =>
      DownloadItem(
        id: id,
        title: title,
        url: url,
        savePath: savePath ?? this.savePath,
        receivedBytes: receivedBytes ?? this.receivedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        status: status ?? this.status,
        error: error ?? this.error,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'savePath': savePath,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'status': status.name,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DownloadItem.fromJson(Map<String, dynamic> m) => DownloadItem(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        url: m['url']?.toString() ?? '',
        savePath: m['savePath']?.toString(),
        receivedBytes: (m['receivedBytes'] as num?)?.toInt() ?? 0,
        totalBytes: (m['totalBytes'] as num?)?.toInt(),
        status: DownloadStatus.values
            .where((s) => s.name == m['status']?.toString())
            .firstOrNull ??
            DownloadStatus.queued,
        error: m['error']?.toString(),
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// 下载列表持久化（KV JSON；v0.9 断点续传用 receivedBytes）。
class DownloadStore {
  DownloadStore(this.kv);

  final KeyValueStore kv;
  static const _key = 'downloads';

  Future<List<DownloadItem>> list() async {
    final raw = await kv.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => DownloadItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> _save(List<DownloadItem> items) async {
    await kv.setString(
        _key, jsonEncode([for (final i in items) i.toJson()]));
  }

  Future<T> _locked<T>(Future<T> Function() op) {
    final next = _tail.then((_) => op());
    _tail = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _tail = Future<void>.value();
  static int _idSeq = 0;

  Future<DownloadItem> enqueue({
    required String title,
    required String url,
  }) {
    return _locked(() async {
      final items = await list();
      final item = DownloadItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_idSeq++}',
        title: title,
        url: url,
        createdAt: DateTime.now(),
      );
      await _save([item, ...items]);
      return item;
    });
  }

  Future<void> update(DownloadItem item) {
    return _locked(() async {
      final items = await list();
      final i = items.indexWhere((e) => e.id == item.id);
      if (i < 0) return;
      items[i] = item;
      await _save(items);
    });
  }

  Future<void> remove(String id) {
    return _locked(() async {
      final items = await list();
      await _save([for (final i in items) if (i.id != id) i]);
    });
  }

  Future<void> clear() => _locked(() => _save(const []));
}
