import 'package:flutter/material.dart';
import 'colors.dart';

/// 收藏 / 历史 / 导出导入面板（docs/02 §4.4）。
class LibraryPanel extends StatelessWidget {
  final List<LibraryItem> favorites;
  final List<LibraryItem> history;
  final void Function(LibraryItem item) onOpen;
  final void Function(LibraryItem item)? onRemoveFavorite;
  final void Function(LibraryItem item)? onRemoveHistory;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback? onClearHistory;

  const LibraryPanel({
    super.key,
    required this.favorites,
    required this.history,
    required this.onOpen,
    this.onRemoveFavorite,
    this.onRemoveHistory,
    required this.onExport,
    required this.onImport,
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: TabBar(
                  labelColor: Color(0xFF4C9AFF),
                  unselectedLabelColor: StarColors.ink3,
                  indicatorColor: Color(0xFF4C9AFF),
                  tabs: [Tab(text: '收藏'), Tab(text: '观看历史')],
                ),
              ),
              TextButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.upload, size: 16),
                label: const Text('导出',
                    style: TextStyle(
                        fontSize: 12, color: StarColors.ink3)),
              ),
              TextButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('导入',
                    style: TextStyle(
                        fontSize: 12, color: StarColors.ink3)),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ItemList(
                  items: favorites,
                  empty: '暂无收藏',
                  onOpen: onOpen,
                  onRemove: onRemoveFavorite,
                ),
                _ItemList(
                  items: history,
                  empty: '暂无观看记录',
                  onOpen: onOpen,
                  onRemove: onRemoveHistory,
                  footer: onClearHistory == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextButton(
                            onPressed: onClearHistory,
                            child: const Text('清空历史',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF6B6B))),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryItem {
  final String workKey;
  final String title;
  final String? subtitle;
  final String? posterUrl;

  const LibraryItem({
    required this.workKey,
    required this.title,
    this.subtitle,
    this.posterUrl,
  });
}

class _ItemList extends StatelessWidget {
  final List<LibraryItem> items;
  final String empty;
  final void Function(LibraryItem) onOpen;
  final void Function(LibraryItem)? onRemove;
  final Widget? footer;

  const _ItemList({
    required this.items,
    required this.empty,
    required this.onOpen,
    this.onRemove,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(empty,
            style: const TextStyle(fontSize: 13, color: StarColors.ink3)),
      );
    }
    return ListView.separated(
      itemCount: items.length + (footer == null ? 0 : 1),
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0x22FFFFFF)),
      itemBuilder: (context, i) {
        if (footer != null && i == items.length) return footer!;
        final item = items[i];
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 64,
            child: item.posterUrl == null
                ? Container(
                    color: const Color(0xFF20262E),
                    child: const Icon(Icons.movie_outlined,
                        size: 18, color: StarColors.ink4),
                  )
                : Image.network(
                  item.posterUrl!,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0',
                  },
                    errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF20262E),
                        child: const Icon(Icons.broken_image_outlined,
                            size: 18, color: StarColors.ink4))),
          ),
          title: Text(item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: StarColors.ink)),
          subtitle: item.subtitle == null
              ? null
              : Text(item.subtitle!,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 11, color: StarColors.ink3)),
          trailing: onRemove == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 16, color: StarColors.ink4),
                  onPressed: () => onRemove!(item),
                ),
          onTap: () => onOpen(item),
        );
      },
    );
  }
}