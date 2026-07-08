import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/completed_pattern_model.dart';

void main() {
  test('parses completed pattern cells into highlight indexes', () {
    final pattern = CompletedPatternModel.fromJson({
      'type': 'ROW',
      'key': 'ROW_1',
      'numbers': [7, 22, 37, 56, 74],
      'cells': [
        [0, 0],
        [1, 0],
        [2, 0],
        [3, 0],
        [4, 0],
      ],
    });

    expect(pattern.highlightCellIndexes, {0, 5, 10, 15, 20});
  });

  test('mergedHighlightIndexes unions multiple patterns', () {
    final patterns = [
      CompletedPatternModel.fromJson({
        'type': 'ROW',
        'numbers': [1],
        'cells': [
          [0, 0],
        ],
      }),
      CompletedPatternModel.fromJson({
        'type': 'ROW',
        'numbers': [2],
        'cells': [
          [0, 1],
        ],
      }),
    ];

    expect(
      CompletedPatternModel.mergedHighlightIndexes(patterns),
      {0, 1},
    );
  });
}
