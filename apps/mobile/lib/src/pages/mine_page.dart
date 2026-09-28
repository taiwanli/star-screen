import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import 'detail_page.dart';
import 'lan_page.dart';

/// 我的：本机数据（无账号体系）+ 源管理 + 收藏/历史入口。
class MinePage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard)? onOpenDetail;

  const MinePage({super.key, required this.services, this.onOpenDetail});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  late Future<List<SourceDef>> _sources;
  bool _batchMode = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _sources = widget.services.registry.all();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('源管理',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FutureBuilder<List<SourceDef>>(
          future: _sources,
          builder: (context, snap) {
            final sources = snap.data ?? const <SourceDef>[];
            return Column(
              children: [
                for (final def in sources) _row(def),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StarColors.brandHi,
                          side: const BorderSide(color: StarColors.brandHi),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _addSource,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加内容源'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StarColors.brandHi,
                          side: const BorderSide(color: StarColors.brandHi),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          setState(() {
                            _batchMode = !_batchMode;
                            if (!_batchMode) _selected.clear();
                          });
                        },
                        icon: Icon(
                            _batchMode ? Icons.close : Icons.checklist,
                            size: 18),
                        label: Text(_batchMode ? '退出批量' : '批量'),
                      ),
                    ),
                  ],
                ),
                if (_batchMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _selected.isEmpty
                                ? null
                                : () async {
                                    for (final k in _selected) {
                                      await widget.services.registry
                                          .setEnabled(k, true);
                                    }
                                    setState(() {
                                      _reload();
                                      _selected.clear();
                                    });
                                  },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text('启用(${_selected.length})'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _selected.isEmpty
                                ? null
                                : () async {
                                    for (final k in _selected) {
                                      await widget.services.registry
                                          .setEnabled(k, false);
                                    }
                                    setState(() {
                                      _reload();
                                      _selected.clear();
                                    });
                                  },
                            icon: const Icon(Icons.pause, size: 18),
                            label: const Text('停用'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text('我的内容',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.favorite_outline, color: StarColors.ink3),
          title: const Text('收藏与历史', style: TextStyle(fontSize: 15)),
          trailing: const Icon(Icons.chevron_right, color: StarColors.ink4),
          dense: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _LibraryRoute(services: widget.services),
          )),
        ),
        ListTile(
          leading: const Icon(Icons.lan, color: StarColors.ink3),
          title: const Text('局域网互联 / 下载', style: TextStyle(fontSize: 15)),
          trailing: const Icon(Icons.chevron_right, color: StarColors.ink4),
          dense: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LanPage(services: widget.services),
          )),
        ),
        ListTile(
          leading: const Icon(Icons.upload, color: StarColors.ink3),
          title: const Text('导出备份', style: TextStyle(fontSize: 15)),
          dense: true,
          onTap: _export,
        ),
        ListTile(
          leading: const Icon(Icons.download, color: StarColors.ink3),
          title: const Text('导入备份', style: TextStyle(fontSize: 15)),
          dense: true,
          onTap: _import,
        ),
        const SizedBox(height: 20),
        const Text('设置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const ListTile(
          leading: Icon(Icons.play_circle_outline, color: StarColors.ink3),
          title: Text('播放内核', style: TextStyle(fontSize: 15)),
          trailing: Text('libmpv（v0.1 统一）',
              style: TextStyle(fontSize: 12, color: StarColors.ink4)),
          dense: true,
        ),
        const ListTile(
          leading: Icon(Icons.sync_outlined, color: StarColors.ink3),
          title: Text('设备同步', style: TextStyle(fontSize: 15)),
          trailing: Text('v0.9 接入', style: TextStyle(fontSize: 12, color: StarColors.ink4)),
          dense: true,
        ),
        const ListTile(
          leading: Icon(Icons.info_outline, color: StarColors.ink3),
          title: Text('关于星映', style: TextStyle(fontSize: 15)),
          trailing: Text('0.1.0-dev', style: TextStyle(fontSize: 12, color: StarColors.ink4)),
          dense: true,
        ),
      ],
    );
  }

  String _kindLabel(SourceKind kind) => switch (kind) {
        SourceKind.cmsJson => '苹果CMS JSON',
        SourceKind.cmsXml => '苹果CMS XML',
        SourceKind.xpathRule => 'XPath 规则',
        SourceKind.drpyJs => 'JS 源',
        SourceKind.spiderJar => 'jar 蜘蛛',
        SourceKind.starRule => 'StarRule 三端源',
        SourceKind.alist => 'Alist 网盘',
        SourceKind.live => '直播',
        SourceKind.unsupported => '不支持',
      };

  Widget _row(SourceDef def) {
    final supported = def.kind.isSupported;
    final group = def.groupId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: _batchMode
          ? Checkbox(
              value: _selected.contains(def.key),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(def.key);
                  } else {
                    _selected.remove(def.key);
                  }
                });
              },
            )
          : Icon(
              supported ? Icons.storage_outlined : Icons.block_outlined,
              color: supported ? StarColors.brandHi : StarColors.ink4,
              size: 22,
            ),
      title: Text(def.name,
          style: TextStyle(
              fontSize: 15,
              color: supported ? StarColors.ink : StarColors.ink4)),
      subtitle: Text(
        [
          if (group != null && group.isNotEmpty) group,
          if (supported)
            _kindLabel(def.kind)
          else
            def.unsupportedReason ?? '不支持：需原生蜘蛛 jar',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 12, color: supported ? StarColors.ink3 : StarColors.bad),
      ),
      trailing: Switch(
        value: def.enabled,
        onChanged: supported
            ? (v) async {
                await widget.services.registry.setEnabled(def.key, v);
                setState(_reload);
              }
            : null,
        activeThumbColor: StarColors.brandHi,
      ),
    );
  }

  Future<void> _addSource() async {
    final result = await ImportWizardDialog.show(
      context,
      title: '添加内容源',
      onImport: (ref) async {
        final report = await widget.services.importFromRef(ref);
        return ImportWizardResult(
          configs: 1,
          sites: report.sources.length,
          unsupported: report.countOf(SourceKind.unsupported),
          sources: [
            for (final s in report.sources)
              ImportSourceLine(
                name: s.name,
                supported: s.kind.isSupported,
                reason: s.unsupportedReason,
              ),
          ],
          issues: [for (final i in report.issues) i.toString()],
        );
      },
    );
    if (result == null) return;
    setState(_reload);
  }

  Future<void> _export() async {
    final text = await widget.services.backup.exportAll();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('已复制备份到剪贴板（${text.length} 字符）',
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
          maxLines: 6,
          decoration: const InputDecoration(
              hintText: '粘贴导出的 JSON…', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StarColors.brand),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final stat = await widget.services.backup.importAll(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: StarColors.raised,
        content: Text(
            '导入完成：源 ${stat['sources']} · 记录 ${stat['records']} · 收藏 ${stat['favorites']}',
            style: const TextStyle(color: StarColors.ink)),
      ));
    }
  }
}

