import 'package:friends_bingo_app/src/features/games/data/models/session_outcome_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionOutcomeSummaryModel', () {
    test('parses winner and blocked cartela numbers', () {
      final summary = SessionOutcomeSummaryModel.fromJson({
        'winnerCartelaNumbers': [233, 15, 46],
        'blockedCartelaNumbers': [3, 44, 4],
      });

      expect(summary.winnerCartelaNumbers, [15, 46, 233]);
      expect(summary.blockedCartelaNumbers, [3, 4, 44]);
    });
  });

  group('mergeSortedCartelaNumbers', () {
    test('deduplicates and sorts merged session and local numbers', () {
      expect(
        mergeSortedCartelaNumbers([15, 46, 15, 3]),
        [3, 15, 46],
      );
    });

    test('merges session checking with local checking numbers', () {
      expect(
        mergeSortedCartelaNumbers([15, 46, 15, 46, 233]),
        [15, 46, 233],
      );
    });
  });
}
