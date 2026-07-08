import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/winning_ball_cell.dart';

void main() {
  const columns = [
    ['1', '2', '3', '4', '5'],
    ['16', '17', '18', '19', '20'],
    ['31', '32', 'FREE', '34', '35'],
    ['46', '47', '48', '49', '50'],
    ['61', '62', '63', '64', '65'],
  ];

  group('cellIndexForCalledNumber', () {
    test('finds B-5 at index 20', () {
      expect(cellIndexForCalledNumber(columns, 5), 20);
    });

    test('returns null for number not on board', () {
      expect(cellIndexForCalledNumber(columns, 99), isNull);
    });
  });

  group('resolveWinningBallCellIndex', () {
    test('prefers API index when valid', () {
      expect(
        resolveWinningBallCellIndex(
          columns: columns,
          highlightCellIndexes: {20, 21},
          winningBallCellIndex: 20,
        ),
        20,
      );
    });

    test('derives index from lastCalledNumber when API index missing', () {
      expect(
        resolveWinningBallCellIndex(
          columns: columns,
          highlightCellIndexes: {20, 21, 22, 23, 24},
          lastCalledNumber: const SessionWinnerLastCalledNumber(
            letter: 'B',
            number: 5,
          ),
        ),
        20,
      );
    });

    test('highlights lastCalledNumber when present on cartela', () {
      expect(
        resolveWinningBallCellIndex(
          columns: columns,
          highlightCellIndexes: {0, 1, 2},
          lastCalledNumber: const SessionWinnerLastCalledNumber(
            letter: 'B',
            number: 5,
          ),
        ),
        20,
      );
    });
  });
}
