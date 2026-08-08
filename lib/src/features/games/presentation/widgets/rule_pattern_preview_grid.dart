import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../domain/game_rule_pattern_preview.dart';
import 'cartela_pattern_progress_painter.dart';

/// Mini 5×5 cartela showing which cells form the winning pattern (sample).
class RulePatternPreviewGrid extends StatelessWidget {
  const RulePatternPreviewGrid({
    required this.markedCells,
    this.linePatterns = const [],
    this.squarePatterns = const [],
    this.anglePatterns = const [],
    this.shapePieces = const [],
    this.shapePolylines = const [],
    this.size = 160,
    super.key,
  });

  final Set<int> markedCells;
  final List<Set<int>> linePatterns;
  final List<Set<int>> squarePatterns;
  final List<Set<int>> anglePatterns;
  final List<Set<int>> shapePieces;
  final List<List<int>> shapePolylines;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = isDark
        ? const Color(0xFF2F3744)
        : AppBranding.lightSurface;
    final inactiveBorder = isDark
        ? const Color(0xFF475569)
        : AppBranding.lightOutline;
    const activeColor = AppBranding.bingoFreeGreen;
    const gap = 3.0;
    const headers = ['B', 'I', 'N', 'G', 'O'];
    final headerHeight = size * 0.16;
    final boardSize = size - headerHeight - 6;
    final cellSize = (boardSize - (gap * 4)) / 5;

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Row(
              children: List.generate(5, (col) {
                return Expanded(
                  child: Center(
                    child: Text(
                      headers[col],
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: List.generate(5, (row) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: row == 4 ? 0 : gap),
                        child: Row(
                          children: List.generate(5, (col) {
                            final index = row * 5 + col;
                            final isFree =
                                index == GameRulePatternPreview.freeCenter;
                            final isMarked = markedCells.contains(index);

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: col == 4 ? 0 : gap,
                                ),
                                child: Center(
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isMarked
                                          ? activeColor
                                          : inactiveColor.withValues(
                                              alpha: 0.92,
                                            ),
                                      border: Border.all(
                                        color: isFree || isMarked
                                            ? AppBranding.feltGreen
                                            : inactiveBorder,
                                        width: isMarked ? 1.8 : 1.1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isMarked
                                                      ? activeColor
                                                      : Colors.black)
                                                  .withValues(
                                                    alpha: isMarked
                                                        ? 0.30
                                                        : 0.10,
                                                  ),
                                          blurRadius: isMarked ? 8 : 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: isFree
                                        ? Center(
                                            child: Text(
                                              'FREE',
                                              style: theme
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: isMarked
                                                        ? Colors.white
                                                        : AppBranding
                                                              .feltGreen,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: cellSize * 0.20,
                                                  ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  }),
                ),
                if (linePatterns.isNotEmpty ||
                    squarePatterns.isNotEmpty ||
                    anglePatterns.isNotEmpty ||
                    shapePieces.isNotEmpty ||
                    shapePolylines.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CartelaPatternProgressPainter(
                        overlay: overlayFromRulePreview(
                          linePatterns: linePatterns,
                          squarePatterns: squarePatterns,
                          anglePatterns: anglePatterns,
                          shapePieces: shapePieces,
                          shapePolylines: shapePolylines,
                        ),
                        gap: gap,
                        lineStrokeWidth: 2.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
