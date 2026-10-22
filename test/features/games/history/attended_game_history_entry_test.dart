import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/pagination_meta.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/history/domain/entities/attended_game_history_entry.dart';
import 'package:friends_bingo_app/src/features/games/history/domain/entities/attended_game_history_state.dart';

void main() {
  group('AttendedGameHistoryEntry', () {
    test('parses from session JSON and sorts cartelas by number', () {
      final json = {
        'id': 'session-123',
        'status': 'finished',
        'slotId': 'slot-1',
        'round': 1,
        'finishedAt': '2026-10-22T18:00:00.000Z',
        'prizeAmount': '150.00',
        'category': 'normal',
        'myCartelas': [
          {
            'id': 'gc-2',
            'cartelaId': 'c-2',
            'userId': 'u-1',
            'gameSessionId': 'session-123',
            'status': 'registered',
            'isWinner': false,
            'createdAt': '2026-10-22T17:00:00.000Z',
            'updatedAt': '2026-10-22T17:00:00.000Z',
            'markedNumbers': [5, 12],
            'cartela': {
              'id': 'c-2',
              'number': 24,
              'createdAt': '2026-10-22T17:00:00.000Z',
              'columns': [
                [1, 2, 3, 4, 5],
                [16, 17, 18, 19, 20],
                [31, 32, 0, 34, 35],
                [46, 47, 48, 49, 50],
                [61, 62, 63, 64, 65],
              ],
            },
          },
          {
            'id': 'gc-1',
            'cartelaId': 'c-1',
            'userId': 'u-1',
            'gameSessionId': 'session-123',
            'status': 'winner',
            'isWinner': true,
            'createdAt': '2026-10-22T17:00:00.000Z',
            'updatedAt': '2026-10-22T17:00:00.000Z',
            'markedNumbers': [1, 2, 3, 4, 5],
            'cartela': {
              'id': 'c-1',
              'number': 7,
              'createdAt': '2026-10-22T17:00:00.000Z',
              'columns': [
                [1, 2, 3, 4, 5],
                [16, 17, 18, 19, 20],
                [31, 32, 0, 34, 35],
                [46, 47, 48, 49, 50],
                [61, 62, 63, 64, 65],
              ],
            },
          },
        ],
      };

      final entry = AttendedGameHistoryEntry.fromSessionJson(json);

      expect(entry.game.sessionId, 'session-123');
      expect(entry.hasWinningCartela, isTrue);
      expect(entry.myCartelas.length, 2);

      final sorted = entry.sortedCartelas;
      expect(sorted[0].cartela.number, 7);
      expect(sorted[1].cartela.number, 24);
    });
  });

  group('AttendedGameHistoryState', () {
    test('hasMore correctly reflects pagination state', () {
      final state1 = AttendedGameHistoryState(
        entries: const [],
        pagination: PaginationMeta(
          page: 1,
          pageSize: 20,
          totalItems: 50,
          totalPages: 3,
        ),
      );
      expect(state1.hasMore, isTrue);

      final state2 = state1.copyWith(
        pagination: PaginationMeta(
          page: 3,
          pageSize: 20,
          totalItems: 50,
          totalPages: 3,
        ),
      );
      expect(state2.hasMore, isFalse);
    });
  });
}
