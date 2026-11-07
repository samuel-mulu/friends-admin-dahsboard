import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_pattern_progress_overlay.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_board_layout.dart';

import 'cartela_number_badge.dart';
import 'live_cartela_card.dart';

/// Lightweight, read-only summary of the player's registered cartela numbers
/// (sorted). Used while the game is preparing and as the never-blank fallback
/// in the live body — never as the play surface (no marking, no BINGO).
///
/// [scrollable] wraps it in a scroll view for bounded parents (e.g. inside
/// `Expanded`); leave it false inside an already-scrolling list.
class RegisteredCartelaNumbersSummary extends StatelessWidget {
  const RegisteredCartelaNumbersSummary({
    required this.cartelas,
    this.scrollable = false,
    super.key,
  });

  final List<GameCartelaModel> cartelas;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final sorted = [...cartelas]
      ..sort((a, b) => a.cartela.number.compareTo(b.cartela.number));
    final chips = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final gameCartela in sorted)
          CartelaNumberCompactBadge(
            key: ValueKey(gameCartela.id),
            number: gameCartela.cartela.number,
            isBlocked: gameCartela.status == GameCartelaStatus.blocked,
          ),
      ],
    );

    if (!scrollable) {
      return chips;
    }
    return SingleChildScrollView(child: chips);
  }
}

class InlineRegisteredCartelaList extends StatelessWidget {
  const InlineRegisteredCartelaList({
    required this.cartelas,
    required this.sortResultsByCartelaId,
    required this.canClaimBingoFor,
    required this.claimingCartelaIds,
    required this.pendingClaimCartelaIds,
    required this.showPendingClaimState,
    required this.showFinishedOutcome,
    required this.freezeCartelaMarks,
    required this.manualMarkedNumbers,
    this.lastManualMarkedKey,
    required this.markedNumbersFor,
    required this.sortResultFor,
    required this.winningPatternCellsByGameCartelaId,
    required this.winningPatternOverlayByGameCartelaId,
    required this.winningBallCellIndexByGameCartelaId,
    required this.prizeAmountFor,
    required this.onMarkedNumberToggled,
    required this.onClaimBingo,
    required this.blockedReasonCodeFor,
    required this.blockedServerReasonFor,
    this.onReorder,
    this.decorativeMotionAllowedListenable,
    super.key,
  });

  final List<GameCartelaModel> cartelas;
  final Map<String, CartelaPatternUiResult> sortResultsByCartelaId;
  final bool Function(GameCartelaModel) canClaimBingoFor;
  final Set<String> claimingCartelaIds;
  final Set<String> pendingClaimCartelaIds;
  final bool showPendingClaimState;
  final bool showFinishedOutcome;
  final bool freezeCartelaMarks;
  final Set<String> manualMarkedNumbers;
  final String? lastManualMarkedKey;
  final Set<String> Function(GameCartelaModel) markedNumbersFor;
  final CartelaPatternUiResult? Function(GameCartelaModel) sortResultFor;
  final Map<String, Set<int>> winningPatternCellsByGameCartelaId;
  final Map<String, CartelaPatternProgressOverlay>
      winningPatternOverlayByGameCartelaId;
  final Map<String, int> winningBallCellIndexByGameCartelaId;
  final String? Function(GameCartelaModel cartela) prizeAmountFor;
  final void Function(GameCartelaModel cartela, String header, String value)
      onMarkedNumberToggled;
  final Future<void> Function(GameCartelaModel) onClaimBingo;
  final String? Function(GameCartelaModel) blockedReasonCodeFor;
  final String? Function(GameCartelaModel) blockedServerReasonFor;
  final void Function(int fromIndex, int toIndex)? onReorder;
  final ValueListenable<bool>? decorativeMotionAllowedListenable;

  Widget _buildCartelaCard({
    required GameCartelaModel gameCartela,
    required CartelaPatternUiResult? sortResult,
    required CartelaPatternProgressOverlay storedWinnerOverlay,
    required bool useStoredWinnerOverlay,
    required Set<int> storedWinnerHighlights,
    required Set<int> winningHighlightCells,
  }) {
    return LiveCartelaCard(
      key: ValueKey(gameCartela.id),
      gameCartela: gameCartela,
      canClaimBingo: canClaimBingoFor(gameCartela),
      isClaiming: claimingCartelaIds.contains(gameCartela.id),
      pendingReview:
          showPendingClaimState &&
          (pendingClaimCartelaIds.contains(gameCartela.id) ||
              claimingCartelaIds.contains(gameCartela.id)),
      showFinishedOutcome: showFinishedOutcome,
      freezeCartelaMarks: freezeCartelaMarks,
      isOneAwayFromWin: sortResult?.isOneAway ?? false,
      hasLocalPatternComplete: sortResult?.hasLocalPatternComplete ?? false,
      isLateClaim: sortResult?.isLateClaim ?? false,
      oneAwayCellIndexes: sortResult?.oneAwayCellIndexes ?? const {},
      winningPatternOverlay: useStoredWinnerOverlay
          ? storedWinnerOverlay
          : sortResult?.completedPatternOverlay ??
                const CartelaPatternProgressOverlay(),
      winningHighlightCells: winningHighlightCells,
      winningBallCellIndex: gameCartela.isWinner
          ? winningBallCellIndexByGameCartelaId[gameCartela.id]
          : null,
      prizeAmount: prizeAmountFor(gameCartela),
      manualMarkedNumbers: markedNumbersFor(gameCartela),
      lastManualMarkedKey: gameCartela.status == GameCartelaStatus.blocked
          ? null
          : lastManualMarkedKeyForCartela(
              lastManualMarkedKey: lastManualMarkedKey,
              cartela: gameCartela,
            ),
      onMarkedNumberToggled: onMarkedNumberToggled,
      onClaimBingo: () => onClaimBingo(gameCartela),
      blockedReasonCode: blockedReasonCodeFor(gameCartela),
      blockedServerReason: blockedServerReasonFor(gameCartela),
      decorativeMotionAllowedListenable: decorativeMotionAllowedListenable,
    );
  }

