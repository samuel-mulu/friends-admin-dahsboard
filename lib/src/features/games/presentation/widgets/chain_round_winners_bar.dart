import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_category_theme.dart';
import '../utils/chain_round_cartela_state.dart';

/// Past Chain Game round winners, pinned under the board for the whole session.
/// Stays visible while later rounds play so players can see who already won.
class ChainRoundWinnersBar extends StatelessWidget {
  const ChainRoundWinnersBar({
    required this.roundResults,
    required this.roundCount,
    this.myCartelaNumbers = const {},
    this.onTap,
    super.key,
  });

  final List<ChainRoundResultSummary> roundResults;
  final int roundCount;
  final Set<int> myCartelaNumbers;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decided = condensedChainRoundResultsForBar(
      roundResults: roundResults,
      roundCount: roundCount,
    );
    if (decided.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.chainGame,
      isDark: theme.brightness == Brightness.dark,
    );
    final chips = _chips(decided);

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                l10n.chainRoundWinnersTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final chip = chips[index];
                      final isMine = myCartelaNumbers.contains(chip.cartela);
                      final mineGold = theme.brightness == Brightness.dark
                          ? AppBranding.gold
                          : AppBranding.goldDark;
                      return _WinnerChip(
                        label: l10n.chainRoundWinnerChip(
                          chip.round,
                          chip.cartela,
                        ),
                        accent: isMine ? mineGold : accent,
                        emphasized: isMine,
                      );
                    },
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static List<_ChainWinnerChipData> _chips(
    List<ChainRoundResultSummary> decided,
  ) {
    return [
      for (final round in decided)
        for (final winner in round.winners)
          _ChainWinnerChipData(
            round: round.roundIndex,
            cartela: winner.cartelaNumber,
          ),
    ];
  }
}

class _ChainWinnerChipData {
  const _ChainWinnerChipData({required this.round, required this.cartela});

  final int round;
  final int cartela;
}

class _WinnerChip extends StatelessWidget {
  const _WinnerChip({
    required this.label,
    required this.accent,
    required this.emphasized,
  });

  final String label;
  final Color accent;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: emphasized ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}
