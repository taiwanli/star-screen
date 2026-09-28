import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';


/// 聚合搜索页（docs/09 M2-1）：并发搜多源、渐进渲染、同片归并为多源卡。
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

class _SearchResultVm {
  final List<WorkCard> cards = [];
  final Map<String, String> failed = {}; // sourceKey → reason
  final Set<String> doneSources = {};
  bool running = false;
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  _SearchResultVm _vm = _SearchResultVm();
  StreamSubscription<SearchUpdate>? _sub;
  Timer? _uiTimer;
  Map<String, SourceDef> _defsByKey = {};
  late Future<List<String>> _historyF;

  @override
  void initState() {
    super.initState();
    _historyF = _history();
  }

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
    await _remember(keyword);
    _historyF = _history();
    setState(() {});
    final defs = await widget.services.enabledSources();
    if (!mounted) return;
    if (defs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: StarColors.raised,
          content: Text('还没有内容源，请先在「源管理」添加',
              style: TextStyle(color: StarColors.ink)),
        ));
      }
      return;
    }
    final videoSources = widget.services.buildVideoSources(defs);
    _defsByKey = {for (final s in videoSources) s.def.key: s.def};

    final vm = _SearchResultVm()..running = true;
    setState(() => _vm = vm);
    await _sub?.cancel();
    _uiTimer?.cancel();
    final cooling = {
      for (final s in videoSources)
        if (widget.services.healthMonitor.isCooling(s.def.key)) s.def.key,
    };
    final engine = SearchEngine(sources: videoSources, skipKeys: cooling);
    _sub = engine.searchAll(keyword).listen((update) {
      switch (update) {
        case SearchSourceDone(:final sourceKey, :final items):
          vm.cards.addAll(items);
          vm.doneSources.add(sourceKey);
          vm.failed.remove(sourceKey);
        case SearchSourceFailed(:final sourceKey, :final sourceName, :final reason):
          vm.failed[sourceKey] = '$sourceName：$reason';
        case SearchCompleted():
          vm.running = false;
      }
      if (mounted) _scheduleUi();
    });
  }

  Future<void> _remember(String kw) async {
    final raw = await widget.services.kv.getString('searchHistory');
    final list = raw == null
        ? <String>[]
        : (jsonDecode(raw) as List<dynamic>).cast<String>();
    list.remove(kw);
    list.insert(0, kw);
    if (list.length > 20) list.removeRange(20, list.length);
    await widget.services.kv.setString('searchHistory', jsonEncode(list));
  }

  Future<List<String>> _history() async {
    final raw = await widget.services.kv.getString('searchHistory');
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }

  void _scheduleUi() {
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 480,
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '聚合搜索已启用的内容源…',
                  isDense: true,
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: StarColors.ink4),
                  filled: true,
                  fillColor: StarColors.page,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: StarColors.line),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: StarColors.brand),
              onPressed: _search,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('搜索'),
            ),
            const SizedBox(width: 16),
            if (vm.running)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: StarColors.brand),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
          future: _historyF,
          builder: (context, snap) {
            final items = snap.data ?? const <String>[];
            if (items.isEmpty || vm.cards.isNotEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final h in items.take(10))
                  ActionChip(
                    label: Text(h, style: const TextStyle(fontSize: 11.5)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: StarColors.surface,
                    side: const BorderSide(color: StarColors.line),
                    onPressed: () {
                      _controller.text = h;
                      _search();
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        if (vm.failed.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final entry in vm.failed.entries)
                Chip(
                  label: Text('⚠ ${entry.value}',
                      style: const TextStyle(fontSize: 11.5)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: StarColors.surface,
                  side: const BorderSide(color: StarColors.line),
                ),
            ],
          ),
        Expanded(child: _results(vm)),
      ],
    );
  }

  Widget _results(_SearchResultVm vm) {
    if (vm.cards.isEmpty && !vm.running) {
      return const Center(
        child: Text('输入关键词开始聚合搜索 —— 已启用源将并发检索，先到先渲染',
            style: TextStyle(fontSize: 13, color: StarColors.ink4)),
      );
    }
    final scores = {
        for (final e in widget.services.healthMonitor.exportState().entries)
          e.key: HealthMonitor.score(
              widget.services.healthMonitor.healthOf(e.key)),
      };
      final groups = SearchEngine.mergeWorks(vm.cards, healthScore: scores);
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
        final sourceNames =
            group.items.map((c) => _defsByKey[c.sourceKey]?.name ?? c.sourceKey);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  : StarNetworkImage(url: 
                  first.posterUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                                        fallback: const ColoredBox(
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
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w500)),
              ),
              if (group.items.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SourceBadge(label: '多源 ${group.items.length}'),
                ),
            ],
          ),
          subtitle: Text(
            '${[first.year, first.genre, first.remarks].whereType<String>().join(' · ')}'
            '${sourceNames.isEmpty ? '' : ' ｜ ${sourceNames.join(' / ')}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: StarColors.ink3),
          ),
          onTap: def == null
              ? null
              : () => widget.onOpenDetail(def, first),
        );
      },
    );
  }
}

class SourceBadge extends StatelessWidget {
  final String label;
  const SourceBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StarColors.brandSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: StarColors.brandHi)),
      ),
    );
  }
}
