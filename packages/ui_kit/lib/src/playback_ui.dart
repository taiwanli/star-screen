import 'dart:async';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

/// 连播倒计时（docs/09 M3-2）：默认 10s，可取消 / 立即播放。
class NextEpisodeBanner extends StatefulWidget {
  final String title;
  final Duration countdown;
  final VoidCallback onPlayNext;
  final VoidCallback onCancel;

  const NextEpisodeBanner({
    super.key,
    required this.title,
    required this.onPlayNext,
    required this.onCancel,
    this.countdown = const Duration(seconds: 10),
  });

  @override
  State<NextEpisodeBanner> createState() => _NextEpisodeBannerState();
}

class _NextEpisodeBannerState extends State<NextEpisodeBanner> {
  late int _left = widget.countdown.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        _timer?.cancel();
        widget.onPlayNext();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: StarColors.glassStrong,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.playlist_play, color: Color(0xFF4C9AFF), size: 22),
          const SizedBox(width: 10),
          Text(widget.title,
              style: const TextStyle(fontSize: 14, color: StarColors.ink)),
          const SizedBox(width: 16),
          Text('$_left s',
              style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 14,
                  color: StarColors.ink3)),
          const SizedBox(width: 16),
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('取消',
                style: TextStyle(fontSize: 13, color: StarColors.ink3)),
          ),
          const SizedBox(width: 4),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C9AFF)),
            onPressed: widget.onPlayNext,
            child: const Text('立即播放', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// 直播数字键缓冲：拼频道号，空闲 [debounce] 后提交（docs/09 M3-2）。
class ChannelNumberBuffer {
  ChannelNumberBuffer({this.debounce = const Duration(milliseconds: 900)});

  final Duration debounce;
  final StringBuffer _buf = StringBuffer();
  Timer? _timer;
  void Function(String digits)? onCommit;

  String get digits => _buf.toString();

  void press(String d, {required void Function(String) onCommitNow}) {
    onCommit = onCommitNow;
    if (_buf.length >= 4) _buf.clear();
    _buf.write(d);
    _timer?.cancel();
    _timer = Timer(debounce, () {
      final v = _buf.toString();
      _buf.clear();
      if (v.isNotEmpty) onCommitNow(v);
    });
  }

  void dispose() {
    _timer?.cancel();
    _buf.clear();
  }
}

/// 频道号浮层（输入过程中显示）。
class ChannelNumberOverlay extends StatelessWidget {
  final String digits;

  const ChannelNumberOverlay({super.key, required this.digits});

  @override
  Widget build(BuildContext context) {
    if (digits.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: StarColors.glassStrong,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        digits,
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontSize: 40,
          color: StarColors.ink,
          letterSpacing: 4,
        ),
      ),
    );
  }
}

/// 导入向导报告（docs/09 M3-6）：支持/不支持原因完整呈现。
class ImportReportView extends StatelessWidget {
  final int configs;
  final int sites;
  final int unsupported;
  final List<String> failedWarehouses;
  final List<ImportSourceLine> sources;
  final List<String> issues;

  const ImportReportView({
    super.key,
    required this.configs,
    required this.sites,
    required this.unsupported,
    this.failedWarehouses = const [],
    this.sources = const [],
    this.issues = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('导入完成：$configs 个配置 · $sites 个站点（不支持 $unsupported 个）',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: StarColors.ink)),
        if (failedWarehouses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('失效子仓：${failedWarehouses.join('、')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFFFB340))),
        ],
        if (sources.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sources.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0x22FFFFFF)),
              itemBuilder: (_, i) {
                final s = sources[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        s.supported ? Icons.check_circle_outline : Icons.block,
                        size: 16,
                        color: s.supported
                            ? const Color(0xFF3DDC97)
                            : const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: StarColors.ink)),
                            if (!s.supported && s.reason != null)
                              Text(s.reason!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: StarColors.ink3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final issue in issues.take(8))
            Text('· $issue',
                style:
                    const TextStyle(fontSize: 11, color: StarColors.ink3)),
        ],
      ],
    );
  }
}

/// 单条源报告行。
class ImportSourceLine {
  final String name;
  final bool supported;
  final String? reason;

  const ImportSourceLine({
    required this.name,
    required this.supported,
    this.reason,
  });
}

