import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 分类浏览 v2（docs/19 P0）：玻璃筛选 Chip 条 + 结果计数 + 海报墙。
class CategoryPage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;

  const CategoryPage({
    super.key,
    required this.services,
    required this.onOpenDetail,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  SourceDef? _source;
  List<SourceDef> _sources = const [];
  String? _typeId;
  String _year = '';
  String _sortLabel = '按更新';
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  final List<WorkCard> _items = [];
  final _scroll = ScrollController();

  static const _years = ['全部', '2026', '2025', '2024', '2023'];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final sources = await widget.services.enabledSources();
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _source = sources.where((s) => s.kind.hasAdapter).firstOrNull ??
          sources.firstOrNull;
    });
    await _load(reset: true);
    await _restoreMemory();
  }

  Future<void> _restoreMemory() async {
    if (_source == null) return;
    final saved = await widget.services.kv.getString('cat:${_source!.key}');
    if (saved != null && mounted) {
      setState(() => _typeId = saved);
      await _load(reset: true);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    final source = _source;
    if (source == null || _loading) return;
    if (!reset && !_hasMore) return;
    setState(() => _loading = true);
    try {
      if (reset) {
        _page = 1;
        _items.clear();
        _hasMore = true;
      }
      final result = await widget.services.sourceFor(source).category(
            CategoryQuery(
              typeId: _typeId,
              page: _page,
              filters: {
                if (_year.isNotEmpty && _year != '全部') 'year': _year,
              },
            ),
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        if (_hasMore) _page++;
      });
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: StarColors.raised,
          content: Text('分类加载失败：$e',
              style: const TextStyle(color: StarColors.bad)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectYear(String y) {
    setState(() => _year = y == '全部' ? '' : y);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 玻璃筛选条 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: StarColors.glass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: StarColors.neuDark.withValues(alpha: 0.35),
                  offset: const Offset(4, 4),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: StarColors.neuLight.withValues(alpha: 0.85),
                  offset: const Offset(-3, -3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // 源切换
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: StarColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: DropdownButton<SourceDef>(
                    value: _source,
                    dropdownColor: StarColors.surface,
                    style: const TextStyle(fontSize: 13, color: StarColors.ink),
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.expand_more,
                        size: 18, color: StarColors.ink3),
                    items: [
                      for (final s in _sources)
                        DropdownMenuItem(value: s, child: Text(s.name)),
                    ],
                    onChanged: (s) {
                      setState(() {
                        _source = s;
                        _typeId = null;
                      });
                      _load(reset: true);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // 年份 Chip
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final y in _years) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: y,
                                  selected: y == '全部'
                                      ? _year.isEmpty
                                      : _year == y,
                                  onTap: () => _selectYear(y),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      IxSlidingIndicator(
                        count: _years.length,
                        index: _years.indexOf(
                          _year.isEmpty ? '全部' : _year,
                        ),
                        width: 280,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 排序
                PopupMenuButton<String>(
                  color: StarColors.surface,
                  tooltip: '排序',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: StarColors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_sortLabel,
                            style: const TextStyle(
                                fontSize: 12, color: StarColors.ink2)),
                        const Icon(Icons.expand_more,
                            size: 16, color: StarColors.ink3),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: '按更新', child: Text('按更新', style: TextStyle(fontSize: 12))),
                    PopupMenuItem(
                        value: '按评分', child: Text('按评分', style: TextStyle(fontSize: 12))),
                    PopupMenuItem(
                        value: '按年份', child: Text('按年份', style: TextStyle(fontSize: 12))),
                  ],
                  onSelected: (v) {
                    setState(() => _sortLabel = v);
                    // 源侧暂无排序参数，先记 UI 态（P1 接 caps.sort）
                  },
                ),
              ],
            ),
          ),
        ),
        // ── 结果计数 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Text(
            _items.isEmpty && !_loading
                ? '暂无结果 · 换个筛选或源试试'
                : '共 ${_items.length}${_hasMore ? '+' : ''} 部 · $_sortLabel'
                  '${_year.isNotEmpty ? ' · $_year' : ''}',
            style: const TextStyle(fontSize: 12, color: StarColors.ink3),
          ),
        ),
        Expanded(
          child: _items.isEmpty && !_loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_filter_outlined,
                          size: 40, color: StarColors.ink4),
                      const SizedBox(height: 10),
                      const Text('没有匹配的影片',
                          style: TextStyle(color: StarColors.ink3)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _year = '');
                          _load(reset: true);
                        },
                        child: const Text('清除筛选'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 0.7,
                    mainAxisExtent: 260,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _items.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= _items.length) {
                      return const IxSkeleton(height: 220, radius: 14);
                    }
                    final card = _items[i];
                    final src = _source;
                    return StarPoster(
                      title: card.title,
                      subtitle: card.remarks ?? card.year ?? '',
                      hueSeed: i,
                      imageUrl: card.posterUrl,
                      badgeText:
                          (card.score != null && card.score!.isNotEmpty)
                              ? card.score
                              : null,
                      onTap: src == null
                          ? null
                          : () => widget.onOpenDetail(src, card),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? StarColors.brand : StarColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : StarColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
