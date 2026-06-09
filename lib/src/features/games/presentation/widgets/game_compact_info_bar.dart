import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../data/models/game_model.dart';

class GameCompactInfoBar extends StatelessWidget {
  const GameCompactInfoBar({required this.game, super.key});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          _CompactInfoChip(label: 'Rule', value: game.ruleName, theme: theme),
          _CompactDivider(theme: theme),
          _CompactInfoChip(
            label: 'Entry',
            value: '${game.entryFee} ETB',
            theme: theme,
          ),
          _CompactDivider(theme: theme),
          _CompactInfoChip(
            label: 'Prize',
            value: '${game.prizeAmount} ETB',
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
