import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_category_theme.dart';

/// Always-on Chain Game header: which round is playing, what this round pays,
/// and the whole-chain pool. Tapping opens the full round ladder.
class ChainGameInfoStrip extends StatelessWidget {
  const ChainGameInfoStrip({
    required this.roundIndex,
    required this.roundCount,
    required this.thisRoundPrize,
    required this.totalPrize,
    this.roundPrizes,
    this.showAllRoundPrizes = false,
    this.patternName,
    this.onTap,
    super.key,
  });

  final int roundIndex;
  final int roundCount;
  final String thisRoundPrize;
  final String totalPrize;
  final List<String>? roundPrizes;
  final bool showAllRoundPrizes;
  final String? patternName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.chainGame,
      isDark: theme.brightness == Brightness.dark,
    );
    final prizes = roundPrizes ?? const <String>[];
    final listAllRounds = showAllRoundPrizes && prizes.length > 1;

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.link_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.chainRoundOfTotal(roundIndex, roundCount),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        if (patternName != null &&
                            patternName!.trim().isNotEmpty)
                          Text(
                            patternName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PrizeColumn(
                    label: l10n.chainRoundThisRoundPrize,
                    value: formatMoney(thisRoundPrize),
                    emphasized: true,
                  ),
                  const SizedBox(width: 12),
                  _PrizeColumn(
                    label: l10n.chainRoundTotalPrize,
                    value: formatMoney(totalPrize),
                    emphasized: false,
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              if (listAllRounds) ...[
                const SizedBox(height: 8),
                ChainRoundPrizeChips(roundPrizes: prizes),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact "Round N Prize: amount" chips — used at registration so every
/// chain round is visible without opening the ladder dialog.
class ChainRoundPrizeChips extends StatelessWidget {
  const ChainRoundPrizeChips({
    required this.roundPrizes,
    super.key,
  });

  final List<String> roundPrizes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var i = 0; i < roundPrizes.length; i++)
          Text(
            '${l10n.bigGameRoundPrize(i + 1)}: ${formatMoney(roundPrizes[i])}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _PrizeColumn extends StatelessWidget {
  const _PrizeColumn({
    required this.label,
    required this.value,
    required this.emphasized,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            color: emphasized
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
