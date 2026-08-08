import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../utils/cartela_pattern_progress_overlay.dart';
import '../utils/cartela_board_layout.dart';
import 'cartela_board_preview.dart';
import 'winning_pattern_cartela_grid.dart';

Future<void> showHistoryCartelaDetailDialog({
  required BuildContext context,
  required GameCartelaModel cartela,
  SessionWinnerResultModel? winnerResult,
  List<CalledNumberModel> calledNumbers = const [],
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _HistoryCartelaDetailDialog(
        cartela: cartela,
        winnerResult: winnerResult,
        calledNumbers: calledNumbers,
      );
    },
  );
}

class _HistoryCartelaDetailDialog extends StatelessWidget {
  const _HistoryCartelaDetailDialog({
    required this.cartela,
    required this.winnerResult,
    required this.calledNumbers,
  });

  final GameCartelaModel cartela;
  final SessionWinnerResultModel? winnerResult;
  final List<CalledNumberModel> calledNumbers;

  String _statusLabel() {
    if (cartela.isWinner) {
      return 'Winner';
    }
    if (cartela.status == GameCartelaStatus.blocked) {
      return 'Blocked';
    }
    return cartela.status.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final winnerResult = this.winnerResult;
    final orderedCalls = List<CalledNumberModel>.from(calledNumbers)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.winningCartelasDetailTitle(cartela.cartela.number),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                _statusLabel(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cartela.status == GameCartelaStatus.blocked
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (cartela.status == GameCartelaStatus.blocked) ...[
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cartela.blockReason != null &&
                            cartela.blockReason!.trim().isNotEmpty) ...[
                          Text(
                            cartela.blockReason!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (cartela.activeNumberWhenBlocked != null)
                            const SizedBox(height: 6),
                        ],
                        if (cartela.activeNumberWhenBlocked != null)
                          Text(
                            'Active number: ${cartela.activeNumberWhenBlocked!.displayBall}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (winnerResult != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.winningCartelasPrize(formatMoney(winnerResult.amount)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (winnerResult.displayWinningBallLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.winningCartelasWinningBall(
                      winnerResult.displayWinningBallLabel!,
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
              if (orderedCalls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.liveCalledNumbersLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _HistoryCalledNumbersScroller(calledNumbers: orderedCalls),
              ],
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: CartelaBoardLayout.reviewBoardAspectRatio,
                child: winnerResult != null
                    ? WinningPatternCartelaGrid(
                        columns: winnerResult.columns,
                        highlightCellIndexes:
                            winnerResult.highlightCellIndexes,
                        patternOverlay:
                            CartelaPatternProgressOverlay.fromCompletedPatterns(
                              winnerResult.completedPatterns,
                            ),
                        winningBallCellIndex:
                            winnerResult.resolvedWinningBallCellIndex,
                      )
                    : CartelaBoardPreview(columns: cartela.cartela.columns),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCalledNumbersScroller extends StatelessWidget {
  const _HistoryCalledNumbersScroller({required this.calledNumbers});

  final List<CalledNumberModel> calledNumbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestOrder = calledNumbers.isEmpty
        ? null
        : calledNumbers.last.order;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppBranding.panelBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBranding.panelBorder(context)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: calledNumbers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final call = calledNumbers[index];
          final isLatest = call.order == latestOrder;
          return _HistoryCalledBallChip(
            label: call.displayValue,
            isLatest: isLatest,
            theme: theme,
          );
        },
      ),
    );
  }
}

class _HistoryCalledBallChip extends StatelessWidget {
  const _HistoryCalledBallChip({
    required this.label,
    required this.isLatest,
    required this.theme,
  });

  final String label;
  final bool isLatest;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLatest
            ? AppBranding.gold.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isLatest
              ? AppBranding.gold
              : theme.colorScheme.outlineVariant,
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: isLatest
              ? AppBranding.brandPurple
              : theme.colorScheme.onSurface,
          fontSize: 10,
        ),
      ),
    );
  }
}
