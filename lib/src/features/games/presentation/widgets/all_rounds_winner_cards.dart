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

  static List<_RoundWinnerGroup> _groupCardsByRound(
    List<AllRoundsWinnerCardData> cards,
  ) {
    final byRound = <int, List<AllRoundsWinnerCardData>>{};
    for (final card in cards) {
      byRound.putIfAbsent(card.roundIndex, () => []).add(card);
    }
    final roundIndexes = byRound.keys.toList()..sort();
    return [
      for (final roundIndex in roundIndexes)
        _RoundWinnerGroup(
          roundIndex: roundIndex,
          roundCount: byRound[roundIndex]!.first.roundCount,
          cards: byRound[roundIndex]!,
        ),
    ];
  }

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
          _AllRoundsWinnersByRound(
            groups: _groupCardsByRound(cards),
            onCardTap: (card) => _openWinnerDialog(context, card),
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

class _RoundWinnerGroup {
  const _RoundWinnerGroup({
    required this.roundIndex,
    required this.roundCount,
    required this.cards,
  });

  final int roundIndex;
  final int roundCount;
  final List<AllRoundsWinnerCardData> cards;
}

class _AllRoundsWinnersByRound extends StatelessWidget {
  const _AllRoundsWinnersByRound({
    required this.groups,
    required this.onCardTap,
  });

  final List<_RoundWinnerGroup> groups;
  final void Function(AllRoundsWinnerCardData card) onCardTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _AllRoundsWinnerRoundRow(
            group: groups[i],
            onCardTap: onCardTap,
          ),
        ],
      ],
    );
  }
}

class _AllRoundsWinnerRoundRow extends StatelessWidget {
  const _AllRoundsWinnerRoundRow({
    required this.group,
    required this.onCardTap,
  });

  final _RoundWinnerGroup group;
  final void Function(AllRoundsWinnerCardData card) onCardTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            l10n.chainRoundOfTotal(group.roundIndex, group.roundCount),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final card = group.cards[index];
                return _AllRoundsWinnerCard(
                  card: card,
                  compact: true,
                  showRoundLabel: false,
                  onTap: card.isNoWinner || card.winnerResults.isEmpty
                      ? null
                      : () => onCardTap(card),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AllRoundsWinnerCard extends StatelessWidget {
  const _AllRoundsWinnerCard({
    required this.card,
    this.onTap,
    this.compact = false,
    this.showRoundLabel = true,
  });

  final AllRoundsWinnerCardData card;
  final VoidCallback? onTap;
  final bool compact;
  final bool showRoundLabel;

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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRoundLabel) ...[
          Text(
            l10n.chainRoundOfTotal(card.roundIndex, card.roundCount),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: card.isNoWinner
                ? theme.colorScheme.onSurfaceVariant
                : gold,
            decoration:
                card.isNoWinner ? TextDecoration.lineThrough : null,
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
              Flexible(
                child: Text(
                  l10n.allRoundsWinnersViewCartela,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: compact ? 132 : null,
          constraints: compact
              ? null
              : const BoxConstraints(minWidth: 120, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (card.isMine ? gold : theme.colorScheme.outlineVariant)
                  .withValues(alpha: 0.7),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
