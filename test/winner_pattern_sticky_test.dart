import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/winner_pattern_clear_policy.dart';

void main() {
  test('advance begin must not clear patterns', () {
    expect(
      shouldClearWinnerPatterns(
        WinnerPatternClearReason.postGameAdvanceBegin,
      ),
      isFalse,
    );
  });

  test('session changed clears patterns', () {
    expect(
      shouldClearWinnerPatterns(WinnerPatternClearReason.sessionChanged),
      isTrue,
    );
  });

  test('canonical without patterns does not clear', () {
    expect(
      shouldClearWinnerPatterns(
        WinnerPatternClearReason.canonicalMissingPatterns,
      ),
      isFalse,
    );
  });

  test('complete replacement may clear then store', () {
    expect(
      shouldClearWinnerPatterns(
        WinnerPatternClearReason.completePatternReplacement,
      ),
      isTrue,
    );
  });

  test('beginPostGameSummaryAdvance does not clear winner patterns', () async {
    final source = await File(
      'lib/src/features/games/presentation/controllers/live_review_controller.dart',
    ).readAsString();
    final start = source.indexOf('void beginPostGameSummaryAdvance');
    expect(start, greaterThanOrEqualTo(0));
    final snippet = source.substring(start, start + 500);
    expect(snippet.contains('clearFinishedReviewVisualState'), isFalse);
    expect(snippet.contains('winnerCartelaDisplay.clear'), isFalse);
  });
}
