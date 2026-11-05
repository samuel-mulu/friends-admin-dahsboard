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
    this.hasError = false,
    this.onRetry,
    super.key,
  });

  final List<AllRoundsWinnerCardData> cards;
  final bool isLoading;

  /// Load failed; shows a friendly message (never the raw error) + [onRetry].
  final bool hasError;
  final VoidCallback? onRetry;

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
        else if (hasError)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.allRoundsWinnersLoadFailed,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.allRoundsWinnersRetry),
                ),
            ],
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

/// One page per round, rounds in ascending order. Opens on the LAST round;
/// the player swipes right (or taps a dot) to see earlier rounds. The
/// "ዙር X ከ Y" label follows the page in view.
class _RoundWinnerPager extends StatefulWidget {
  const _RoundWinnerPager({required this.cards, required this.onOpen});

  final List<AllRoundsWinnerCardData> cards;
  final ValueChanged<AllRoundsWinnerCardData> onOpen;

  @override
  State<_RoundWinnerPager> createState() => _RoundWinnerPagerState();
}

class _RoundWinnerPagerState extends State<_RoundWinnerPager> {
  late List<List<AllRoundsWinnerCardData>> _rounds;
  late final PageController _controller;
  late int _index;

  /// Set once the player swipes or taps a dot. Until then a data refresh keeps
  /// the pager on the last round; afterwards it keeps the player's page.
  bool _userNavigated = false;
  bool _pageHandoffArmed = true;

  int get _lastIndex => _rounds.isEmpty ? 0 : _rounds.length - 1;

  @override
  void initState() {
    super.initState();
    _rounds = _groupByRound(widget.cards);
    _index = _lastIndex;
    _controller = PageController(initialPage: _index);
  }

  void _goToPage(int page) {
    _userNavigated = true;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  /// A sideways drag on a multi-winner row scrolls those cards. Once that row
  /// is at its end, the same drag moves to the next round so round paging
  /// still works.
  void _onCardScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _pageHandoffArmed = true;
      return;
    }
    if (notification is! OverscrollNotification ||
        notification.metrics.axis != Axis.horizontal ||
        notification.dragDetails == null ||
        !_pageHandoffArmed ||
        notification.overscroll.abs() < 8) {
      return;
    }

    final next = notification.overscroll > 0 ? _index + 1 : _index - 1;
    if (next < 0 || next >= _rounds.length || !_controller.hasClients) {
      return;
    }
    _pageHandoffArmed = false;
    _goToPage(next);
  }

  /// Marks a direct drag on the round pager itself (depth 0) as navigation.
  bool _onPagerScrollStart(ScrollStartNotification notification) {
    if (notification.depth == 0 && notification.dragDetails != null) {
      _userNavigated = true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant _RoundWinnerPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cards, widget.cards)) {
      _rounds = _groupByRound(widget.cards);
    }
    if (_rounds.isEmpty) {
      return;
    }
    final target = _userNavigated ? _index.clamp(0, _lastIndex) : _lastIndex;
    if (target == _index) {
      return;
    }
    _index = target;
    // Jump after this frame: moving the page fires onPageChanged → setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) {
        _controller.jumpToPage(_index);
      }
    });
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
    final rounds = _rounds;
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
                onSelected: _goToPage,
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: _onPagerScrollStart,
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
                  onCardScroll: _onCardScroll,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Cards grouped per round, rounds ascending (so the last page = last round).
/// Card order inside a round is kept as delivered.
List<List<AllRoundsWinnerCardData>> _groupByRound(
  List<AllRoundsWinnerCardData> cards,
) {
  final groups = <int, List<AllRoundsWinnerCardData>>{};
  for (final card in cards) {
    groups.putIfAbsent(card.roundIndex, () => []).add(card);
  }
  final roundIndexes = groups.keys.toList()..sort();
  return [for (final roundIndex in roundIndexes) groups[roundIndex]!];
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

const double _winnerCardWidth = 240;

class _RoundWinnerRow extends StatelessWidget {
  const _RoundWinnerRow({
    required this.cards,
    required this.onOpen,
    this.onCardScroll,
  });

  final List<AllRoundsWinnerCardData> cards;
  final ValueChanged<AllRoundsWinnerCardData> onOpen;
  final void Function(ScrollNotification notification)? onCardScroll;

  @override
  Widget build(BuildContext context) {
    if (cards.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _winnerCard(cards.first),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        onCardScroll?.call(notification);
        return false;
      },
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: _winnerCard(cards[index]),
          );
        },
      ),
    );
  }

  Widget _winnerCard(AllRoundsWinnerCardData card) {
    return SizedBox(
      width: _winnerCardWidth,
      child: _AllRoundsWinnerCard(
        card: card,
        onTap: _tapFor(card),
      ),
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
  const _AllRoundsWinnerCard({required this.card, this.onTap});

  final AllRoundsWinnerCardData card;
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  height: 1.35,
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
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.allRoundsWinnersViewCartela,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
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
