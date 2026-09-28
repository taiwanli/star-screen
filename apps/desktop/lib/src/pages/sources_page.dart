import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_lan/star_lan.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import '../theme_notifier.dart';

/// 源管理（docs/05 §3）：列表 / 启停 / 删除 / 添加订阅。
class SourcesPage extends StatefulWidget {
  final AppServices services;
  final VoidCallback onChanged;

  const SourcesPage({super.key, required this.services, required this.onChanged});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  late Future<List<SourceDef>> _sources;
  final Map<String, SourceCheckResult> _checks = {};
  SourceFilter _filter = SourceFilter.all;
  bool _checking = false;
  int _checkDone = 0;
  int _checkTotal = 0;
  String? _groupFilter;
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

  final List<SourceCheckResult> _checkLog = [];
  final Set<String> _rechecking = {};

  Future<void> _checkAll() async {
    setState(() {
      _checking = true;
      _checkDone = 0;
      _checkTotal = 0;
      _checkLog.clear();
      _checks.clear();
    });
    final defs = await widget.services.registry.all();
    final adaptable = [
      for (final d in defs)
        if (d.kind.hasAdapter) widget.services.sourceFor(d),
    ];
    final checker = SourceChecker();
    final results = await checker.checkAll(
      adaptable,
      onProgress: (d, t) {
        if (mounted) {
          setState(() {
            _checkDone = d;
            _checkTotal = t;
          });
        }
      },
      onResult: (r) {
        if (!mounted) return;
        setState(() {
          _checks[r.key] = r;
          _checkLog
            ..removeWhere((e) => e.key == r.key)
            ..insert(0, r);
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
    });
    StarFeedback.success();
    final bad = results.where((r) => !r.ok).length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: StarColors.raised,
      content: Text('检测完成：${results.length} 个源，失效 $bad 个',
          style: const TextStyle(color: StarColors.ink)),
    ));
  }

  /// 单源重测（阅读「校验」单条）。
  Future<void> _checkOne(SourceDef def) async {
    if (_rechecking.contains(def.key) || !def.kind.hasAdapter) return;
    setState(() => _rechecking.add(def.key));
    try {
      final src = widget.services.sourceFor(def);
      final r = await SourceChecker().check(src);
      if (!mounted) return;
      setState(() {
        _checks[def.key] = r;
        _checkLog
          ..removeWhere((e) => e.key == r.key)
          ..insert(0, r);
      });
    } finally {
      if (mounted) setState(() => _rechecking.remove(def.key));
    }
  }

