import 'dart:async';
import 'package:flutter/material.dart';
import 'colors.dart';

/// 字幕样式参数（与 packages/player 的 SubtitleStyle 同构，UI 侧独立避免反向依赖）。
class SubtitleUiStyle {
  final double fontSize;
  final double backgroundOpacity;
  final int delayMs;

  const SubtitleUiStyle({
    this.fontSize = 24,
    this.backgroundOpacity = 0.67,
    this.delayMs = 0,
  });

  /// TV 默认：≥32px + 半透明背景板（docs/07 §4.4）。
  static const tv = SubtitleUiStyle(fontSize: 32, backgroundOpacity: 0.72);

  SubtitleUiStyle copyWith({
    double? fontSize,
    double? backgroundOpacity,
    int? delayMs,
  }) =>
      SubtitleUiStyle(
        fontSize: fontSize ?? this.fontSize,
        backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
        delayMs: delayMs ?? this.delayMs,
      );
}

/// 字幕渲染层：延迟缓冲 + 样式（字号/底板透明度）。
/// 关闭 media_kit 自带 SubtitleView 后叠在 Video 之上，支持延迟（docs/09 M3-3）。
/// [textStream] 为当前显示的字幕行（media_kit `stream.subtitle`）。
class StarSubtitleOverlay extends StatefulWidget {
  final Stream<List<String>> textStream;
  final SubtitleUiStyle style;

  const StarSubtitleOverlay({
    super.key,
    required this.textStream,
    required this.style,
  });

  @override
  State<StarSubtitleOverlay> createState() => _StarSubtitleOverlayState();
}

class _StarSubtitleOverlayState extends State<StarSubtitleOverlay> {
  String _visible = '';
  String _pending = '';
  Timer? _timer;
  StreamSubscription<List<String>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.textStream.listen(_onLines);
  }

  @override
  void didUpdateWidget(covariant StarSubtitleOverlay old) {
    super.didUpdateWidget(old);
    if (!identical(old.textStream, widget.textStream)) {
      _sub?.cancel();
      _sub = widget.textStream.listen(_onLines);
    }
    if (old.style.delayMs != widget.style.delayMs && _pending.isNotEmpty) {
      _schedule(_pending);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _onLines(List<String> lines) {
    _onText(lines.join('\n'));
  }

  void _onText(String text) {
    _pending = text;
    if (widget.style.delayMs <= 0) {
      _timer?.cancel();
      setState(() => _visible = text);
      return;
    }
    _schedule(text);
  }

  void _schedule(String text) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: widget.style.delayMs), () {
      if (mounted) setState(() => _visible = text);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_visible.isEmpty) return const SizedBox.expand();
    final opacity = widget.style.backgroundOpacity.clamp(0.0, 1.0);
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, opacity),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _visible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.style.fontSize,
                  height: 1.35,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 轨道条目（内封 / 外挂）。
class SubtitleTrackOption {
  final String id;
  final String title;
  final bool isExternal;
  final bool selected;

  const SubtitleTrackOption({
    required this.id,
    required this.title,
    this.isExternal = false,
    this.selected = false,
  });
}

/// 字幕面板：轨道选择 + 外挂加载 + 样式（大小/底板/延迟）。
/// 桌面弹出菜单、手机底部面板、TV OSD 共用逻辑，由宿主决定外壳。
class SubtitlePanel extends StatefulWidget {
  final List<SubtitleTrackOption> tracks;
  final SubtitleUiStyle style;
  final ValueChanged<String?> onSelectTrack; // null = 关闭字幕
  final ValueChanged<SubtitleUiStyle> onStyleChanged;
  final Future<void> Function(String uri) onLoadExternal;
  final double width;

  const SubtitlePanel({
    super.key,
    required this.tracks,
    required this.style,
    required this.onSelectTrack,
    required this.onStyleChanged,
    required this.onLoadExternal,
    this.width = 320,
  });

