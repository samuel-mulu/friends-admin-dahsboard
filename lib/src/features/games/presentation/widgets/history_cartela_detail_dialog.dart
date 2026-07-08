import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
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
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _HistoryCartelaDetailDialog(
        cartela: cartela,
        winnerResult: winnerResult,
      );
    },
  );
}

class _HistoryCartelaDetailDialog extends StatelessWidget {
  const _HistoryCartelaDetailDialog({
    required this.cartela,
    required this.winnerResult,
  });

  final GameCartelaModel cartela;
  final SessionWinnerResultModel? winnerResult;

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
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
