import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';

/// 手机分类浏览（docs/02 §4.2）。
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
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  final List<WorkCard> _items = [];
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _load();
      }
    });
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
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DropdownButton<SourceDef>(
                value: _source,
                dropdownColor: StarColors.surface,
                items: [
                  for (final s in _sources)
                    DropdownMenuItem(value: s, child: Text(s.name)),
                ],
                onChanged: (s) {
                  setState(() => _source = s);
                  _load(reset: true);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _items.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= _items.length) {
                return const Center(
                    child: CircularProgressIndicator(color: StarColors.brand));
              }
              final card = _items[i];
              final src = _source;
              return StarPoster(
                title: card.title,
                subtitle: card.remarks ?? '',
                hueSeed: i,
                imageUrl: card.posterUrl,
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
