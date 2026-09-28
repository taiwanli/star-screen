import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 「我的」：收藏 / 历史 / 导出导入（docs/02 §4.4）。
class LibraryPage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;
  final VoidCallback? onOpenLan;

  const LibraryPage({
    super.key,
    required this.services,
    required this.onOpenDetail,
    this.onOpenLan,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<FavoriteItem>, List<ContinueItem>)>(
      future: _load(),
      builder: (context, snap) {
        final data = snap.data;
        final favs = data?.$1 ?? const <FavoriteItem>[];
        final hist = data?.$2 ?? const <ContinueItem>[];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.onOpenLan != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: widget.onOpenLan,
                    icon: const Icon(Icons.lan, size: 16),
                    label: const Text('局域网互联 / 下载',
                        style: TextStyle(
                            fontSize: 12, color: StarColors.ink3)),
                  ),
                ),
              Expanded(
                child: LibraryPanel(
            favorites: [
              for (final f in favs)
                LibraryItem(
                  workKey: f.favorite.workKey,
                  title: f.title,
                  subtitle: f.favorite.snapshot.remarks ??
                      f.favorite.snapshot.year,
                  posterUrl: f.posterUrl,
                ),
            ],
            history: [
              for (final h in hist)
                LibraryItem(
                  workKey: h.record.workKey,
                  title: h.title,
                  subtitle: h.subtitle,
                  posterUrl: h.posterUrl,
                ),
            ],
            onOpen: (item) => _open(item),
            onRemoveFavorite: (item) async {
              await widget.services.favoriteStore.remove(item.workKey);
              setState(() {});
            },
            onRemoveHistory: (item) async {
              await widget.services.playRecordStore.delete(item.workKey);
              setState(() {});
            },
            onClearHistory: () async {
              await widget.services.playRecordStore.clearAll();
              setState(() {});
            },
            onExport: _export,
            onImport: _import,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<(List<FavoriteItem>, List<ContinueItem>)> _load() async {
    final favs = await widget.services.favoriteStore.listAll();
    final hist = await widget.services.playRecordStore.historyDetailed();
    return (favs, hist);
  }

  Future<void> _open(LibraryItem item) async {
    final sources = await widget.services.registry.all();
    final def = sources
          .where((s) => item.workKey.startsWith('${s.key}::'))
          .firstOrNull;
    if (def == null || !mounted) return;
    widget.onOpenDetail(
      def,
      WorkCard(
        sourceKey: def.key,
        workId: SourceDef.workIdFromKey(item.workKey, def.key),
        title: item.title,
        posterUrl: item.posterUrl,
      ),
    );
  }

  Future<void> _export() async {
    final text = await widget.services.backup.exportAll();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('已复制 ${text.length} 字符到剪贴板（可粘贴保存为备份文件）',
            style: const TextStyle(color: StarColors.ink)),
      ));
    }
  }

  Future<void> _import() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: StarColors.surface,
        title: const Text('导入备份', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 8,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            hintText: '粘贴导出的 JSON…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StarColors.brand),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      final stat = await widget.services.backup.importAll(text);
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text(
              '导入完成：源 ${stat['sources']} · 记录 ${stat['records']} · 收藏 ${stat['favorites']}',
              style: const TextStyle(color: StarColors.ink)),
        ));
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text('导入失败：$e',
              style: const TextStyle(color: StarColors.bad)),
        ));
      }
    }
  }
}
