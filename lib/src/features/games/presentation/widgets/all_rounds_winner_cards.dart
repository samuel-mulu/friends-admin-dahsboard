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
          _RoundWinnerPager(
            cards: cards,
            onOpen: (card) => _openWinnerDialog(context, card),
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

/// One page per round. The "ዙር X ከ Y" label follows the page in view.
class _RoundWinnerPager extends StatefulWidget {
  const _RoundWinnerPager({required this.cards, required this.onOpen});

  final List<AllRoundsWinnerCardData> cards;
  final ValueChanged<AllRoundsWinnerCardData> onOpen;

  @override
  State<_RoundWinnerPager> createState() => _RoundWinnerPagerState();
}

class _RoundWinnerPagerState extends State<_RoundWinnerPager> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant _RoundWinnerPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = _groupByRound(widget.cards).length;
    if (count == 0) {
      return;
    }
    if (_index >= count) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rounds = _groupByRound(widget.cards);
    if (rounds.isEmpty) {
      return const SizedBox.shrink();
    }

    final index = _index.clamp(0, rounds.length - 1);
    final current = rounds[index].first;
    final multiple = rounds.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.chainRoundOfTotal(current.roundIndex, current.roundCount),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (multiple)
              _RoundDots(
                count: rounds.length,
                index: index,
                onSelected: (next) {
                  _controller.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 88,
          child: PageView.builder(
            controller: _controller,
            itemCount: rounds.length,
            onPageChanged: (next) {
              if (_index == next) {
                return;
              }
              setState(() => _index = next);
            },
            itemBuilder: (context, page) {
              final roundCards = rounds[page];
              return _RoundWinnerRow(
                cards: roundCards,
                onOpen: widget.onOpen,
              );
            },
          ),
        ),
      ],
    );
  }
}

List<List<AllRoundsWinnerCardData>> _groupByRound(
  List<AllRoundsWinnerCardData> cards,
) {
  final groups = <int, List<AllRoundsWinnerCardData>>{};
  final order = <int>[];
  for (final card in cards) {
    final existing = groups[card.roundIndex];
    if (existing == null) {
      order.add(card.roundIndex);
      groups[card.roundIndex] = [card];
    } else {
      existing.add(card);
    }
  }
  return [for (final roundIndex in order) groups[roundIndex]!];
}

class _RoundDots extends StatelessWidget {
  const _RoundDots({
    required this.count,
    required this.index,
    required this.onSelected,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () => onSelected(i),
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == index ? 14 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundWinnerRow extends StatelessWidget {
  const _RoundWinnerRow({required this.cards, required this.onOpen});

  final List<AllRoundsWinnerCardData> cards;
  final ValueChanged<AllRoundsWinnerCardData> onOpen;

  @override
  Widget build(BuildContext context) {
    if (cards.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 240,
          child: _AllRoundsWinnerCard(
            card: cards.first,
            onTap: _tapFor(cards.first),
          ),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _AllRoundsWinnerCard(
              card: cards[i],
              expand: true,
              onTap: _tapFor(cards[i]),
            ),
          ),
        ],
      ],
    );
  }

  VoidCallback? _tapFor(AllRoundsWinnerCardData card) {
    if (card.isNoWinner || card.winnerResults.isEmpty) {
      return null;
    }
    return () => onOpen(card);
  }
}

class _AllRoundsWinnerCard extends StatelessWidget {
  const _AllRoundsWinnerCard({
    required this.card,
    this.expand = false,
    this.onTap,
  });

  final AllRoundsWinnerCardData card;
  final bool expand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    // Brand gold washes out on the cream summary panel. Keep the gold hue,
    // but use a darker tone so cartela, amount, and phone stay readable.
    final goldText = isDark ? AppBranding.gold : const Color(0xFF6E5210);
    final goldBorder = isDark ? AppBranding.gold : const Color(0xFF8C6914);
    final goldFill = isDark
        ? AppBranding.liveCardDark
        : (card.isMine ? const Color(0xFFFFE7A8) : const Color(0xFFFFF3D4));
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
      color: card.isNoWinner ? AppBranding.panelBackground(context) : goldFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: expand ? double.infinity : null,
          constraints: expand
              ? null
              : const BoxConstraints(minWidth: 140, maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: card.isNoWinner
                  ? theme.colorScheme.outlineVariant
                  : goldBorder,
              width: card.isMine ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: card.isNoWinner
                      ? theme.colorScheme.onSurfaceVariant
                      : goldText,
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