  @override
  State<SubtitlePanel> createState() => _SubtitlePanelState();
}

class _SubtitlePanelState extends State<SubtitlePanel> {
  late SubtitleUiStyle _style = widget.style;

  void _update(SubtitleUiStyle s) {
    setState(() => _style = s);
    widget.onStyleChanged(s);
  }

  @override
  void didUpdateWidget(covariant SubtitlePanel old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _style = widget.style;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Material(
        color: StarColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('字幕',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: StarColors.ink)),
              const SizedBox(height: 8),
              _TrackList(tracks: widget.tracks, onSelect: widget.onSelectTrack),
              const Divider(height: 20, color: Color(0x22FFFFFF)),
              _StyleSliders(style: _style, onChanged: _update),
              const SizedBox(height: 10),
              _ExternalLoader(onLoad: widget.onLoadExternal),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  final List<SubtitleTrackOption> tracks;
  final ValueChanged<String?> onSelect;

  const _TrackList({required this.tracks, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('关闭字幕',
              style: TextStyle(fontSize: 13, color: StarColors.ink)),
          trailing: tracks.every((t) => !t.selected)
              ? const Icon(Icons.check, size: 16, color: Color(0xFF4C9AFF))
              : null,
          onTap: () => onSelect(null),
        ),
        for (final t in tracks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              t.title,
              style: const TextStyle(fontSize: 13, color: StarColors.ink),
            ),
            subtitle: t.isExternal
                ? const Text('外挂',
                    style:
                        TextStyle(fontSize: 11, color: StarColors.ink3))
                : null,
            trailing: t.selected
                ? const Icon(Icons.check, size: 16, color: Color(0xFF4C9AFF))
                : null,
            onTap: () => onSelect(t.id),
          ),
        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('无字幕轨',
                style: TextStyle(fontSize: 12, color: StarColors.ink3)),
          ),
      ],
    );
  }
}

class _StyleSliders extends StatelessWidget {
  final SubtitleUiStyle style;
  final ValueChanged<SubtitleUiStyle> onChanged;

  const _StyleSliders({required this.style, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sliderLabel('字号', '${style.fontSize.round()}'),
        Slider(
          value: style.fontSize.clamp(14, 48),
          min: 14,
          max: 48,
          divisions: 17,
          onChanged: (v) => onChanged(style.copyWith(fontSize: v)),
        ),
        _sliderLabel('底板', '${(style.backgroundOpacity * 100).round()}%'),
        Slider(
          value: style.backgroundOpacity.clamp(0, 1),
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (v) => onChanged(style.copyWith(backgroundOpacity: v)),
        ),
        _sliderLabel('延迟', '${style.delayMs} ms'),
        Slider(
          value: style.delayMs.clamp(0, 5000).toDouble(),
          min: 0,
          max: 5000,
          divisions: 20,
          onChanged: (v) => onChanged(style.copyWith(delayMs: v.round())),
        ),
      ],
    );
  }

  Widget _sliderLabel(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: StarColors.ink3)),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 12, color: StarColors.ink)),
          ],
        ),
      );
}

class _ExternalLoader extends StatefulWidget {
  final Future<void> Function(String uri) onLoad;

  const _ExternalLoader({required this.onLoad});

  @override
  State<_ExternalLoader> createState() => _ExternalLoaderState();
}

class _ExternalLoaderState extends State<_ExternalLoader> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uri = _ctrl.text.trim();
    if (uri.isEmpty) {
      setState(() => _error = '请输入字幕路径或 URL');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onLoad(uri);
      _ctrl.clear();
    } on Object catch (e) {
      setState(() => _error = '加载失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('外挂字幕（srt / ass / vtt）',
            style: TextStyle(fontSize: 12, color: StarColors.ink3)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(fontSize: 12, color: StarColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '本地路径或 https://…',
                  hintStyle:
                      const TextStyle(fontSize: 12, color: StarColors.ink4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  errorText: _error,
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('加载', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}