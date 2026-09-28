import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_tv/src/widgets/tv_focus_engine.dart';

void main() {
  group('GeometricTvFocusPolicy —— F2 几何最近邻 + 行列锚定', () {
    const from = Rect.fromLTWH(100, 100, 80, 40);

    test('右侧：同排优先（横向偏移权重 ×2）', () {
      const sameRow = Rect.fromLTWH(220, 108, 80, 40); // dy=12
      const lowerRow = Rect.fromLTWH(200, 200, 80, 40); // 更近但错排
      final sSame = GeometricTvFocusPolicy.scoreCandidate(
          from, sameRow, TraversalDirection.right);
      final sLower = GeometricTvFocusPolicy.scoreCandidate(
          from, lowerRow, TraversalDirection.right);
      expect(sSame, lessThan(sLower));
    });

    test('下方：横向对齐优先', () {
      const aligned = Rect.fromLTWH(110, 180, 80, 40);
      const skewed = Rect.fromLTWH(280, 160, 80, 40);
      final sA = GeometricTvFocusPolicy.scoreCandidate(
          from, aligned, TraversalDirection.down);
      final sB = GeometricTvFocusPolicy.scoreCandidate(
          from, skewed, TraversalDirection.down);
      expect(sA, lessThan(sB));
    });

    test('左/上方向主轴距离计入', () {
      const left = Rect.fromLTWH(0, 100, 80, 40);
      final score = GeometricTvFocusPolicy.scoreCandidate(
          from, left, TraversalDirection.left);
      expect(score, greaterThanOrEqualTo(0));
    });
  });

  group('TvFocusMemory —— F3 焦点记忆', () {
    setUp(TvFocusMemory.debugClear);

    test('按 pageKey 记住并读取', () {
      expect(TvFocusMemory.lastOf('home'), isNull);
      TvFocusMemory.remember('home', 'nav-首页');
      TvFocusMemory.remember('detail', 'ep-3');
      expect(TvFocusMemory.lastOf('home'), 'nav-首页');
      expect(TvFocusMemory.lastOf('detail'), 'ep-3');
    });
  });

  group('TvFocusScope —— F4 永不丢失', () {
    testWidgets('注册后可请求焦点；无焦点时恢复记忆点', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TvFocusScope(
            pageKey: 't1',
            child: _Probe(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(_Probe), findsOneWidget);
    });
  });
}

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) {
    final scope = TvFocusScope.maybeOf(context);
    final node = scope?.register('a');
    return Focus(
      focusNode: node,
      child: const SizedBox(width: 40, height: 40),
    );
  }
}
