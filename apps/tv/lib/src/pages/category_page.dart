import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import '../widgets/focus_widgets.dart';

/// TV 分类浏览（docs/02 §4.2）。
class TvCategoryPage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;

  const TvCategoryPage({
    super.key,
    required this.services,
    required this.onOpenDetail,
  });

  @override
  State<TvCategoryPage> createState() => _TvCategoryPageState();
}

class _TvCategoryPageState extends State<TvCategoryPage> {
  SourceDef? _source;
  List<SourceDef> _sources = const [];
  final List<WorkCard> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sources = await widget.services.enabledSources();
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _source = sources.where((s) => s.kind.hasAdapter).firstOrNull ?? sources.firstOrNull;
    });
    await _load(reset: true);
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
      final result = await widget.services
          .sourceFor(source)
          .category(CategoryQuery(page: _page));
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        if (_hasMore) _page++;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in _sources)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TvFocusChip(
                    label: s.name,
                    focusId: 'cat-src-${s.key}',
                    isNavSelected: s.key == _source?.key,
                    onSelect: () {
                      setState(() => _source = s);
                      _load(reset: true);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1.35,
            ),
            itemCount: _items.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= _items.length) {
                return const Center(
                    child: CircularProgressIndicator(color: StarColors.brand));
              }
              final card = _items[i];
              final src = _source;
              return TvFocusCard(
                title: card.title,
                subtitle: card.remarks ?? '',
                hueSeed: i,
                imageUrl: card.posterUrl,
                focusId: 'cat-$i',
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
