import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_pattern_preview.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_pattern_progress_painter.dart';

void main() {
  group('rule sample red-line overlays', () {
    test('SMALL_CROSS_TRIANGLE_SQUARE draws cross, triangle, and square', () {
      final sample =
          GameRulePatternPreview.samplesForRule('SMALL_CROSS_TRIANGLE_SQUARE')
              .single;
      final overlay = overlayFromRulePreview(
        linePatterns: sample.linePatterns,
        squarePatterns: sample.squarePatterns,
        anglePatterns: sample.anglePatterns,
        shapePieces: sample.shapePieces,
        shapePolylines: sample.shapePolylines,
      );

      expect(overlay.squares, hasLength(1));
      expect(overlay.shapePolylines, isNotEmpty);
      expect(overlay.isEmpty, isFalse);
      expect(
        overlay.allOverlayCellIndexes.containsAll(sample.shapePieces.first),
        isTrue,
      );
    });

    test('THREE_SMALL_T draws six small-T strokes', () {
      final sample =
          GameRulePatternPreview.samplesForRule('THREE_SMALL_T').single;
      final overlay = overlayFromRulePreview(
        shapePieces: sample.shapePieces,
      );

      expect(sample.shapePieces, hasLength(3));
      expect(overlay.shapePolylines, hasLength(6));
    });

    test('ONE_LINE_TWO_TRIANGLES draws line plus triangle outlines', () {
      final sample =
          GameRulePatternPreview.samplesForRule('ONE_LINE_TWO_TRIANGLES')
              .single;
      final overlay = overlayFromRulePreview(
        linePatterns: sample.linePatterns,
        shapePieces: sample.shapePieces,
      );

      expect(overlay.lines, hasLength(1));
      expect(overlay.shapePolylines, isNotEmpty);
    });

    test('THREE_RECTANGLES outlines three rectangle blocks', () {
      final sample =
          GameRulePatternPreview.samplesForRule('THREE_RECTANGLES').single;
      final overlay = overlayFromRulePreview(
        shapePieces: sample.shapePieces,
      );

      expect(overlay.squares, hasLength(3));
    });

    test('BIG_N_OR_Z samples expose shape polylines', () {
      final samples = GameRulePatternPreview.samplesForRule('BIG_N_OR_Z');
      expect(samples, isNotEmpty);
      for (final sample in samples) {
        expect(sample.shapePolylines, isNotEmpty);
        final overlay = overlayFromRulePreview(
          shapePolylines: sample.shapePolylines,
        );
        expect(overlay.shapePolylines, isNotEmpty);
      }
    });

    test('single-cell angles become corner highlights', () {
      final sample =
          GameRulePatternPreview.samplesForRule('THREE_SQUARES_TWO_ANGLES')
              .single;
      final overlay = overlayFromRulePreview(
        squarePatterns: sample.squarePatterns,
        anglePatterns: sample.anglePatterns,
      );

      expect(overlay.squares, hasLength(3));
      expect(overlay.cornerHighlightCells, {0, 24});
    });
  });
}
