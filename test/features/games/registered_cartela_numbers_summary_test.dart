import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_number_badge.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart';

final _now = DateTime.utc(2026, 11, 6);

GameCartelaModel _cartela(
  int number, {
  GameCartelaStatus status = GameCartelaStatus.registered,
}) {
  return GameCartelaModel(
    id: 'gc-$number',
    gameId: 'session-1',
    userId: 'user-1',
    cartelaId: 'cartela-$number',
    status: status,
    isWinner: false,
    blockedAt: status == GameCartelaStatus.blocked ? _now : null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(id: 'cartela-$number', number: number, createdAt: _now),
  );
}

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('100 cartelas fit a bounded panel and scroll (no overflow)', (
    tester,
  ) async {
    final cartelas = [for (var i = 1; i <= 100; i++) _cartela(i * 7)];

    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          height: 160,
          child: Column(
            children: [
              Expanded(
                child: RegisteredCartelaNumbersSummary(
                  cartelas: cartelas,
                  scrollable: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(CartelaNumberCompactBadge), findsNWidgets(100));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('numbers are sorted ascending and blocked ones are marked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        RegisteredCartelaNumbersSummary(
          cartelas: [
            _cartela(663),
            _cartela(56),
            _cartela(139, status: GameCartelaStatus.blocked),
          ],
        ),
      ),
    );

    final badges = tester
        .widgetList<CartelaNumberCompactBadge>(
          find.byType(CartelaNumberCompactBadge),
        )
        .toList();
    expect(badges.map((b) => b.number), [56, 139, 663]);
    expect(badges.map((b) => b.isBlocked), [false, true, false]);
    // Inside an already-scrolling parent it must not add its own scroll view.
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
