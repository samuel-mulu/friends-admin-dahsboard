import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_pattern_progress_overlay.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_board_layout.dart';

import 'package:friends_bingo_app/src/features/games/cartelas/application/live_cartela_live_store.dart';

import 'live_cartela_card.dart';
import 'live_cartela_tile.dart';

class RegisteredCartelaList extends StatelessWidget {
  const RegisteredCartelaList({required this.cartelas, super.key});

  final List<GameCartelaModel> cartelas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cartelas
          .map(
            (gameCartela) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: RegisteredCartelaListTile(gameCartela: gameCartela),
            ),
          )
          .toList(growable: false),
    );
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
    this.bingoLockListenable,
    this.decorativeMotionAllowedListenable,
    this.cartelaLiveStore,
    this.cartelaLiveListenable,
    this.liveSortResultFor,
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
  final ValueListenable<bool>? bingoLockListenable;
  final ValueListenable<bool>? decorativeMotionAllowedListenable;
  final LiveCartelaLiveStore? cartelaLiveStore;
  final Listenable? cartelaLiveListenable;
  final CartelaPatternUiResult? Function(GameCartelaModel)?
      liveSortResultFor;

  CartelaPatternUiResult? _resolveSortResult(GameCartelaModel gameCartela) {
    return sortResultFor(gameCartela) ??
        liveSortResultFor?.call(gameCartela) ??
        sortResultsByCartelaId[gameCartela.id];
  }

  Widget _buildCartelaCard({
    required GameCartelaModel gameCartela,
    required CartelaPatternUiResult? sortResult,
    required CartelaPatternProgressOverlay storedWinnerOverlay,
    required bool useStoredWinnerOverlay,
    required Set<int> storedWinnerHighlights,
    required Set<int> winningHighlightCells,
  }) {
    final isBlocked = gameCartela.status == GameCartelaStatus.blocked;
    final isClaiming = claimingCartelaIds.contains(gameCartela.id);
    final lockListenable = bingoLockListenable;

    final card = LiveCartelaCard(
      key: ValueKey(gameCartela.id),
      gameCartela: gameCartela,
      canClaimBingo: canClaimBingoFor(gameCartela),
      isClaiming: isClaiming,
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
      bingoLockListenable: lockListenable,
      resolveCanClaimBingo: lockListenable == null
          ? null
          : () => canClaimBingoFor(gameCartela),
      resolveShowReadyPulse: lockListenable == null
          ? null
          : () {
              final liveSort = _resolveSortResult(gameCartela);
              return (liveSort?.hasLocalPatternComplete ?? false) &&
                  !(liveSort?.isLateClaim ?? false) &&
                  canClaimBingoFor(gameCartela) &&
                  !isClaiming &&
                  !isBlocked &&
                  !showFinishedOutcome;
            },
      decorativeMotionAllowedListenable: decorativeMotionAllowedListenable,
    );

    return card;
  }

  Widget _buildCartelaCardForGrid({
    required GameCartelaModel gameCartela,
    required CartelaPatternProgressOverlay storedWinnerOverlay,
    required bool useStoredWinnerOverlay,
    required Set<int> storedWinnerHighlights,
  }) {
    final sortResult = _resolveSortResult(gameCartela);
    final winningHighlightCells = {
      ...?sortResult?.completedPatternCells,
      ...storedWinnerHighlights,
    };
    return _buildCartelaCard(
      gameCartela: gameCartela,
      sortResult: sortResult,
      storedWinnerOverlay: storedWinnerOverlay,
      useStoredWinnerOverlay: useStoredWinnerOverlay,
      storedWinnerHighlights: storedWinnerHighlights,
      winningHighlightCells: winningHighlightCells,
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
    final rawStoredWinnerOverlay =
        winningPatternOverlayByGameCartelaId[gameCartela.id];
    final storedWinnerOverlay =
        rawStoredWinnerOverlay ?? const CartelaPatternProgressOverlay();
    final storedWinnerHighlights =
        rawStoredWinnerOverlay != null && !rawStoredWinnerOverlay.isEmpty
            ? rawStoredWinnerOverlay.allOverlayCellIndexes
            : winningPatternCellsByGameCartelaId[gameCartela.id] ??
                const <int>{};
    final store = cartelaLiveStore;
    final liveListenable = cartelaLiveListenable;
    final Widget card;
    if (store != null && liveListenable != null) {
      card = LiveCartelaTile(
        key: ValueKey('tile_${gameCartela.id}'),
        gameCartelaId: gameCartela.id,
        store: store,
        liveListenable: liveListenable,
        builder: (_) => _buildCartelaCardForGrid(
          gameCartela: gameCartela,
          storedWinnerOverlay: storedWinnerOverlay,
          useStoredWinnerOverlay:
              rawStoredWinnerOverlay != null && !rawStoredWinnerOverlay.isEmpty,
          storedWinnerHighlights: storedWinnerHighlights,
        ),
      );
    } else {
      card = _buildCartelaCardForGrid(
        gameCartela: gameCartela,
        storedWinnerOverlay: storedWinnerOverlay,
        useStoredWinnerOverlay:
            rawStoredWinnerOverlay != null && !rawStoredWinnerOverlay.isEmpty,
        storedWinnerHighlights: storedWinnerHighlights,
      );
    }

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

class RegisteredCartelaListTile extends StatelessWidget {
  const RegisteredCartelaListTile({required this.gameCartela, super.key});

  final GameCartelaModel gameCartela;

  static ({Color background, Color foreground}) _statusColors(
    ThemeData theme,
    GameCartelaStatus status,
  ) {
    return switch (status) {
      GameCartelaStatus.registered => (
        background: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.onPrimaryContainer,
      ),
      GameCartelaStatus.winner => (
        background: const Color(0xFFE8F5E9),
        foreground: const Color(0xFF2E7D32),
      ),
      GameCartelaStatus.blocked => (
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      ),
      GameCartelaStatus.cancelled => (
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = _statusColors(theme, gameCartela.status);
    final statusLabel = gameCartela.isWinner
        ? 'Winner'
        : gameCartela.status == GameCartelaStatus.blocked
        ? 'Blocked / Invalid Bingo'
        : gameCartela.status.label;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${gameCartela.cartela.number}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartela ${gameCartela.cartela.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
