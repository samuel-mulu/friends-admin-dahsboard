import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/winner_cartela_live_display.dart';

void main() {
  const columns = <List<String>>[
    ['7', '13', '10', '9', '4'],
    ['22', '20', '26', '18', '21'],
    ['37', '43', 'FREE', '41', '42'],
    ['56', '51', '57', '60', '53'],
    ['74', '64', '65', '72', '62'],
  ];

  const patterns = [
    CompletedPatternModel(
      type: 'ROW',
      key: 'ROW_1',
      numbers: [7, 22, 37, 56, 74],
      highlightCellIndexes: {0, 1, 2, 3, 4},
    ),
  ];

  test('resolveLiveWinningBallCellIndex finds ball inside pattern', () {
    expect(
      resolveLiveWinningBallCellIndex(
        columns: columns,
        patterns: patterns,
        lastCalledNumber: const SessionWinnerLastCalledNumber(
          letter: 'O',
          number: 74,
        ),
      ),
      4,
    );
  });

  test('WinnerCartelaDisplayCache stores winning ball for claim snapshot', () {
    final cache = WinnerCartelaDisplayCache();

    cache.storeClaimSnapshot(
      gameCartelaId: 'gc-1',
      patterns: patterns,
      columns: columns,
      lastCalledNumber: const SessionWinnerLastCalledNumber(
        letter: 'O',
        number: 74,
      ),
    );

    expect(cache.winningBallCellIndexByGameCartelaId['gc-1'], 4);
    expect(cache.overlayByGameCartelaId['gc-1']?.isEmpty, isFalse);
  });

  test('applySessionResult without patterns leaves sticky claim patterns', () {
    final cache = WinnerCartelaDisplayCache();
    cache.storeClaimSnapshot(
      gameCartelaId: 'c1',
      patterns: patterns,
      columns: columns,
      lastCalledNumber: const SessionWinnerLastCalledNumber(
        letter: 'O',
        number: 74,
      ),
    );

    cache.applySessionResult(
      SessionWinnerResultModel(
        gameCartelaId: 'c1',
        cartelaId: 'cartela-1',
        cartelaNumber: 1,
        amount: '10',
        columns: columns,
        completedPatterns: const [],
      ),
    );

    expect(cache.hasPatternsFor('c1'), isTrue);
    expect(cache.overlayByGameCartelaId['c1']?.isEmpty, isFalse);
  });

  test(
    'applySessionResult without patterns leaves sticky storePatterns overlays',
    () {
      final cache = WinnerCartelaDisplayCache();
      cache.storePatterns(
        gameCartelaId: 'c2',
        patterns: patterns,
        columns: columns,
      );

      cache.applySessionResult(
        SessionWinnerResultModel(
          gameCartelaId: 'c2',
          cartelaId: 'cartela-2',
          cartelaNumber: 2,
          amount: '10',
          columns: columns,
          completedPatterns: const [],
        ),
      );

      expect(cache.hasPatternsFor('c2'), isTrue);
    },
  );

  test(
    'WinnerCartelaDisplayCache clears stale winning ball when unresolved',
    () {
      final cache = WinnerCartelaDisplayCache();

      cache.storeClaimSnapshot(
        gameCartelaId: 'gc-1',
        patterns: patterns,
        columns: columns,
        lastCalledNumber: const SessionWinnerLastCalledNumber(
          letter: 'O',
          number: 74,
        ),
      );

      cache.applySessionResult(
        SessionWinnerResultModel(
          gameCartelaId: 'gc-1',
          cartelaId: 'c-1',
          cartelaNumber: 1,
          amount: '10',
          columns: columns,
          completedPatterns: patterns,
          lastCalledNumber: const SessionWinnerLastCalledNumber(
            letter: 'I',
            number: 24,
          ),
        ),
      );

      expect(
        cache.winningBallCellIndexByGameCartelaId.containsKey('gc-1'),
        isFalse,
      );
    },
  );

  test('displayWinningBallLabel shows API ball even when not on cartela', () {
    final result = SessionWinnerResultModel(
      gameCartelaId: 'gc-1',
      cartelaId: 'c-1',
      cartelaNumber: 270,
      amount: '50',
      columns: columns,
      completedPatterns: patterns,
      lastCalledNumber: const SessionWinnerLastCalledNumber(
        letter: 'I',
        number: 24,
      ),
    );

    expect(result.resolvedWinningBallCellIndex, isNull);
    expect(result.displayWinningBallLabel, 'I-24');
  });

  test(
    'displayWinningBallLabel prefers API lastCalledNumber when resolved',
    () {
      final result = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 13,
        amount: '50',
        columns: columns,
        completedPatterns: patterns,
        winningBallCellIndex: 4,
        lastCalledNumber: const SessionWinnerLastCalledNumber(
          letter: 'I',
          number: 19,
        ),
      );

      expect(result.resolvedWinningBallCellIndex, 4);
      expect(result.displayWinningBallLabel, 'I-19');
    },
  );

  test(
    'displayWinningBallLabel falls back to grid column without API ball',
    () {
      final result = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 1,
        amount: '50',
        columns: columns,
        completedPatterns: patterns,
        winningBallCellIndex: 4,
      );

      expect(result.displayWinningBallLabel, 'O-74');
    },
  );
}
