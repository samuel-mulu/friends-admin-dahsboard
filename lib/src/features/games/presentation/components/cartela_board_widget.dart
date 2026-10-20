import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../data/models/cartela_model.dart';
import '../../domain/cartela_mark_color.dart';
import '../utils/cartela_pattern_progress_overlay.dart';
import '../widgets/cartela_pattern_progress_painter.dart';

enum CartelaBoardSize { compact, standard, large }

/// Standalone, reusable 5×5 B-I-N-G-O Cartela Board with complete styling,
/// animations, custom dauber color palette support, and winning pattern overlays.
class CartelaBoardWidget extends StatelessWidget {
  const CartelaBoardWidget({
    super.key,
    required this.cartela,
    required this.markedCells,
    this.winningPatternCells,
    this.winningBallNumber,
    this.lastMarkedNumber,
    this.oneAwayCellIndexes,
    this.patternOverlay = const CartelaPatternProgressOverlay(),
    this.markColor = CartelaMarkColor.green,
    this.isBlocked = false,
    this.isWinner = false,
    this.interactive = true,
    this.showHeader = true,
    this.onCellTapped,
    this.boardSize = CartelaBoardSize.standard,
    this.cardHeaderTrailing,
  });

  final CartelaModel cartela;
  final Set<int> markedCells;
  final Set<int>? winningPatternCells;
  final int? winningBallNumber;
  final int? lastMarkedNumber;
  final Set<int>? oneAwayCellIndexes;
  final CartelaPatternProgressOverlay patternOverlay;
  final CartelaMarkColor markColor;
  final bool isBlocked;
  final bool isWinner;
  final bool interactive;
  final bool showHeader;
  final void Function(int number)? onCellTapped;
  final CartelaBoardSize boardSize;
  final Widget? cardHeaderTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = [
      cartela.b,
      cartela.i,
      cartela.n,
      cartela.g,
      cartela.o,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: isWinner ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isWinner
                  ? AppBranding.gold
                  : isBlocked
                      ? theme.colorScheme.error
                      : theme.dividerColor.withValues(alpha: 0.2),
              width: isWinner ? 2.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Cartela # and status
              if (showHeader)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.style_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '#${cartela.number}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ?cardHeaderTrailing,
                    ],
                  ),
                ),
              // B-I-N-G-O Title Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                child: Row(
                  children: ['B', 'I', 'N', 'G', 'O'].map((letter) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppBranding.bingoColumnColor(letter),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 5x5 Matrix with optional pattern overlay
              Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: List.generate(5, (colIdx) {
                        final colData = columns[colIdx];
                        return Expanded(
                          child: Column(
                            children: List.generate(5, (rowIdx) {
                              final cellIndex = (rowIdx * 5) + colIdx;
                              final isFreeSpace = colIdx == 2 && rowIdx == 2;
                              final rawVal = (colData.length > rowIdx) ? colData[rowIdx] : '';
                              final number = isFreeSpace ? 0 : (int.tryParse(rawVal) ?? 0);
                              final isMarked = isFreeSpace || (number > 0 && markedCells.contains(number));
                              final isLastMarked = number > 0 && lastMarkedNumber != null && lastMarkedNumber == number;
                              final isWinningCell = number > 0 && (winningPatternCells?.contains(number) ?? false);
                              final isWinningBall = number > 0 && winningBallNumber != null && winningBallNumber == number;
                              final isOneAway = oneAwayCellIndexes?.contains(cellIndex) ?? false;

                              return _buildCell(
                                context: context,
                                number: number,
                                displayLabel: isFreeSpace ? 'FREE' : (number > 0 ? number.toString() : rawVal),
                                cellIndex: cellIndex,
                                isFreeSpace: isFreeSpace,
                                isMarked: isMarked,
                                isLastMarked: isLastMarked,
                                isWinningCell: isWinningCell,
                                isWinningBall: isWinningBall,
                                isOneAway: isOneAway,
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                    if (!patternOverlay.isEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: CartelaPatternProgressPainter(
                              overlay: patternOverlay,
                              cellInset: 2.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required int number,
    required String displayLabel,
    required int cellIndex,
    required bool isFreeSpace,
    required bool isMarked,
    required bool isLastMarked,
    required bool isWinningCell,
    required bool isWinningBall,
    required bool isOneAway,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color fillColor;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color textColor;

    if (isFreeSpace) {
      fillColor = AppBranding.bingoFreeGreen;
      borderColor = Colors.white.withValues(alpha: 0.22);
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: AppBranding.bingoFreeGreen.withValues(alpha: 0.55),
          blurRadius: 8,
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
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isWinningCell) {
      fillColor = AppBranding.gold.withValues(alpha: 0.35);
      borderColor = AppBranding.gold;
      textColor = isDark ? Colors.amberAccent : AppBranding.brandPurple;
      shadows = [
        BoxShadow(
          color: AppBranding.gold.withValues(alpha: 0.4),
          blurRadius: 6,
        ),
      ];
    } else if (isOneAway) {
      fillColor = theme.colorScheme.error.withValues(alpha: 0.2);
      borderColor = theme.colorScheme.error;
      textColor = theme.colorScheme.error;
      shadows = [
        BoxShadow(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
          blurRadius: 8,
        ),
      ];
    } else if (isLastMarked) {
      fillColor = AppBranding.gold;
      borderColor = AppBranding.goldDark;
      textColor = AppBranding.casinoPurpleDeep;
      shadows = [
        BoxShadow(
          color: AppBranding.gold.withValues(alpha: 0.72),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isMarked) {
      final palette = CartelaMarkColorPalette.forColor(markColor);
      fillColor = palette.fill;
      borderColor = palette.border;
      textColor = palette.text;
      shadows = [
        BoxShadow(
          color: palette.shadow.withValues(alpha: 0.55),
          blurRadius: 8,
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
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (interactive && !isFreeSpace && onCellTapped != null && number > 0)
                ? () => onCellTapped!(number)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: isWinningBall || isLastMarked ? 2.0 : 1.0,
                ),
                boxShadow: shadows,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: isFreeSpace ? 11 : 16,
                        fontWeight: (isMarked || isWinningCell || isWinningBall || isFreeSpace)
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
