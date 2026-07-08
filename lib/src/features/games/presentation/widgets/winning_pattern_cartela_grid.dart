import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../utils/cartela_board_layout.dart';
import '../utils/cartela_mark_helpers.dart';
import '../utils/cartela_pattern_progress_overlay.dart';
import 'cartela_pattern_progress_painter.dart';

class WinningPatternCartelaGrid extends StatelessWidget {
  const WinningPatternCartelaGrid({
    required this.columns,
    required this.highlightCellIndexes,
    this.patternOverlay = const CartelaPatternProgressOverlay(),
    this.winningBallCellIndex,
    this.compact = false,
    super.key,
  });

  final List<List<String>> columns;
  final Set<int> highlightCellIndexes;
  final CartelaPatternProgressOverlay patternOverlay;
  final int? winningBallCellIndex;
  final bool compact;

  Set<int> get _effectiveHighlightCellIndexes {
    if (highlightCellIndexes.isNotEmpty) {
      return highlightCellIndexes;
    }
    if (!patternOverlay.isEmpty) {
      return patternOverlay.allOverlayCellIndexes;
    }
    return highlightCellIndexes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerFontSize = compact
        ? CartelaBoardLayout.compactReviewHeaderFontSize
        : CartelaBoardLayout.reviewHeaderFontSize;
    final cellFontSize = compact
        ? CartelaBoardLayout.compactReviewCellNumberFontSize
        : CartelaBoardLayout.reviewCellNumberFontSize;
    final effectiveHighlights = _effectiveHighlightCellIndexes;

    return Column(
      children: [
        Row(
          children: List.generate(bingoColumnHeaders.length, (index) {
            final header = bingoColumnHeaders[index];
            return Expanded(
              child: Text(
                header,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppBranding.bingoColumnColor(header),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: CartelaBoardLayout.headerToGridGap),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppBranding.cartelaBoardBackground(context),
              borderRadius:
                  BorderRadius.circular(CartelaBoardLayout.boardBorderRadius),
              border: isDark
                  ? null
                  : Border.all(
                      color: AppBranding.lightOutline.withValues(alpha: 0.55),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CartelaBoardLayout.boardPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: List.generate(5, (rowIndex) {
                          return Expanded(
                            child: Row(
                              children: List.generate(5, (columnIndex) {
                                final value =
                                    columns[columnIndex].length > rowIndex
                                    ? columns[columnIndex][rowIndex]
                                    : '';
                                final cellIndex = rowIndex * 5 + columnIndex;
                                final isWinningBall =
                                    winningBallCellIndex == cellIndex;
                                final isHighlighted =
                                    effectiveHighlights.contains(cellIndex);
                                final isFree = value == 'FREE';

                                return Expanded(
                                  child: _WinningPatternCell(
                                    value: value,
                                    isWinningBall: isWinningBall,
                                    isHighlighted: isHighlighted,
                                    isFree: isFree,
                                    fontSize: cellFontSize,
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                      if (!patternOverlay.isEmpty)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: CartelaPatternProgressPainter(
                              overlay: patternOverlay,
                              cellInset: CartelaBoardLayout.cellPadding,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WinningPatternCell extends StatelessWidget {
  const _WinningPatternCell({
    required this.value,
    required this.isWinningBall,
    required this.isHighlighted,
    required this.isFree,
    required this.fontSize,
  });

  final String value;
  final bool isWinningBall;
  final bool isHighlighted;
  final bool isFree;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayValue = isFree ? 'F' : value;

    final Color fillColor;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color textColor;

    if (isFree) {
      fillColor = AppBranding.bingoFreeGreen;
      borderColor = Colors.white.withValues(alpha: 0.22);
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: AppBranding.bingoFreeGreen.withValues(alpha: 0.55),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isWinningBall) {
      fillColor = AppBranding.gold;
      borderColor = AppBranding.goldDark;
      textColor = AppBranding.casinoPurpleDeep;
      shadows = [
        BoxShadow(
          color: AppBranding.gold.withValues(alpha: 0.72),
          blurRadius: 12,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isHighlighted) {
      fillColor = AppBranding.bingoFreeGreen;
      borderColor = AppBranding.feltGreen;
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: AppBranding.bingoFreeGreen.withValues(alpha: 0.55),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else {
      fillColor = AppBranding.cellBackground(context, marked: false);
      borderColor = AppBranding.cellBorder(context, marked: false);
      textColor = AppBranding.cellForeground(context, marked: false);
      shadows = isDark
          ? const []
          : [
              BoxShadow(
                color: AppBranding.brandPurple.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ];
    }

    return Padding(
      padding: const EdgeInsets.all(CartelaBoardLayout.cellPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          return Center(
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: shadows,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: isFree ? fontSize + 1 : fontSize,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
