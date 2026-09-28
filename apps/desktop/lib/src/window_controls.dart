import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面窗口控制（最小化 / 最大化 / 关闭）。
class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _sync();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => _sync();
  @override
  void onWindowUnmaximize() => _sync();

  Future<void> _sync() async {
    final m = await windowManager.isMaximized();
    if (mounted) setState(() => _maximized = m);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          tooltip: '最小化',
          icon: Icons.remove,
          onTap: () => windowManager.minimize(),
        ),
        _Btn(
          tooltip: _maximized ? '还原' : '最大化',
          icon: _maximized ? Icons.filter_none : Icons.crop_square,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            _sync();
          },
        ),
        _Btn(
          tooltip: '关闭',
          icon: Icons.close,
          danger: true,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _Btn({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 36,
          child: Icon(icon,
              size: 16, color: danger ? const Color(0xFFFF6B6B) : Colors.white70),
        ),
      ),
    );
  }
}
