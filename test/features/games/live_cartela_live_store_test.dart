import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/live_cartela_live_store.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/live_cartela_live_store_sync.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';

final _now = DateTime.utc(2026, 3, 1);

GameCartelaModel _cartela(String id, int number, int anchorNumber) {
  List<String> column(int col) {
    return [
      for (var row = 0; row < 5; row++)
        row == 2 && col == 2
            ? 'FREE'
            : (col == 0 && row == 0 ? '$anchorNumber' : '${col * 15 + row + 1}'),
    ];
  }

  return GameCartelaModel(
    id: id,
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'c-$id',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'c-$id',
      number: number,
      createdAt: _now,
      b: column(0),
      i: column(1),
      n: column(2),
      g: column(3),
      o: column(4),
    ),
  );
}

void main() {
  test('buildBallNumberToCartelaIds maps numbers to cartela ids', () {
    final a = _cartela('a', 1, 7);
    final b = _cartela('b', 2, 12);
    final index = buildBallNumberToCartelaIds([a, b]);
    expect(index[7], contains('a'));
    expect(index[12], contains('b'));
  });

  test('afterCalledNumbersUpdated bumps only touched tile revisions', () {
    final store = LiveCartelaLiveStore();
    addTearDown(store.dispose);

    final a = _cartela('a', 1, 7);
    final b = _cartela('b', 2, 12);
    store.syncCartelas([a, b]);

    final listenableA = store.listenableFor('a');
    final listenableB = store.listenableFor('b');
    expect(listenableA.value, 0);
    expect(listenableB.value, 0);

    store.afterCalledNumbersUpdated(
      cartelas: [a, b],
      committedBallNumber: 7,
    );

    expect(listenableA.value, 1);
    expect(listenableB.value, 0);
  });
}
