import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_viewport.dart';

void main() {
  testWidgets(
    'LiveCartelaViewport resets scrollIdleListenable to true if unmounted mid-scroll (BUG-12)',
    (tester) async {
      final scrollIdle = ValueNotifier<bool>(true);
      addTearDown(scrollIdle.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveCartelaViewport(
              scrollIdleListenable: scrollIdle,
              onScrollStart: () {},
              onScrollEnd: () {},
              padding: EdgeInsets.zero,
              buildCartelaSliver: (_) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      SizedBox(height: 80, child: Text('Item $index')),
                  childCount: 50,
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      expect(scrollIdle.value, isFalse);

      // Unmount LiveCartelaViewport while gesture is still active (mid-scroll).
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );

      expect(scrollIdle.value, isTrue);
      await gesture.up();
    },
  );
}
