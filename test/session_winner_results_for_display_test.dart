import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/session_winner_results_for_display.dart';

void main() {
  const columns = <List<String>>[
    ['7', '13', '10', '9', '4'],
    ['22', '20', '26', '18', '21'],
    ['37', '43', 'FREE', '41', '42'],
    ['56', '51', '57', '60', '53'],
    ['74', '64', '65', '72', '62'],
  ];

  const apiPatterns = [
    CompletedPatternModel(
      type: 'ROW',
      key: 'ROW_1',
      numbers: [7, 22, 37, 56, 74],
      highlightCellIndexes: {0, 5, 10, 15, 20},
    ),
  ];

  const claimPatterns = [
    CompletedPatternModel(
      type: 'ROW',
      key: 'ROW_5',
      numbers: [4, 21, 42, 53, 62],
      highlightCellIndexes: {4, 9, 14, 19, 24},
    ),
  ];

  SessionWinnerResultModel apiResult({
    required String gameCartelaId,
    required int cartelaNumber,
    required SessionWinnerLastCalledNumber lastCalled,
    required int winningBallCellIndex,
    List<CompletedPatternModel> patterns = apiPatterns,
  }) {
    return SessionWinnerResultModel(
      gameCartelaId: gameCartelaId,
      cartelaId: 'cartela-$cartelaNumber',
      cartelaNumber: cartelaNumber,
      amount: '40.00',
      columns: columns,
      completedPatterns: patterns,
      winningBallCellIndex: winningBallCellIndex,
      lastCalledNumber: lastCalled,
    );
  }

  test('keeps per-winner API lastCalledNumber without session override', () {
    final results = sessionWinnerResultsForDisplay(
      apiResults: [
        apiResult(
          gameCartelaId: 'gc-1',
          cartelaNumber: 5,
          lastCalled: const SessionWinnerLastCalledNumber(
            letter: 'B',
            number: 74,
          ),
          winningBallCellIndex: 20,
        ),
        apiResult(
          gameCartelaId: 'gc-2',
          cartelaNumber: 12,
          lastCalled: const SessionWinnerLastCalledNumber(
            letter: 'O',
            number: 75,
          ),
          winningBallCellIndex: 21,
        ),
      ],
      claimPatternsByGameCartelaId: {
        'gc-1': claimPatterns,
        'gc-2': claimPatterns,
      },
    );

    expect(results, hasLength(2));
    expect(results[0].lastCalledNumber?.number, 74);
    expect(results[0].winningBallCellIndex, 20);
    expect(results[0].completedPatterns, apiPatterns);
    expect(results[1].lastCalledNumber?.number, 75);
    expect(results[1].winningBallCellIndex, 21);
    expect(results[1].completedPatterns, apiPatterns);
  });

  test('uses one session lastCalledNumber for every winner when provided', () {
    const sessionLast = SessionWinnerLastCalledNumber(
      letter: 'I',
      number: 19,
    );

    final results = sessionWinnerResultsForDisplay(
      apiResults: [
        apiResult(
          gameCartelaId: 'gc-1',
          cartelaNumber: 3,
          lastCalled: const SessionWinnerLastCalledNumber(
            letter: 'I',
            number: 24,
          ),
          winningBallCellIndex: 6,
        ),
        apiResult(
          gameCartelaId: 'gc-2',
          cartelaNumber: 13,
          lastCalled: const SessionWinnerLastCalledNumber(
            letter: 'I',
            number: 24,
          ),
          winningBallCellIndex: 6,
        ),
      ],
      claimPatternsByGameCartelaId: const {},
      sessionLastCalledNumber: sessionLast,
    );

    expect(results, hasLength(2));
    expect(results[0].lastCalledNumber, sessionLast);
    expect(results[1].lastCalledNumber, sessionLast);
    expect(results[0].displayWinningBallLabel, 'I-19');
    expect(results[1].displayWinningBallLabel, 'I-19');
  });

  test('uses claim patterns only while API patterns are still empty', () {
    final results = sessionWinnerResultsForDisplay(
      apiResults: [
        apiResult(
          gameCartelaId: 'gc-1',
          cartelaNumber: 5,
          lastCalled: const SessionWinnerLastCalledNumber(
            letter: 'B',
            number: 74,
          ),
          winningBallCellIndex: 20,
          patterns: const [],
        ),
      ],
      claimPatternsByGameCartelaId: {
        'gc-1': claimPatterns,
      },
    );

    expect(results.single.completedPatterns, claimPatterns);
    expect(results.single.lastCalledNumber?.number, 74);
    expect(results.single.winningBallCellIndex, 20);
  });

  test('uses payout summary when API amount is zero', () {
    final results = sessionWinnerResultsForDisplay(
      apiResults: [
        apiResult(
          gameCartelaId: 'gc-1',
          cartelaNumber: 317,
          lastCalled: const SessionWinnerLastCalledNumber(
            letter: 'I',
            number: 24,
          ),
          winningBallCellIndex: 6,
        ).copyWith(amount: '0'),
      ],
      claimPatternsByGameCartelaId: const {},
      winnerPayoutsSummary: const [
        WinnerPayoutSummary(
          cartelaId: 'cartela-317',
          cartelaNumber: 317,
          amount: '50.66',
          owner: 'OTHER',
        ),
      ],
    );

    expect(results.single.amount, '50.66');
  });

  test('deduplicates winner rows by gameCartelaId', () {
    final duplicateA = apiResult(
      gameCartelaId: 'gc-1',
      cartelaNumber: 9,
      lastCalled: const SessionWinnerLastCalledNumber(
        letter: 'B',
        number: 74,
      ),
      winningBallCellIndex: 20,
      patterns: const [],
    );
    final duplicateB = apiResult(
      gameCartelaId: 'gc-1',
      cartelaNumber: 9,
      lastCalled: const SessionWinnerLastCalledNumber(
        letter: 'B',
        number: 74,
      ),
      winningBallCellIndex: 20,
      patterns: apiPatterns,
    );

    final results = sessionWinnerResultsForDisplay(
      apiResults: [duplicateA, duplicateB],
      claimPatternsByGameCartelaId: const {},
    );

    expect(results, hasLength(1));
    expect(results.single.gameCartelaId, 'gc-1');
    expect(results.single.completedPatterns, isNotEmpty);
  });

  test('deduplicates winner rows by cartela number fallback', () {
    final first = SessionWinnerResultModel(
      gameCartelaId: '',
      cartelaId: '',
      cartelaNumber: 27,
      amount: '10.00',
      columns: const [],
      completedPatterns: const [],
      owner: 'OTHER',
    );
    final second = SessionWinnerResultModel(
      gameCartelaId: '',
      cartelaId: '',
      cartelaNumber: 27,
      amount: '10.00',
      columns: columns,
      completedPatterns: apiPatterns,
      owner: 'OTHER',
    );

    final results = sessionWinnerResultsForDisplay(
      apiResults: [first, second],
      claimPatternsByGameCartelaId: const {},
    );

    expect(results, hasLength(1));
    expect(results.single.cartelaNumber, 27);
    expect(results.single.completedPatterns, isNotEmpty);
  });

  test('sticky claim-only patterns can build display rows without API results', () {
    final patterns = [
      CompletedPatternModel(
        type: 'ROW',
        key: 'ROW_1',
        numbers: const [1, 2, 3, 4, 5],
        highlightCellIndexes: {0, 1, 2, 3, 4},
      ),
    ];

    final results = sessionWinnerResultsForDisplay(
      apiResults: const [],
      claimPatternsByGameCartelaId: {'gc-1': patterns},
    );

    expect(results, hasLength(1));
    expect(results.single.gameCartelaId, 'gc-1');
    expect(results.single.completedPatterns, isNotEmpty);
    expect(winnerResultsReadyForDisplay(results), isTrue);
  });

  test('winnerDialogReadyForImmediateShow accepts sticky payload', () {
    expect(
      winnerDialogReadyForImmediateShow(
        summaryOrWinnerWindowVisible: true,
        hasStickyWinnerPayload: true,
        winnerResultsLoaded: false,
      ),
      isTrue,
    );
    expect(
      winnerDialogReadyForImmediateShow(
        summaryOrWinnerWindowVisible: true,
        hasStickyWinnerPayload: false,
        winnerResultsLoaded: true,
      ),
      isTrue,
    );
    expect(
      winnerDialogReadyForImmediateShow(
        summaryOrWinnerWindowVisible: false,
        hasStickyWinnerPayload: true,
        winnerResultsLoaded: true,
      ),
      isFalse,
    );
  });

  test('winnerResultsReadyForDisplay requires completed patterns', () {
    final withPatterns = SessionWinnerResultModel(
      gameCartelaId: 'gc-1',
      cartelaId: 'cartela-1',
      cartelaNumber: 5,
      amount: '10.00',
      columns: columns,
      completedPatterns: apiPatterns,
    );
    final columnsOnly = SessionWinnerResultModel(
      gameCartelaId: 'gc-2',
      cartelaId: 'cartela-2',
      cartelaNumber: 6,
      amount: '10.00',
      columns: columns,
      completedPatterns: const [],
    );

    expect(winnerResultReadyForDisplay(withPatterns), isTrue);
    expect(winnerResultReadyForDisplay(columnsOnly), isFalse);
    expect(winnerResultsReadyForDisplay([withPatterns]), isTrue);
    expect(winnerResultsReadyForDisplay([withPatterns, columnsOnly]), isFalse);
    expect(winnerResultsReadyForDisplay(const []), isFalse);
  });
}
