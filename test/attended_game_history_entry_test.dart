import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/attended_game_history_entry.dart';

void main() {
  test('fromSessionJson parses nested my cartelas', () {
    final entry = AttendedGameHistoryEntry.fromSessionJson({
      'id': 'session-1',
      'sessionId': 'session-1',
      'staticCode': 'MIX_01-S1',
      'playCode': '123',
      'name': 'Friday Bingo',
      'gameType': 'FULL_HOUSE',
      'entryFee': '5.00',
      'prizePerCartela': '10.00',
      'companyFeePerCartela': '1.00',
      'prizeAmount': '100.00',
      'companyRevenue': '20.00',
      'status': 'FINISHED',
      'playOrder': 1,
      'startedAt': '2026-06-15T12:00:00.000Z',
      'finishedAt': '2026-06-15T12:30:00.000Z',
      'createdAt': '2026-06-15T12:00:00.000Z',
      'updatedAt': '2026-06-15T12:30:00.000Z',
      'registeredCartelasCount': 10,
      'calledNumbersCount': 20,
      'registrationOpen': false,
      'gameSlot': {
        'staticCode': 'FULL_HOUSE-S1',
        'gameType': 'FULL_HOUSE',
        'name': 'Friday Bingo',
      },
      'myCartelas': [
        {
          'id': 'gc-1',
          'gameSessionId': 'session-1',
          'userId': 'user-1',
          'cartelaId': 'cartela-1',
          'status': 'REGISTERED',
          'isWinner': false,
          'createdAt': '2026-06-15T12:00:00.000Z',
          'updatedAt': '2026-06-15T12:00:00.000Z',
          'cartela': {
            'id': 'cartela-1',
            'number': 12,
            'createdAt': '2026-06-15T12:00:00.000Z',
            'b': ['1', '2', '3', '4', '5'],
            'i': ['6', '7', '8', '9', '10'],
            'n': ['11', '12', 'FREE', '14', '15'],
            'g': ['16', '17', '18', '19', '20'],
            'o': ['21', '22', '23', '24', '25'],
          },
        },
      ],
    });

    expect(entry.game.sessionId, 'session-1');
    expect(entry.myCartelas, hasLength(1));
    expect(entry.myCartelas.first.cartela.number, 12);
    expect(entry.myCartelas.first.status, GameCartelaStatus.registered);
  });
}
