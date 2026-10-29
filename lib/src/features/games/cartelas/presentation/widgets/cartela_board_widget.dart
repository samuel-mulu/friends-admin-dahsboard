import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_board_layout.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_color.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_pattern_progress_overlay.dart';
import 'cartela_pattern_progress_painter.dart';

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
    this.expandToFill = false,
    this.pulseOneAwayCells = false,
    this.decorativeMotionAllowedListenable,
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

  /// When true, stretches the inner board to the parent's height (live play cards).
  final bool expandToFill;

  /// Pulses one-away cell fill/border (live play); requires [oneAwayCellIndexes].
  final bool pulseOneAwayCells;

  /// When false (e.g. list scrolling), one-away cell pulse pauses.
  final ValueListenable<bool>? decorativeMotionAllowedListenable;

  @override
  Widget build(BuildContext context) {
    final columns = [cartela.b, cartela.i, cartela.n, cartela.g, cartela.o];

    final cellPulseActive =
        pulseOneAwayCells && (oneAwayCellIndexes?.isNotEmpty ?? false);

    return _OneAwayCellPulseHost(
      active: cellPulseActive,
      motionAllowedListenable: decorativeMotionAllowedListenable,
      builder: (oneAwayPulseT) {
        if (expandToFill) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: _buildBoardCard(
                  context: context,
                  columns: columns,
                  expanded: true,
                  oneAwayPulseT: oneAwayPulseT,
                ),
              );
            },
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _buildBoardCard(
              context: context,
              columns: columns,
              expanded: false,
              oneAwayPulseT: oneAwayPulseT,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardCard({
    required BuildContext context,
    required List<List<String>> columns,
    required bool expanded,
    required double oneAwayPulseT,
  }) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isWinner ? 6 : 0,
      margin: EdgeInsets.zero,
      color: theme.brightness == Brightness.dark ? null : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isWinner
              ? AppBranding.gold
              : isBlocked
              ? theme.colorScheme.error
              : (theme.brightness == Brightness.dark
                    ? theme.dividerColor.withValues(alpha: 0.2)
                    : Colors.transparent),
          width: isWinner ? 2.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (showHeader) _buildCartelaHeader(context),
          if (expanded)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CartelaBoardLayout.boardPadding,
                  CartelaBoardLayout.boardPadding,
                  CartelaBoardLayout.boardPadding,
                  0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardWidth = constraints.maxWidth;
                    final designHeight =
                        CartelaBoardLayout.liveBingoLetterRowHeight +
                        boardWidth;

                    return FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: boardWidth,
                        height: designHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height:
                                  CartelaBoardLayout.liveBingoLetterRowHeight,
                              child: _buildBingoLetterBar(
                                context,
                                expanded: true,
                              ),
                            ),
                            SizedBox(
                              width: boardWidth,
                              height: boardWidth,
                              child: _buildSquareLiveGrid(
                                context,
                                columns,
                                boardWidth: boardWidth,
                                oneAwayPulseT: oneAwayPulseT,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else ...[
            _buildBingoLetterBar(context, expanded: false),
            Padding(
              padding: const EdgeInsets.all(6),
              child: _buildGrid(context, columns, oneAwayPulseT: oneAwayPulseT),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartelaHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
                '${cartela.number}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ?cardHeaderTrailing,
        ],
      ),
    );
  }

  Widget _buildBingoLetterBar(BuildContext context, {required bool expanded}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: expanded ? 2 : 4),
      color: theme.brightness == Brightness.dark
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final letterFontSize = expanded
              ? math.max(
                  CartelaBoardLayout.liveHeaderFontSize,
                  constraints.maxWidth / 5 * 0.32,
                )
              : 14.0;

          return Row(
            children: ['B', 'I', 'N', 'G', 'O'].map((letter) {
              final colColor = AppBranding.bingoColumnColor(letter);
              return Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    decoration: BoxDecoration(
                      color: colColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: letterFontSize,
                        fontWeight: FontWeight.w900,
                        color: colColor,
                        height: 1.1,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSquareLiveGrid(
    BuildContext context,
    List<List<String>> columns, {
    required double boardWidth,
    required double oneAwayPulseT,
  }) {
    final theme = Theme.of(context);
    final gap = CartelaBoardLayout.liveCellGap;
    final cellSize = CartelaBoardLayout.liveGridCellSlotSize(boardWidth);
    final gridBackground = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65)
        : const Color(0xFFF7F5F0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: gridBackground,
            borderRadius: BorderRadius.circular(
              CartelaBoardLayout.boardBorderRadius,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Column(
              children: List.generate(5, (rowIdx) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: rowIdx == 4 ? 0 : gap),
                    child: Row(
                      children: List.generate(5, (colIdx) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: colIdx == 4 ? 0 : gap,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: cellSize,
                                height: cellSize,
                                child: _buildGridCell(
                                  context: context,
                                  columns: columns,
                                  rowIdx: rowIdx,
                                  colIdx: colIdx,
                                  cellExtent: cellSize,
                                  liveExpanded: true,
                                  oneAwayPulseT: oneAwayPulseT,
                                ),
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
          ),
        ),
        if (!patternOverlay.isEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CartelaPatternProgressPainter(
                  overlay: patternOverlay,
                  gap: gap,
                  cellInset: CartelaBoardLayout.cellPadding,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<List<String>> columns, {
    required double oneAwayPulseT,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: List.generate(5, (colIdx) {
            return Expanded(
              child: Column(
                children: List.generate(5, (rowIdx) {
                  return _buildGridCell(
                    context: context,
                    columns: columns,
                    rowIdx: rowIdx,
                    colIdx: colIdx,
                    oneAwayPulseT: oneAwayPulseT,
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
    );
  }

  Widget _buildGridCell({
    required BuildContext context,
    required List<List<String>> columns,
    required int rowIdx,
    required int colIdx,
    double? cellExtent,
    bool liveExpanded = false,
    double oneAwayPulseT = 0,
  }) {
    final colData = columns[colIdx];
    final cellIndex = (rowIdx * 5) + colIdx;
    final isFreeSpace = colIdx == 2 && rowIdx == 2;
    final rawVal = (colData.length > rowIdx) ? colData[rowIdx] : '';
    final number = isFreeSpace ? 0 : (int.tryParse(rawVal) ?? 0);
    final isMarked =
        isFreeSpace || (number > 0 && markedCells.contains(number));
    final isLastMarked =
        number > 0 && lastMarkedNumber != null && lastMarkedNumber == number;
    final isWinningCell =
        number > 0 && (winningPatternCells?.contains(number) ?? false);
    final isWinningBall =
        number > 0 && winningBallNumber != null && winningBallNumber == number;
    final isOneAway = oneAwayCellIndexes?.contains(cellIndex) ?? false;

    return _buildCell(
      context: context,
      number: number,
      displayLabel: isFreeSpace
          ? 'FREE'
          : (number > 0 ? number.toString() : rawVal),
      isFreeSpace: isFreeSpace,
      isMarked: isMarked,
      isLastMarked: isLastMarked,
      isWinningCell: isWinningCell,
      isWinningBall: isWinningBall,
      isOneAway: isOneAway,
      cellExtent: cellExtent,
      liveExpanded: liveExpanded,
      oneAwayPulseT: oneAwayPulseT,
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required int number,
    required String displayLabel,
    required bool isFreeSpace,
    required bool isMarked,
    required bool isLastMarked,
    required bool isWinningCell,
    required bool isWinningBall,
    required bool isOneAway,
    double? cellExtent,
    bool liveExpanded = false,
    double oneAwayPulseT = 0,
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
          color: AppBranding.bingoFreeGreen.withValues(alpha: 0.38),
          blurRadius: 3.5,
          offset: const Offset(0, 1.5),
        ),
      ];
    } else if (isWinningBall && isWinner) {
      final palette = CartelaMarkColorPalette.forColor(CartelaMarkColor.yellow);
      fillColor = palette.fill;
      borderColor = palette.border;
      textColor = palette.text;
      shadows = [
        BoxShadow(
          color: palette.shadow.withValues(alpha: 0.65),
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
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isWinningCell && !isWinner) {
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
      final t = pulseOneAwayCells ? oneAwayPulseT : 0.0;
      fillColor = AppBranding.oneAwayRedFill(t);
      borderColor = AppBranding.oneAwayRedBorder(t);
      textColor = AppBranding.oneAwayRed;
      shadows = [
        BoxShadow(
          color: AppBranding.oneAwayRedShadow(t),
          blurRadius: 6 + t * 8,
          spreadRadius: 0.5 + t * 1.4,
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
          color: palette.shadow.withValues(alpha: 0.38),
          blurRadius: 3.5,
          offset: const Offset(0, 1.5),
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

    final padding = cellExtent != null ? CartelaBoardLayout.cellPadding : 2.0;
    final borderRadius = cellExtent != null
        ? math.max(4.0, cellExtent * 0.16)
        : 6.0;
    final numberFontSize = cellExtent != null
        ? (liveExpanded
              ? CartelaBoardLayout.liveExpandedCellNumberFontSize(cellExtent)
              : CartelaBoardLayout.maximizedCellNumberFontSize(cellExtent))
        : (isFreeSpace ? 11.0 : 16.0);
    final freeFontSize = cellExtent != null
        ? math.max(8.0, cellExtent * (liveExpanded ? 0.24 : 0.28))
        : 11.0;

    final cellBody = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            (interactive && !isFreeSpace && onCellTapped != null && number > 0)
            ? () => onCellTapped!(number)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: isOneAway && pulseOneAwayCells ? 0 : 200,
          ),
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: isOneAway && pulseOneAwayCells
                  ? 1.0 + oneAwayPulseT * 1.4
                  : (isWinningBall || isLastMarked ? 2.0 : 1.0),
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
                    fontSize: isFreeSpace ? freeFontSize : numberFontSize,
                    fontWeight:
                        (isMarked ||
                            isWinningCell ||
                            isWinningBall ||
                            isFreeSpace)
                        ? FontWeight.w900
                        : FontWeight.w700,
                    color: textColor,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (cellExtent != null) {
      return Padding(padding: EdgeInsets.all(padding), child: cellBody);
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: AspectRatio(aspectRatio: 1.0, child: cellBody),
    );
  }
}

class _OneAwayCellPulseHost extends StatefulWidget {
  const _OneAwayCellPulseHost({
    required this.active,
    required this.builder,
    this.motionAllowedListenable,
  });

  final bool active;
  final Widget Function(double pulseT) builder;
  final ValueListenable<bool>? motionAllowedListenable;

  @override
  State<_OneAwayCellPulseHost> createState() => _OneAwayCellPulseHostState();
}

class _OneAwayCellPulseHostState extends State<_OneAwayCellPulseHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    widget.motionAllowedListenable?.addListener(_syncAnimation);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _OneAwayCellPulseHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionAllowedListenable != widget.motionAllowedListenable) {
      oldWidget.motionAllowedListenable?.removeListener(_syncAnimation);
      widget.motionAllowedListenable?.addListener(_syncAnimation);
    }
    if (oldWidget.active != widget.active ||
        oldWidget.motionAllowedListenable != widget.motionAllowedListenable) {
      _syncAnimation();
    }
  }

  bool get _motionAllowed => widget.motionAllowedListenable?.value ?? true;

  void _syncAnimation() {
    if (!mounted) {
      return;
    }
    final shouldPulse = widget.active && _motionAllowed;
    if (shouldPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
      setState(() {});
      return;
    }
    _controller
      ..stop()
      ..value = 0;
    setState(() {});
  }

  @override
  void dispose() {
    widget.motionAllowedListenable?.removeListener(_syncAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || !_motionAllowed) {
      return widget.builder(0);
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => widget.builder(_pulse.value),
    );
  }
}
