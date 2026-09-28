import 'dart:async';

import 'package:flutter/material.dart';

import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import '../widgets/focus_widgets.dart';


/// TV 聚合搜索页（docs/09 M2-1）：软键盘输入 + 结果焦点网格 + 多源角标。
class TvSearchPage extends StatefulWidget {
  final AppServices services;
  final void Function(SourceDef, WorkCard) onOpenDetail;

  const TvSearchPage({
    super.key,
    required this.services,
    required this.onOpenDetail,
  });

  @override
  State<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends State<TvSearchPage> {
  final _controller = TextEditingController();
  final _cards = <WorkCard>[];
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
    if (defs.isEmpty) return;
    final videoSources = widget.services.buildVideoSources(defs);
    _defsByKey
      ..clear()
      ..addEntries([for (final s in videoSources) MapEntry(s.def.key, s.def)]);
    setState(() {
      _cards.clear();
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
        case SearchSourceDone(:final items):
          _cards.addAll(items);
        case SearchSourceFailed():
          break;
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
    final groups = SearchEngine.mergeWorks(_cards);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      children: [
        Row(
          children: [
            SizedBox(
              width: 640,
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                style: const TextStyle(fontSize: 24, color: StarColors.ink),
                decoration: const InputDecoration(
                  hintText: '输入关键词，OK 键搜索',
                  isDense: true,
                  filled: true,
                  fillColor: StarColors.surface,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TvFocusChip(label: _running ? '搜索中…' : '搜索', isNavSelected: false, onSelect: _search),
            if (_running)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: StarColors.brand),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        if (groups.isEmpty && !_running)
          const Text('输入关键词开始聚合搜索',
              style: TextStyle(fontSize: 24, color: StarColors.ink4)),
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(group.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w500)),
                    ),
                    if (group.items.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text('多源 ${group.items.length}',
                            style: const TextStyle(
                                fontSize: 20, color: StarColors.brandHi)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 364,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: group.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 32),
                    itemBuilder: (_, i) {
                      final card = group.items[i];
                      final def = _defsByKey[card.sourceKey];
                      return TvFocusCard(
                        title: card.title,
                        subtitle: card.remarks ??
                            '${def?.name ?? card.sourceKey}'
                                '${card.year == null ? '' : ' · ${card.year}'}',
                        hueSeed: i,
                        imageUrl: card.posterUrl,
                        onTap: def == null
                            ? null
                            : () => widget.onOpenDetail(def, card),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