  Future<void> _deleteUnsupported() async {
    final defs = await widget.services.registry.all();
    if (!mounted) return;
    final keys = [
      for (final d in defs)
        if (!d.kind.isSupported) d.key,
    ];
    if (keys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('没有不支持的源', style: TextStyle(color: StarColors.ink)),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: StarColors.surface,
        title: const Text('清理不支持的源', style: TextStyle(fontSize: 16)),
        content: Text(
            '将删除 ${keys.length} 个需 jar 插件/暂不支持的源（不会影响可浏览源）。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StarColors.bad),
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除 ${keys.length} 个'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final k in keys) {
      await widget.services.registry.remove(k);
      _checks.remove(k);
    }
    if (!mounted) return;
    setState(_reload);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: StarColors.raised,
      content: Text('已清理 ${keys.length} 个不支持的源',
          style: const TextStyle(color: StarColors.ink)),
    ));
  }

  /// 清空全部内容源（用户要求删除自带/已导入的源）。
  Future<void> _clearAll() async {
    final defs = await widget.services.registry.all();
    if (defs.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StarColors.surface,
        title: const Text('清空全部源', style: TextStyle(fontSize: 16)),
        content: Text('将删除全部 ${defs.length} 个内容源，不可恢复。\n直播频道与本地收藏不受影响。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('全部删除', style: TextStyle(color: StarColors.bad)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final d in defs) {
      await widget.services.registry.remove(d.key);
    }
    // 同步清空直播频道（订阅 lives 导入的频道表）
    await widget.services.liveStore.clearAll();
    if (!mounted) return;
    setState(_reload);
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: StarColors.raised,
      content: Text('已清空全部内容源', style: TextStyle(color: StarColors.ink)),
    ));
  }

  Future<void> _deleteInvalid() async {
    final invalid = [
      for (final e in _checks.entries)
        if (!e.value.ok) e.key,
    ];
    if (invalid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('没有失效源 —— 请先「检测源」', style: TextStyle(color: StarColors.ink)),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: StarColors.surface,
        title: const Text('删除失效源', style: TextStyle(fontSize: 16)),
        content: Text('将删除 ${invalid.length} 个检测失败的源，不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StarColors.bad),
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除 ${invalid.length} 个'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final key in invalid) {
      await widget.services.registry.remove(key);
      _checks.remove(key);
    }
    setState(_reload);
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('已删除 ${invalid.length} 个失效源',
            style: const TextStyle(color: StarColors.ink)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('源管理',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('星映不内置任何内容源，请接入自有合法源',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: StarColors.ink4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 工具条可横向滚动，最大化窗口时「添加内容源」不会被裁掉
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: _checking ? null : _checkAll,
              icon: _checking
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.health_and_safety_outlined, size: 18),
              label: Text(_checking
                  ? '检测中 $_checkDone/$_checkTotal'
                  : '检测源'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _deleteInvalid,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('删除失效源'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _batchMode = !_batchMode;
                  if (!_batchMode) _selected.clear();
                });
              },
              icon: Icon(_batchMode ? Icons.close : Icons.checklist, size: 18),
              label: Text(_batchMode ? '退出批量' : '批量操作'),
            ),
            if (_batchMode) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () async {
                        for (final k in _selected) {
                          await widget.services.registry.setEnabled(k, true);
                        }
                        setState(() {
                          _reload();
                          _selected.clear();
                        });
                        widget.onChanged();
                      },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text('启用(${_selected.length})'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () async {
                        for (final k in _selected) {
                          await widget.services.registry.setEnabled(k, false);
                        }
                        setState(() {
                          _reload();
                          _selected.clear();
                        });
                        widget.onChanged();
                      },
                icon: const Icon(Icons.pause, size: 18),
                label: const Text('停用'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () async {
                        for (final k in _selected) {
                          await widget.services.registry.remove(k);
                        }
                        setState(() {
                          _reload();
                          _selected.clear();
                        });
                        widget.onChanged();
                      },
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('删除'),
              ),
            ],
            if (!_batchMode) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _deleteUnsupported,
              icon: const Icon(Icons.block, size: 18),
              label: const Text('清理不支持'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
              label: const Text('清空全部源'),
            ),
            ],
          ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 固定右侧，最大化窗口也始终可见
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: StarColors.brand),
              onPressed: _addSource,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加内容源'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 筛选（阅读 APP：全部/启用/失效/停用）
        FutureBuilder<List<SourceDef>>(
          future: _sources,
          builder: (context, snap) {
            final all = snap.data ?? const <SourceDef>[];
            Widget chip(SourceFilter f, String label, int count) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('$label（$count）',
                      style: const TextStyle(fontSize: 11)),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              );
            }

            final invalidCount =
                _checks.values.where((c) => !c.ok).length;
            final groups = <String>{for (final s in all) if ((s.groupId ?? '').isNotEmpty) s.groupId!};
            return Wrap(
              children: [
                chip(SourceFilter.all, '全部', all.length),
                for (final g in groups)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(g, style: const TextStyle(fontSize: 11)),
                      selected: _groupFilter == g,
                      onSelected: (_) => setState(() {
                        _groupFilter = _groupFilter == g ? null : g;
                      }),
                    ),
                  ),
                chip(
                    SourceFilter.enabled,
                    '启用',
                    all.where((s) => s.enabled).length),
                chip(SourceFilter.invalid, '失效', invalidCount),
                chip(SourceFilter.disabled, '停用',
                    all.where((s) => !s.enabled).length),
                chip(SourceFilter.unsupported, '不支持',
                    all.where((s) => !s.kind.isSupported).length),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                StarFeedback.soundEnabled = !StarFeedback.soundEnabled;
                StarFeedback.hapticEnabled = StarFeedback.soundEnabled;
                if (StarFeedback.soundEnabled) StarFeedback.selection();
                setState(() {});
              },
              icon: Icon(
                  StarFeedback.soundEnabled
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  size: 16),
              label: Text(StarFeedback.soundEnabled ? '音效开' : '音效关',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
            TextButton.icon(
              onPressed: () {
                StarFeedback.reduceMotion = !StarFeedback.reduceMotion;
                setState(() {});
              },
              icon: Icon(
                  StarFeedback.reduceMotion
                      ? Icons.motion_photos_off
                      : Icons.motion_photos_on,
                  size: 16),
              label: Text(StarFeedback.reduceMotion ? '减弱动效' : '全动效',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
            TextButton.icon(
              onPressed: themeNotifier.toggle,
              icon: const Icon(Icons.palette_outlined, size: 16),
              label: const Text('切换亮/暗主题',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
            TextButton.icon(
              onPressed: _checkUpdate,
              icon: const Icon(Icons.system_update, size: 16),
              label: const Text('检查更新',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
            TextButton.icon(
              onPressed: _pickHomeSource,
              icon: const Icon(Icons.home_outlined, size: 16),
              label: const Text('默认首页源',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
            TextButton.icon(
              onPressed: _pickEngine,
              icon: const Icon(Icons.play_circle_outline, size: 16),
              label: const Text('播放引擎',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
            TextButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: const Text('清理缓存',
                  style: TextStyle(fontSize: 11, color: StarColors.ink4)),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildSourceList()),
              if (_checkLog.isNotEmpty) ...[
                const VerticalDivider(width: 1, color: StarColors.line),
                Expanded(flex: 2, child: _buildCheckLog()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckLog() {
    return Container(
      color: StarColors.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              _checking
                  ? '检测进度 $_checkDone/$_checkTotal'
                  : '检测结果（${_checkLog.length}）',
              style: const TextStyle(fontSize: 12, color: StarColors.ink3),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _checkLog.length,
              itemBuilder: (_, i) {
                final r = _checkLog[i];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    r.ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 16,
                    color: r.ok ? StarColors.brandHi : StarColors.bad,
                  ),
                  title: Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: StarColors.ink)),
                  subtitle: Text(
                    r.ok ? '${r.latencyMs ?? '-'}ms' : (r.reason ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: r.ok ? StarColors.ink3 : StarColors.bad),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceList() {
    return FutureBuilder<List<SourceDef>>(
      future: _sources,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: StarColors.brand));
        }
        final all = snap.data ?? const <SourceDef>[];
        var sources = _filter.apply(all, _checks);
        final g = _groupFilter;
        if (g != null && g.isNotEmpty) {
          sources = [for (final s in sources) if (s.groupId == g) s];
        }
        if (sources.isEmpty) {
          return Center(
            child: Text(
              _filter == SourceFilter.invalid
                  ? '暂无失效源 —— 点「检测源」筛查'
                  : _filter == SourceFilter.unsupported
                      ? '暂无不支持的源'
                      : '还没有内容源 —— 点击右上角「添加内容源」',
              style: const TextStyle(color: StarColors.ink4),
            ),
          );
        }
        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: sources.length,
          // Flutter 3.41+：onReorderItem 的 newIndex 已扣除移除位
          onReorderItem: (oldIndex, newIndex) async {
            final list = [...sources];
            final item = list.removeAt(oldIndex);
            list.insert(newIndex, item);
            await widget.services.registry
                .reorder([for (final s in list) s.key]);
            setState(_reload);
            StarFeedback.selection();
          },
          itemBuilder: (_, i) {
            final s = sources[i];
            return Padding(
              key: ValueKey('src-${s.key}'),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  ReorderableDelayedDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.drag_handle, size: 18, color: StarColors.ink4),
                    ),
                  ),
                  Expanded(child: _row(s)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _healthColor(SourceDef def, SourceCheckResult? check) {
    if (!def.kind.isSupported) return StarColors.ink4;
    if (check == null) return StarColors.ink3;
    if (!check.ok) return StarColors.bad;
    final ms = check.latencyMs ?? 9999;
    if (ms < 500) return StarColors.brandHi;
    if (ms < 1500) return const Color(0xFFE6A23C);
    return const Color(0xFF909399);
  }

  Widget _row(SourceDef def) {
    final check = _checks[def.key];
    final invalid = check != null && !check.ok;
    final supported = def.kind.isSupported;
    final group = def.groupId;
    return ListTile(
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
              invalid
                  ? Icons.error_outline
                  : (supported ? Icons.storage_outlined : Icons.block_outlined),
              color: invalid
                  ? StarColors.bad
                  : (supported ? StarColors.brandHi : StarColors.ink4),
            ),
      title: Text(def.name,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: supported ? StarColors.ink : StarColors.ink4)),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: _healthColor(def, check),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              [
                if (group != null && group.isNotEmpty) group,
                if (invalid)
                  '失效：${check.reason ?? '未知原因'}'
                else if (check?.ok == true)
                  '正常 · ${check!.latencyMs ?? '-'}ms'
                else if (supported)
                  _kindLabel(def.kind)
                else
                  '不支持 · ${def.unsupportedReason ?? '暂无适配器'}',
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: invalid
                    ? StarColors.bad
                    : (supported ? StarColors.ink3 : StarColors.bad),
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: def.enabled,
            onChanged: supported
                ? (v) async {
                    await widget.services.registry.setEnabled(def.key, v);
                    setState(_reload);
                    widget.onChanged();
                  }
                : null,
            activeThumbColor: StarColors.brandHi,
          ),
          IconButton(
            icon: _rechecking.contains(def.key)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 18),
            color: StarColors.ink4,
            tooltip: '重测',
            onPressed: def.kind.hasAdapter ? () => _checkOne(def) : null,
          ),
          if (invalid)
            IconButton(
              icon: const Icon(Icons.healing, size: 18),
              color: StarColors.brandHi,
              tooltip: '一键恢复',
              onPressed: () async {
                widget.services.healthMonitor.recover(def.key);
                await _checkOne(def);
                setState(_reload);
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: StarColors.ink4,
            tooltip: '删除',
            onPressed: () async {
              await widget.services.registry.remove(def.key);
              setState(_reload);
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }

  String _kindLabel(SourceKind kind) => switch (kind) {
        SourceKind.cmsJson => '苹果CMS JSON',
        SourceKind.cmsXml => '苹果CMS XML',
        SourceKind.xpathRule => 'XPath 规则源',
        SourceKind.drpyJs => 'JS 源（沙箱）',
        SourceKind.spiderJar => 'jar 蜘蛛',
        SourceKind.starRule => 'StarRule 三端源',
        SourceKind.alist => 'Alist 网盘',
        SourceKind.live => '直播',
        SourceKind.unsupported => '不支持',
      };

  Future<void> _pickHomeSource() async {
    final defs = await widget.services.registry.enabled();
    final adaptable = [
      for (final d in defs)
        if (d.kind.hasAdapter) d,
    ];
    if (adaptable.isEmpty) return;
    final cur = await widget.services.pickHomeSource();
    if (!mounted) return;
    final picked = await showDialog<SourceDef>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: StarColors.surface,
        title: const Text('默认首页源', style: TextStyle(fontSize: 16)),
        children: [
          for (final s in adaptable)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s),
              child: Text(s.name,
                  style: TextStyle(
                      fontSize: 13,
                      color: s.key == cur?.key
                          ? StarColors.brandHi
                          : StarColors.ink)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await widget.services.setHomeSourceKey(picked.key);
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('默认首页源：${picked.name}',
            style: const TextStyle(color: StarColors.ink)),
      ));
    }
  }

  Future<void> _pickEngine() async {
    final cur = await widget.services.playerEngine();
    if (!mounted) return;
    final picked = await showDialog<PlayerEngineType>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: StarColors.surface,
        title: const Text('播放引擎', style: TextStyle(fontSize: 16)),
        children: [
          for (final t in PlayerEngineType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text(PlayerEnginePref.describe(t),
                  style: TextStyle(
                      fontSize: 13,
                      color: t == cur ? StarColors.brandHi : StarColors.ink)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await widget.services.setPlayerEngine(picked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('播放引擎：${PlayerEnginePref.describe(picked)}',
            style: const TextStyle(color: StarColors.ink)),
      ));
    }
  }

  Future<void> _clearCache() async {
    await widget.services.kv.remove('searchHistory');
    await widget.services.kv.remove('cat:');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: StarColors.raised,
        content: Text('已清理搜索历史与分类记忆',
            style: TextStyle(color: StarColors.ink)),
      ));
    }
  }

  static const _updateManifest =
      'https://raw.githubusercontent.com/taiwanli/XingYing/main/version.json';

  Future<void> _checkUpdate() async {
    final checker = UpdateChecker(getText: (url) async {
      final client = HttpClient();
      try {
        final req =
            await client.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 5));
        final res = await req.close();
        return await res.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    });
    final info = await checker.check(_updateManifest, '0.1.0-dev.22');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: StarColors.raised,
      content: Text(
        info == null
            ? '已是最新版本'
            : '发现新版本 ${info.version}${info.notes == null ? '' : '：${info.notes}'}',
        style: const TextStyle(color: StarColors.ink),
      ),
    ));
  }

  Future<void> _addSource() async {
    final result = await ImportWizardDialog.show(
      context,
      title: '添加内容源',
      onImport: (ref) async {
        final summary = await widget.services.importFromRef(ref);
        final defs = await widget.services.registry.all();
        return ImportWizardResult(
          configs: summary.configs,
          sites: summary.sites,
          unsupported: summary.unsupported,
          failedWarehouses: summary.failedWarehouses,
          sources: [
            for (final d in defs)
              ImportSourceLine(
                name: d.name,
                supported: d.kind.isSupported,
                reason: d.unsupportedReason,
              ),
          ],
        );
      },
    );
    if (result == null) return;
    setState(_reload);
    widget.onChanged();
  }
}
