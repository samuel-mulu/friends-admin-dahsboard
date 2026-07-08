import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/cartela_mark_helpers.dart';

GameCartelaModel _cartelaWithColumns(List<List<String>> columns) {
  final now = DateTime.utc(2026, 1, 1);
  return GameCartelaModel(
    id: 'gc-1',
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-1',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: now,
    updatedAt: now,
    cartela: CartelaModel(
      id: 'cartela-1',
      number: 1,
      createdAt: now,
      b: columns[0],
      i: columns[1],
      n: columns[2],
      g: columns[3],
      o: columns[4],
    ),
  );
}

void main() {
  group('resolveLastManualMarkedKey', () {
    test('sets gold target when a new mark is added', () {
      expect(
        resolveLastManualMarkedKey(
          currentLastMarkedKey: 'B:1',
          nextMarks: {'B:1', 'B:4'},
          toggledKey: 'B:4',
        ),
        'B:4',
      );
    });

    test('clears gold target when the last marked cell is unmarked', () {
      expect(
        resolveLastManualMarkedKey(
          currentLastMarkedKey: 'B:4',
          nextMarks: {'B:1'},
          toggledKey: 'B:4',
        ),
        isNull,
      );
    });

    test('keeps gold target when a non-gold marked cell is unmarked', () {
      expect(
        resolveLastManualMarkedKey(
          currentLastMarkedKey: 'B:4',
          nextMarks: {'B:4'},
          toggledKey: 'B:1',
        ),
        'B:4',
      );
    });
  });

  group('isLastManuallyMarkedCell', () {
    test('returns true only for the last marked key', () {
      expect(
        isLastManuallyMarkedCell(
          lastManualMarkedKey: 'B:4',
          header: 'B',
          value: '4',
        ),
        isTrue,
      );
      expect(
        isLastManuallyMarkedCell(
          lastManualMarkedKey: 'B:4',
          header: 'B',
          value: '1',
        ),
        isFalse,
      );
    });
  });

  group('reviewMarksIncludingCalled', () {
    test('merges manual marks with every called ball', () {
      final marks = reviewMarksIncludingCalled(
        manualMarkedNumbers: {'B:7'},
        calledNumbers: [
          CalledNumberModel(
            id: 'cn-1',
            sessionId: 'session-1',
            letter: 'I',
            number: 22,
            order: 1,
            createdAt: DateTime.utc(2026, 6, 18),
          ),
        ],
      );

      expect(marks, {'B:7', 'I:22'});
    });
  });

  group('clearManualMarksForCartela', () {
    test('removes shared marks that appear on the requested cartela', () {
      final cartela = _cartelaWithColumns([
        ['7', '16', '31', '46', '61'],
        ['2', '22', '32', '47', '62'],
        ['3', '18', 'FREE', '48', '63'],
        ['4', '19', '33', '49', '64'],
        ['5', '20', '34', '50', '65'],
      ]);
      final marks = {'B:7', 'I:22', 'G:52'};

      expect(
        clearManualMarksForCartela(
          manualMarkedNumbers: marks,
          cartela: cartela,
        ),
        {'G:52'},
      );
    });
  });

  group('manualMarksForCartela', () {
    test('shows shared marks on every cartela that contains the number', () {
      final cartelaOne = _cartelaWithColumns([
        ['1', '2', '3', '4', '5'],
        ['16', '22', '18', '19', '20'],
        ['31', '32', 'FREE', '34', '35'],
        ['46', '47', '48', '49', '50'],
        ['61', '62', '63', '64', '65'],
      ]);
      final cartelaTwo = _cartelaWithColumns([
        ['6', '7', '8', '9', '10'],
        ['17', '21', '22', '23', '24'],
        ['36', '37', 'FREE', '38', '39'],
        ['51', '52', '53', '54', '55'],
        ['66', '67', '68', '69', '70'],
      ]);

      const marks = {'I:22'};

      expect(
        manualMarksForCartela(cartela: cartelaOne, manualMarkedNumbers: marks),
        {'I:22'},
      );
      expect(
        manualMarksForCartela(cartela: cartelaTwo, manualMarkedNumbers: marks),
        {'I:22'},
      );
    });
  });

  group('normalizeManualMarkedNumbers', () {
    test('keeps only normalized global mark keys', () {
      expect(normalizeManualMarkedNumbers({'B:1', 'bad-key', 'I:22'}), {
        'B:1',
        'I:22',
      });
    });
  });
}