  Widget _wrapReorderableCell({
    required BuildContext context,
    required int index,
    required double cellWidth,
    required double cellHeight,
    required Widget card,
  }) {
    final onReorder = this.onReorder;
    final theme = Theme.of(context);
    final wrapped = onReorder == null
        ? card
        : LongPressDraggable<int>(
            data: index,
            delay: const Duration(milliseconds: 400),
            hapticFeedbackOnStart: true,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: cellWidth,
                height: cellHeight,
                child: Opacity(opacity: 0.92, child: card),
              ),
            ),
            childWhenDragging: SizedBox(width: cellWidth, height: cellHeight),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != index,
              onAcceptWithDetails: (details) => onReorder(details.data, index),
              builder: (context, candidateData, rejectedData) {
                final isTarget = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: isTarget
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        )
                      : null,
                  child: card,
                );
              },
            ),
          );

    return KeyedSubtree(
      key: ValueKey('cartela_cell_${cartelas[index].id}'),
      child: wrapped,
    );
  }

  Widget _buildGridItem({
    required BuildContext context,
    required int index,
    required double cellWidth,
    required double cellHeight,
  }) {
    final gameCartela = cartelas[index];
    final sortResult =
        sortResultFor(gameCartela) ?? sortResultsByCartelaId[gameCartela.id];
    final rawStoredWinnerOverlay =
        winningPatternOverlayByGameCartelaId[gameCartela.id];
    final storedWinnerOverlay =
        rawStoredWinnerOverlay ?? const CartelaPatternProgressOverlay();
    final storedWinnerHighlights =
        rawStoredWinnerOverlay != null && !rawStoredWinnerOverlay.isEmpty
            ? rawStoredWinnerOverlay.allOverlayCellIndexes
            : winningPatternCellsByGameCartelaId[gameCartela.id] ??
                const <int>{};
    final winningHighlightCells = {
      ...?sortResult?.completedPatternCells,
      ...storedWinnerHighlights,
    };
    final card = _buildCartelaCard(
      gameCartela: gameCartela,
      sortResult: sortResult,
      storedWinnerOverlay: storedWinnerOverlay,
      useStoredWinnerOverlay:
          rawStoredWinnerOverlay != null && !rawStoredWinnerOverlay.isEmpty,
      storedWinnerHighlights: storedWinnerHighlights,
      winningHighlightCells: winningHighlightCells,
    );

    return _wrapReorderableCell(
      context: context,
      index: index,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      card: card,
    );
  }

  static const _crossAxisSpacing = 6.0;
  static const _mainAxisSpacing = 6.0;

  static double _resolveChildAspectRatio(
    BuildContext context,
    double tileWidth,
  ) {
    var ratio = CartelaBoardLayout.liveTwoUpTileAspectRatio(tileWidth);
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    if (scale > 1.25) {
      ratio *= 0.96;
    } else if (scale > 1.05) {
      ratio *= 0.98;
    }
    return ratio.clamp(0.70, 0.86);
  }

  /// Real scrolling 2-col grid for sticky live play ([CustomScrollView]).
  Widget asSliver({required double crossAxisExtent}) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final safeExtent = crossAxisExtent > 0 ? crossAxisExtent : 1.0;
        final cellWidth = (safeExtent - _crossAxisSpacing) / 2;
        final ratio = _resolveChildAspectRatio(context, cellWidth);
        final cellHeight = cellWidth / ratio;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: _mainAxisSpacing,
            crossAxisSpacing: _crossAxisSpacing,
            childAspectRatio: ratio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGridItem(
              context: context,
              index: index,
              cellWidth: cellWidth,
              cellHeight: cellHeight,
            ),
            childCount: cartelas.length,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nested inside a parent [ListView] (non-sticky layouts only).
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - _crossAxisSpacing) / 2;
        final ratio = _resolveChildAspectRatio(context, cellWidth);
        final cellHeight = cellWidth / ratio;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: _mainAxisSpacing,
            crossAxisSpacing: _crossAxisSpacing,
            childAspectRatio: ratio,
          ),
          itemCount: cartelas.length,
          itemBuilder: (context, index) => _buildGridItem(
            context: context,
            index: index,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
          ),
        );
      },
    );
  }
}
