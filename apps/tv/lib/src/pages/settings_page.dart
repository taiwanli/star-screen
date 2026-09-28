import 'package:flutter/material.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_ui_kit/star_ui_kit.dart';

import '../app_services.dart';
import '../widgets/focus_widgets.dart';

/// TV 设置：全部选择式（禁长表单，docs/07 §4）——源管理 + 播放内核展示。
class SettingsPage extends StatefulWidget {
  final AppServices services;
  final VoidCallback onChanged;

  const SettingsPage({
    super.key,
    required this.services,
    required this.onChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<SourceDef>> _sources;

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
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('设置',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
        ),
        // 播放内核（v0.1 统一 libmpv；v0.2 回退链开放 EXO/IJK）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 280,
                    child: Text('播放内核',
                        style: TextStyle(fontSize: 26, color: StarColors.ink)),
                  ),
                  Text('libmpv（三端统一 · v0.2 开放 EXO/IJK 切换）',
                      style:
                          const TextStyle(fontSize: 22, color: StarColors.ink3)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 280,
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('源管理',
                          style:
                              TextStyle(fontSize: 26, color: StarColors.ink)),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<SourceDef>>(
                      future: _sources,
                      builder: (context, snap) {
                        final sources = snap.data ?? const <SourceDef>[];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final def in sources)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      def.kind.isSupported
                                          ? Icons.storage_outlined
                                          : Icons.block_outlined,
                                      size: 28,
                                      color: def.kind.isSupported
                                          ? StarColors.brandHi
                                          : StarColors.ink4,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            def.name,
                                            style: TextStyle(
                                                fontSize: 22,
                                                color: def.kind.isSupported
                                                    ? StarColors.ink2
                                                    : StarColors.ink4),
                                          ),
                                          Text(
                                            [
                                              if ((def.groupId ?? '').isNotEmpty)
                                                def.groupId!,
                                              _kindLabel(def.kind),
                                              if (!def.kind.isSupported)
                                                def.unsupportedReason ??
                                                    '需原生蜘蛛 jar',
                                            ].join(' · '),
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: def.kind.isSupported
                                                    ? StarColors.ink4
                                                    : StarColors.bad),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: def.enabled,
                                      onChanged: def.kind.isSupported
                                          ? (v) async {
                                              await widget.services.registry
                                                  .setEnabled(def.key, v);
                                              setState(_reload);
                                            }
                                          : null,
                                      activeThumbColor: StarColors.brandHi,
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TvFocusChip(
                                label: '+ 添加内容源',
                                isNavSelected: false,
                                onSelect: _addSource,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('本机数据 · 数据不出设备',
                  style: TextStyle(fontSize: 20, color: StarColors.ink4)),
            ],
          ),
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
    widget.onChanged();
  }
}
