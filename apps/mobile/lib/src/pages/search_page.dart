import 'dart:async';

import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';


/// 手机聚合搜索页（docs/09 M2-1）：并发搜多源、同片归并、失败源提示。
class SearchPage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;

  const SearchPage({
    super.key,
    required this.services,
    required this.onOpenDetail,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _cards = <WorkCard>[];
  final _failed = <String, String>{};
  final _defsByKey = <String, SourceDef>{};
  StreamSubscription<SearchUpdate>? _sub;
  Timer? _uiTimer;
  bool _running = false;

  @override
  void dispose() {
    _sub?.cancel();
    _uiTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;
    final defs = await widget.services.enabledSources();
    if (!mounted) return;
    if (defs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: StarColors.raised,
          content: Text('还没有内容源，请先在「我的 → 源管理」添加',
              style: TextStyle(color: StarColors.ink)),
        ));
      }
      return;
    }
    final videoSources = widget.services.buildVideoSources(defs);
    _defsByKey
      ..clear()
      ..addEntries([for (final s in videoSources) MapEntry(s.def.key, s.def)]);
    setState(() {
      _cards.clear();
      _failed.clear();
      _running = true;
    });
    await _sub?.cancel();
    _uiTimer?.cancel();
    final cooling = {
      for (final s in videoSources)
        if (widget.services.healthMonitor.isCooling(s.def.key)) s.def.key,
    };
    _sub = SearchEngine(sources: videoSources, skipKeys: cooling)
        .searchAll(keyword)
        .listen((update) {
      switch (update) {
        case SearchSourceDone(:final sourceKey, :final items):
          _cards.addAll(items);
          _failed.remove(sourceKey);
        case SearchSourceFailed(:final sourceKey, :final sourceName, :final reason):
          _failed[sourceKey] = '$sourceName：$reason';
        case SearchCompleted():
          _running = false;
      }
      if (mounted) _scheduleUi();
    });
  }

  void _scheduleUi() {
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '聚合搜索已启用的内容源…',
              isDense: true,
              prefixIcon:
                  const Icon(Icons.search, color: StarColors.ink4),
              suffixIcon: TextButton(
                onPressed: _search,
                child: const Text('搜索',
                    style: TextStyle(color: StarColors.brandHi)),
              ),
              filled: true,
              fillColor: StarColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: StarColors.line),
              ),
            ),
          ),
        ),
        if (_failed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '⚠ ${_failed.values.join(" ｜ ")}',
                style: const TextStyle(fontSize: 11.5, color: StarColors.warn),
              ),
            ),
          ),
        Expanded(child: _results()),
      ],
    );
  }

  Widget _results() {
    if (_cards.isEmpty && !_running) {
      return const SizedBox.shrink();
    }
    final groups = SearchEngine.mergeWorks(_cards);
    if (groups.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: StarColors.brand));
    }
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final group = groups[i];
        final first = group.items.first;
        final def = _defsByKey[first.sourceKey];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 78,
              child: first.posterUrl == null
                  ? const ColoredBox(
                      color: StarColors.raised,
                      child: Icon(Icons.movie_outlined,
                          size: 20, color: StarColors.ink4))
                  : Image.network(
                  first.posterUrl!,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent': 'Mozilla/5.0',
                  },
                  cacheWidth: 480,
                  filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const ColoredBox(
                          color: StarColors.raised,
                          child: Icon(Icons.movie_outlined,
                              size: 20, color: StarColors.ink4))),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15)),
              ),
              if (group.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: StarColors.brandSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      child: Text('多源 ${group.items.length}',
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: StarColors.brandHi)),
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            [first.year, first.genre, first.remarks]
                .whereType<String>()
                .join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: StarColors.ink3),
          ),
          onTap: def == null ? null : () => widget.onOpenDetail(def, first),
        );
      },
    );
  }
}
