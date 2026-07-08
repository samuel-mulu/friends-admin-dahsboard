import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_called_number_sync.dart';

CalledNumberModel _calledNumber({
  required String id,
  required int order,
  required int number,
}) {
  return CalledNumberModel(
    id: id,
    sessionId: 'session-1',
    slotId: 'slot-1',
    letter: 'B',
    number: number,
    order: order,
    createdAt: DateTime(2026, 6, 12, 12, 0, order),
    playerStatus: 'playing',
  );
}

void main() {
  group('live called number sync', () {
    test(
      'normalizes by order ascending and removes duplicate id/order entries',
      () {
        final normalized = normalizeCalledNumbers([
          _calledNumber(id: 'cn-2', order: 2, number: 12),
          _calledNumber(id: 'cn-1', order: 1, number: 7),
          _calledNumber(id: 'cn-1', order: 1, number: 7),
          _calledNumber(id: 'cn-2b', order: 2, number: 12),
          _calledNumber(id: 'cn-3', order: 3, number: 19),
        ]);

        expect(normalized.map((item) => item.order).toList(), [1, 2, 3]);
        expect(normalized.map((item) => item.id).toList(), [
          'cn-1',
          'cn-2',
          'cn-3',
        ]);
      },
    );

    test('deduplicates duplicate events by order even when id changes', () {
      final result = applyLiveCalledNumberNotification(
        committed: [
          _calledNumber(id: 'cn-1', order: 1, number: 7),
          _calledNumber(id: 'cn-2', order: 2, number: 12),
        ],
        deferred: const [],
        incoming: _calledNumber(id: 'cn-2-dup', order: 2, number: 12),
      );

      expect(result.isDuplicate, isTrue);
      expect(result.committed.map((item) => item.order).toList(), [1, 2]);
      expect(result.deferred, isEmpty);
    });

    test('holds out-of-order draws until missing order arrives', () {
      final deferredFirst = applyLiveCalledNumberNotification(
        committed: [
          _calledNumber(id: 'cn-1', order: 1, number: 7),
          _calledNumber(id: 'cn-2', order: 2, number: 12),
          _calledNumber(id: 'cn-3', order: 3, number: 19),
          _calledNumber(id: 'cn-4', order: 4, number: 23),
          _calledNumber(id: 'cn-5', order: 5, number: 29),
        ],
        deferred: const [],
        incoming: _calledNumber(id: 'cn-7', order: 7, number: 33),
      );

      expect(deferredFirst.requiresCanonicalSync, isTrue);
      expect(deferredFirst.committed.map((item) => item.order).toList(), [
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(deferredFirst.deferred.map((item) => item.order).toList(), [7]);

      final resolved = applyLiveCalledNumberNotification(
        committed: deferredFirst.committed,
        deferred: deferredFirst.deferred,
        incoming: _calledNumber(id: 'cn-6', order: 6, number: 31),
      );

      expect(resolved.requiresCanonicalSync, isFalse);
      expect(resolved.committed.map((item) => item.order).toList(), [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
      expect(resolved.accepted.map((item) => item.order).toList(), [6, 7]);
      expect(resolved.deferred, isEmpty);
    });

    test(
      'reconnect canonical snapshot clears deferred gaps once history is loaded',
      () {
        final committed = [
          _calledNumber(id: 'cn-1', order: 1, number: 7),
          _calledNumber(id: 'cn-2', order: 2, number: 12),
        ];
        final deferred = [_calledNumber(id: 'cn-4', order: 4, number: 23)];
        final canonical = normalizeCalledNumbers([
          _calledNumber(id: 'cn-1', order: 1, number: 7),
          _calledNumber(id: 'cn-2', order: 2, number: 12),
          _calledNumber(id: 'cn-3', order: 3, number: 19),
          _calledNumber(id: 'cn-4', order: 4, number: 23),
        ]);

        final remainingDeferred = pruneDeferredCalledNumbers(
          committed: canonical,
          deferred: deferred,
        );

        expect(
          mergeCalledNumbers(
            current: committed,
            incoming: canonical,
          ).map((item) => item.order).toList(),
          [1, 2, 3, 4],
        );
        expect(remainingDeferred, isEmpty);
      },
    );
  });
}