/// 导入向导结果（docs/09 M3-6）。
class ImportWizardResult {
  final int configs;
  final int sites;
  final int unsupported;
  final List<String> failedWarehouses;
  final List<ImportSourceLine> sources;
  final List<String> issues;

  const ImportWizardResult({
    required this.configs,
    required this.sites,
    required this.unsupported,
    this.failedWarehouses = const [],
    this.sources = const [],
    this.issues = const [],
  });
}

/// TVBox 配置导入向导（三端共用外壳）：输入 → 导入中 → 报告（支持/不支持原因）。
class ImportWizardDialog extends StatefulWidget {
  final Future<ImportWizardResult> Function(String ref) onImport;
  final String title;

  const ImportWizardDialog({
    super.key,
    required this.onImport,
    this.title = '导入订阅',
  });

  static Future<ImportWizardResult?> show(
    BuildContext context, {
    required Future<ImportWizardResult> Function(String ref) onImport,
    String title = '导入订阅',
  }) {
    return showDialog<ImportWizardResult>(
      context: context,
      builder: (_) => ImportWizardDialog(onImport: onImport, title: title),
    );
  }

  @override
  State<ImportWizardDialog> createState() => _ImportWizardDialogState();
}

class _ImportWizardDialogState extends State<ImportWizardDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;
  ImportWizardResult? _result;

  /// 文件管理器选文件 → 填入路径。
  Future<void> _pickFile() async {
    setState(() {
      _error = null;
    });
    try {
      final file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(
            label: '订阅/StarRule',
            extensions: <String>['json', 'star', 'jsonc', 'txt'],
          ),
        ],
      );
      if (file != null && file.path.isNotEmpty) {
        setState(() {
          _ctrl.text = file.path;
        });
      }
    } on Object catch (e) {
      setState(() => _error = '打开文件选择器失败：$e');
    }
  }

  /// 文件管理器选文件夹 → 批量导入目录内配置。
  Future<void> _pickFolder() async {
    setState(() {
      _error = null;
    });
    try {
      final dir = await getDirectoryPath();
      if (dir != null && dir.isNotEmpty) {
        setState(() {
          _ctrl.text = dir;
        });
      }
    } on Object catch (e) {
      setState(() => _error = '打开目录选择器失败：$e');
    }
  }

  Future<void> _run() async {
    final ref = _ctrl.text.trim();
    if (ref.isEmpty) {
      setState(() => _error = '请输入配置地址或本地路径');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await widget.onImport(ref);
      setState(() => _result = r);
    } on Object catch (e) {
      setState(() => _error = '导入失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StarColors.surface,
      title: Text(widget.title,
          style: const TextStyle(fontSize: 16, color: StarColors.ink)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('粘贴 TVBox 配置地址 / 本地路径 / 配置 JSON 原文：',
                style: TextStyle(fontSize: 12, color: StarColors.ink3)),
            const SizedBox(height: 10),
            TextField(
              controller: _ctrl,
              autofocus: true,
              enabled: !_busy,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: StarColors.ink),
              decoration: InputDecoration(
                hintText: 'https://… 或 C:/path/box.json 或直接粘贴 JSON',
                hintStyle:
                    const TextStyle(fontSize: 13, color: StarColors.ink4),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                errorText: _error,
                errorStyle: const TextStyle(fontSize: 11),
              ),
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickFile,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('选择文件…'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickFolder,
                  icon: const Icon(Icons.drive_folder_upload, size: 16),
                  label: const Text('选择文件夹…'),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(color: Color(0xFF4C9AFF)),
              const SizedBox(height: 8),
              const Text('正在获取并解析配置…',
                  style: TextStyle(fontSize: 12, color: StarColors.ink3)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              ImportReportView(
                configs: _result!.configs,
                sites: _result!.sites,
                unsupported: _result!.unsupported,
                failedWarehouses: _result!.failedWarehouses,
                sources: _result!.sources,
                issues: _result!.issues,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _result),
          child: Text(_result == null ? '取消' : '完成',
              style: const TextStyle(fontSize: 13)),
        ),
        if (_result == null)
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4C9AFF)),
            onPressed: _busy ? null : _run,
            child: Text(_busy ? '导入中…' : '开始导入',
                style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}