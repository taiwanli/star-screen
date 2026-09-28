import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV 焦点引擎（docs/03 §7.3 / docs/07 §5.3）：
/// - F2 几何最近邻 + 行列锚定（同排优先，杜绝焦点跳飞）；
/// - F3 焦点记忆（按 pageKey 记住最后落点，返回/切页恢复）；
/// - F4 永不丢失（primaryFocus 丢失时立刻恢复到记忆点/首焦点）；
/// - F8 响应 ≤100ms（内存几何计算，无异步）。
class TvFocusMemory {
  TvFocusMemory._();

  static final Map<String, String> _last = {};

  static String? lastOf(String pageKey) => _last[pageKey];

  static void remember(String pageKey, String id) {
    _last[pageKey] = id;
    // docs/13 D3：FIFO 上限，长会话不无限累积
    if (_last.length > 64) _last.remove(_last.keys.first);
  }

  /// 测试用：清空记忆。
  static void debugClear() => _last.clear();
}

/// 几何方向遍历：在当前节点的指定方向找最近可聚焦节点。
class GeometricTvFocusPolicy extends FocusTraversalPolicy
    with DirectionalFocusTraversalPolicyMixin {
  @override
  Iterable<FocusNode> sortDescendants(
      Iterable<FocusNode> descendants, FocusNode currentNode) {
    final list = descendants.toList()
      ..sort((a, b) {
        final ra = _rectOf(a);
        final rb = _rectOf(b);
        if (ra == null || rb == null) return 0;
        final dy = ra.top.compareTo(rb.top);
        if (dy.abs() > 8) return dy; // 行优先
        return ra.left.compareTo(rb.left);
      });
    return list;
  }

  @override
  FocusNode? findFirstFocusInDirection(
      FocusNode currentNode, TraversalDirection direction) {
    final from = _rectOf(currentNode);
    if (from == null) return null;
    FocusNode? best;
    var bestScore = double.infinity;
    for (final node in _candidates(currentNode)) {
      if (node == currentNode || !node.canRequestFocus) continue;
      final rect = _rectOf(node);
      if (rect == null) continue;
      if (!_inDirection(from, rect, direction)) continue;
      final score = scoreCandidate(from, rect, direction);
      if (score < bestScore) {
        bestScore = score;
        best = node;
      }
    }
    return best;
  }

  static Iterable<FocusNode> _candidates(FocusNode current) {
    final scope = current.enclosingScope;
    return scope?.descendants ?? current.descendants;
  }

  /// 候选评分：主轴距离 + 2×横向偏移（同排优先，docs/03 §7.3 行列锚定）。
  static double scoreCandidate(
      Rect from, Rect to, TraversalDirection direction) {
    return switch (direction) {
      TraversalDirection.left =>
        (from.left - to.right).clamp(0, double.infinity) + (to.center.dy - from.center.dy).abs() * 2,
      TraversalDirection.right =>
        (to.left - from.right).clamp(0, double.infinity) + (to.center.dy - from.center.dy).abs() * 2,
      TraversalDirection.up =>
        (from.top - to.bottom).clamp(0, double.infinity) + (to.center.dx - from.center.dx).abs() * 2,
      TraversalDirection.down =>
        (to.top - from.bottom).clamp(0, double.infinity) + (to.center.dx - from.center.dx).abs() * 2,
    };
  }

  static bool _inDirection(Rect from, Rect to, TraversalDirection direction) {
    return switch (direction) {
      TraversalDirection.left => to.center.dx < from.center.dx,
      TraversalDirection.right => to.center.dx > from.center.dx,
      TraversalDirection.up => to.center.dy < from.center.dy,
      TraversalDirection.down => to.center.dy > from.center.dy,
    };
  }

  static Rect? _rectOf(FocusNode node) {
    final ctx = node.context;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }
}

/// 页面级焦点作用域：记忆 + 永不丢失（F3/F4）。
class TvFocusScope extends StatefulWidget {
  final String pageKey;
  final Widget child;

  /// 可聚焦节点 id → FocusNode（由子树通过 [TvFocusScope.maybeOf] 注册）。
  const TvFocusScope({super.key, required this.pageKey, required this.child});

  static TvFocusScopeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<TvFocusScopeState>();

  @override
  State<TvFocusScope> createState() => TvFocusScopeState();
}

class TvFocusScopeState extends State<TvFocusScope> {
  final Map<String, FocusNode> _nodes = {};
  String? _currentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// 注册可记忆的焦点节点（id 稳定，用于 F3）。
  FocusNode register(String id, {bool autofocus = false}) {
    return _nodes.putIfAbsent(id, () {
      final n = FocusNode(debugLabel: '${widget.pageKey}/$id');
      if (autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && n.canRequestFocus) {
            n.requestFocus();
          }
        });
      }
      return n;
    });
  }

  void _onFocusChanged() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) {
      // F4：焦点丢失 → 恢复记忆点
      _restore();
      return;
    }
    final label = primary.debugLabel ?? '';
    if (label.startsWith('${widget.pageKey}/')) {
      final id = label.substring(widget.pageKey.length + 1);
      _currentId = id;
      TvFocusMemory.remember(widget.pageKey, id);
    }
  }

  void _restore() {
    if (!mounted || _nodes.isEmpty) return;
    final saved = TvFocusMemory.lastOf(widget.pageKey);
    var target = saved != null ? _nodes[saved] : null;
    target ??= _nodes.values.cast<FocusNode?>().firstWhere(
          (n) => n!.canRequestFocus,
          orElse: () => _nodes.values.first,
        );
    if (target != null && target.canRequestFocus) {
      target.requestFocus();
    }
  }

  /// 当前焦点 id（F3 记忆）。
  String? get currentId => _currentId;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: GeometricTvFocusPolicy(),
      child: widget.child,
    );
  }
}

/// 五向键 → [TraversalDirection]。
TraversalDirection? tvDirectionOf(KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
  return switch (event.logicalKey) {
    LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
    LogicalKeyboardKey.arrowRight => TraversalDirection.right,
    LogicalKeyboardKey.arrowUp => TraversalDirection.up,
    LogicalKeyboardKey.arrowDown => TraversalDirection.down,
    _ => null,
  };
}

/// 焦点组件包装：可记忆 id + 三重信号容器（缩放/描边/阴影，F5）。
class TvFocusBox extends StatelessWidget {
  final String id;
  final Widget child;
  final VoidCallback? onSelect;
  final double borderRadius;
  final bool showGlow;

  const TvFocusBox({
    super.key,
    required this.id,
    required this.child,
    this.onSelect,
    this.borderRadius = 12,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final scope = TvFocusScope.maybeOf(context);
    final node = scope?.register(id);
    final content = Builder(
      builder: (ctx) {
        final hasFocus = Focus.of(ctx).hasFocus;
        return AnimatedScale(
          scale: hasFocus ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: hasFocus ? const Color(0xFF4C9AFF) : Colors.transparent,
                width: 3,
              ),
              boxShadow: hasFocus && showGlow
                  ? const [
                      BoxShadow(blurRadius: 40, color: Color(0x8C000000)),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
    );
    if (node == null) {
      return Focus(
        onKeyEvent: (_, e) => _select(e),
        child: content,
      );
    }
    return Focus(
      focusNode: node,
      onKeyEvent: (_, e) => _select(e),
      child: content,
    );
  }

  KeyEventResult _select(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) &&
        onSelect != null) {
      onSelect!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
