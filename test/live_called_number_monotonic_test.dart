import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_called_number_monotonic.dart';

void main() {
  test('same session refuses shorter HTTP list when local is ahead', () {
    final merged = mergeCalledNumbersMonotonic(
      sessionId: 's1',
      localSessionId: 's1',
      localOrders: const [1, 2, 3, 4],
      incomingOrders: const [1, 2, 3],
      preferIncomingIfNewerSocket: false,
    );
    expect(merged.orders, [1, 2, 3, 4]);
    expect(merged.rejectedRollback, isTrue);
  });

  test('session change accepts full incoming replace', () {
    final merged = mergeCalledNumbersMonotonic(
      sessionId: 's2',
      localSessionId: 's1',
      localOrders: const [1, 2, 3, 4],
      incomingOrders: const [1],
      preferIncomingIfNewerSocket: false,
    );
    expect(merged.orders, [1]);
    expect(merged.rejectedRollback, isFalse);
  });

  test('socket orders union wins when marked newer during recovery', () {
    final merged = mergeCalledNumbersMonotonic(
      sessionId: 's1',
      localSessionId: 's1',
      localOrders: const [1, 2, 3, 5],
      incomingOrders: const [1, 2, 3, 4],
      preferIncomingIfNewerSocket: true,
      socketMaxOrder: 5,
      incomingMaxOrder: 4,
    );
    expect(merged.orders.contains(5), isTrue);
    expect(merged.rejectedRollback, isTrue);
  });
}