class _LibraryRoute extends StatefulWidget {
  final AppServices services;

  const _LibraryRoute({required this.services});

  @override
  State<_LibraryRoute> createState() => _LibraryRouteState();
}

class _LibraryRouteState extends State<_LibraryRoute> {
  late Future<(List<FavoriteItem>, List<ContinueItem>)> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<(List<FavoriteItem>, List<ContinueItem>)> _load() async {
    final favs = await widget.services.favoriteStore.listAll();
    final hist = await widget.services.playRecordStore.historyDetailed();
    return (favs, hist);
  }

  void _refresh() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StarColors.glass,
        title: const Text('收藏与历史',
            style: TextStyle(fontSize: 16, color: StarColors.ink)),
      ),
      body: FutureBuilder<(List<FavoriteItem>, List<ContinueItem>)>(
        future: _data,
        builder: (context, snap) {
          final data = snap.data;
          return LibraryPanel(
            favorites: [
              for (final f in data?.$1 ?? const <FavoriteItem>[])
                LibraryItem(
                  workKey: f.favorite.workKey,
                  title: f.title,
                  subtitle: f.favorite.snapshot.year,
                  posterUrl: f.posterUrl,
                ),
            ],
            history: [
              for (final h in data?.$2 ?? const <ContinueItem>[])
                LibraryItem(
                  workKey: h.record.workKey,
                  title: h.title,
                  subtitle: h.subtitle,
                  posterUrl: h.posterUrl,
                ),
            ],
            onOpen: (item) async {
              final sources = await widget.services.registry.all();
              final def = sources
                  .where((s) => item.workKey.startsWith('${s.key}::'))
                  .firstOrNull;
              if (def == null || !context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DetailPage(
                  services: widget.services,
                  def: def,
                  card: WorkCard(
                    sourceKey: def.key,
                    workId: SourceDef.workIdFromKey(item.workKey, def.key),
                    title: item.title,
                    posterUrl: item.posterUrl,
                  ),
                ),
              ));
            },
            onRemoveFavorite: (item) async {
              await widget.services.favoriteStore.remove(item.workKey);
              _refresh();
            },
            onRemoveHistory: (item) async {
              await widget.services.playRecordStore.delete(item.workKey);
              _refresh();
            },
            onClearHistory: () async {
              await widget.services.playRecordStore.clearAll();
              _refresh();
            },
            onExport: () async {
              final text = await widget.services.backup.exportAll();
              await Clipboard.setData(ClipboardData(text: text));
            },
            onImport: () {},
          );
        },
      ),
    );
  }
}
