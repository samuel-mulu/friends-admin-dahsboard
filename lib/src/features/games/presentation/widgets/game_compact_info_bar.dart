import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/game_model.dart';

class GameCompactInfoBar extends StatelessWidget {
  const GameCompactInfoBar({required this.game, super.key});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppBranding.casinoPurple.withValues(alpha: 0.55),
                        AppBranding.casinoPurpleDeep.withValues(alpha: 0.4),
                      ]
                    : [
                        AppBranding.casinoPurple,
                        AppBranding.casinoPurpleDeep,
                      ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppBranding.gold.withValues(alpha: isDark ? 0.55 : 0.75),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: AppBranding.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rule',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.ruleName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppBranding.gold : Colors.white,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _CompactInfoChip(
                label: 'Entry',
                value: formatMoney(game.entryFee),
                theme: theme,
              ),
              _CompactDivider(theme: theme),
              _CompactInfoChip(
                label: 'Prize',
                value: formatMoney(game.prizeAmount),
                theme: theme,
              ),
              _CompactDivider(theme: theme),
              _CompactInfoChip(
                label: 'Reg',
                value: '${game.registeredCartelasCount}',
                theme: theme,
              ),
              _CompactDivider(theme: theme),
              _CompactInfoChip(
                label: 'Called',
                value: '${game.calledNumbersCount}',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactInfoChip extends StatelessWidget {
  const _CompactInfoChip({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompactDivider extends StatelessWidget {
  const _CompactDivider({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
