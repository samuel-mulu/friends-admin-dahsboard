import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/session_winner_result_model.dart';
import '../utils/round_winner_history_adapters.dart';
import 'winner_cartela_dialog.dart';

/// Read-only final-summary section: winning cartelas grouped by round.
///
/// Does not own game lifecycle. Opens the existing [showWinnerCartelaDialog]
/// with the historical winnerResults supplied by the caller.
class AllRoundsWinnerCards extends StatelessWidget {
  const AllRoundsWinnerCards({
    required this.cards,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final List<AllRoundsWinnerCardData> cards;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.allRoundsWinnersTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (isLoading)
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.gameResultsLoading,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          )
        else if (errorMessage != null && errorMessage!.trim().isNotEmpty)
          Text(
            errorMessage!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else if (cards.isEmpty)
          Text(
            l10n.sessionResultsNoWinners,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final card in cards)
                _AllRoundsWinnerCard(
                  card: card,
                  onTap: card.isNoWinner || card.winnerResults.isEmpty
                      ? null
                      : () => _openWinnerDialog(context, card),
                ),
            ],
          ),
      ],
    );
  }

  void _openWinnerDialog(BuildContext context, AllRoundsWinnerCardData card) {
    final selectedId = card.selectedGameCartelaId;
    final ordered = <SessionWinnerResultModel>[
      ...card.winnerResults.where((r) => r.gameCartelaId == selectedId),
      ...card.winnerResults.where((r) => r.gameCartelaId != selectedId),
    ];
    if (ordered.isEmpty) {
      return;
    }

    showWinnerCartelaDialog(
      context: context,
      results: ordered,
      roundIndex: card.roundIndex,
      roundCount: card.roundCount,
    );
  }
}

class _AllRoundsWinnerCard extends StatelessWidget {
  const _AllRoundsWinnerCard({required this.card, this.onTap});

  final AllRoundsWinnerCardData card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final gold = theme.brightness == Brightness.dark
        ? AppBranding.gold
        : AppBranding.goldDark;
    final canTap = onTap != null;

    final subtitle = card.isNoWinner
        ? l10n.sessionResultsNoWinners
        : [
            if (card.cartelaNumber != null)
              l10n.reviewModeWinnerCartela(card.cartelaNumber!),
            if (card.amount != null && card.amount!.isNotEmpty) card.amount!,
            if (card.phoneNumber != null && card.phoneNumber!.trim().isNotEmpty)
              card.phoneNumber!,
          ].join(' · ');

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (card.isMine ? gold : theme.colorScheme.outlineVariant)
                  .withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chainRoundOfTotal(card.roundIndex, card.roundCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: card.isNoWinner
                      ? theme.colorScheme.onSurfaceVariant
                      : gold,
                  decoration: card.isNoWinner
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              if (canTap) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.allRoundsWinnersViewCartela,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
