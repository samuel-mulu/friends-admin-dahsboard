import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  group('WinnerPayoutSummary', () {
    test('totals only the current user split amount', () {
      final payouts = [
        const WinnerPayoutSummary(
          cartelaId: 'cartela-1',
          cartelaNumber: 7,
          amount: '3.34',
          owner: 'OTHER',
        ),
        const WinnerPayoutSummary(
          cartelaId: 'cartela-2',
          cartelaNumber: 12,
          amount: '3.33',
          owner: 'ME',
        ),
        const WinnerPayoutSummary(
          cartelaId: 'cartela-3',
          cartelaNumber: 19,
          amount: '3.33',
          owner: 'OTHER',
        ),
      ];

      final total = WinnerPayoutSummary.totalForMyCartelas(
        payouts: payouts,
        myCartelaIds: {'cartela-2'},
      );

      expect(total, '3.33');
    });

    test('matches payout by cartela id when owner is omitted', () {
      final payouts = [
        const WinnerPayoutSummary(
          cartelaId: 'cartela-9',
          cartelaNumber: 9,
          amount: '40.00',
        ),
        const WinnerPayoutSummary(
          cartelaId: 'cartela-10',
          cartelaNumber: 10,
          amount: '40.00',
        ),
      ];

      final total = WinnerPayoutSummary.totalForMyCartelas(
        payouts: payouts,
        myCartelaIds: {'cartela-9'},
      );

      expect(total, '40.00');
    });

    test('GameModel exposes my payout amount from finished payload', () {
      final game = GameModel.fromOperationJson({
        'slotId': 'slot-1',
        'sessionId': 'session-1',
        'staticCode': 'ROWS-S1',
        'playCode': 'BINGO-ABC123',
        'playerStatus': 'finished',
        'rawStatus': 'FINISHED',
        'entryFee': '10',
        'prizePerCartela': '8',
        'prizeAmount': '10.00',
        'registeredCartelasCount': 3,
        'calledNumbersCount': 12,
        'winnerPayoutsSummary': [
          {
            'cartelaId': 'cartela-1',
            'cartelaNumber': 7,
            'amount': '3.34',
            'owner': 'OTHER',
          },
          {
            'cartelaId': 'cartela-2',
            'cartelaNumber': 12,
            'amount': '3.33',
            'owner': 'ME',
          },
          {
            'cartelaId': 'cartela-3',
            'cartelaNumber': 19,
            'amount': '3.33',
            'owner': 'OTHER',
          },
        ],
      });

      expect(
        game.myWinnerPayoutAmount({'cartela-2'}),
        '3.33',
      );
    });
  });
}
