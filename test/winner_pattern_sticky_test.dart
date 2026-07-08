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
}
