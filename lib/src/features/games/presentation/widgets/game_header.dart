import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_category_theme.dart';
import '../../domain/game_rule_localized_name.dart';
import 'game_category_badge.dart';
import 'game_countdown.dart';
import 'game_player_status_chip.dart';

/// Reusable game header — category, rule, status, prize, entry, countdown.
class GameHeader extends ConsumerWidget {
  const GameHeader({
    required this.game,
    this.title,
    this.countdownLabel,
    this.countdownTarget,
    this.serverClock,
    this.showMetadata = true,
    this.showStatus = true,
    this.compact = false,
    this.trailing,
    super.key,
  });

  final GameModel game;
  final String? title;
  final String? countdownLabel;
  final DateTime? countdownTarget;
  final ServerClockService? serverClock;
  final bool showMetadata;
  final bool showStatus;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final category = GameCategoryTheme.categoryFor(game);
    final ruleName = game.localizedRuleName(ref);
    final displayTitle = title ?? ruleName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              GameCategoryTheme.iconFor(category),
              color: GameCategoryTheme.accentColor(
                category,
                isDark: theme.brightness == Brightness.dark,
              ),
              size: compact ? 22 : 28,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style:
                        (compact
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GameCategoryBadge(category: category, compact: true),
                      if (showStatus)
                        GamePlayerStatusChip.forGame(game, compact: true),
                    ],
                  ),
                ],
              ),
            ),
            ...[trailing].nonNulls,
          ],
        ),
        if (countdownLabel != null && countdownTarget != null) ...[
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          GameCountdownRow(
            label: countdownLabel!,
            target: countdownTarget,
            serverClock: serverClock,
            large: !compact,
          ),
        ],
        if (showMetadata) ...[
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          _GameHeaderMetadata(game: game, compact: compact),
        ],
      ],
    );
  }
}

class _GameHeaderMetadata extends StatelessWidget {
  const _GameHeaderMetadata({required this.game, this.compact = false});

  final GameModel game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <_MetaRow>[
      if (game.fixedPrizeAmount != null)
        _MetaRow(
          label: l10n.bigGameFixedPrize,
          value: '${formatMoney(game.fixedPrizeAmount!)} ETB',
        )
      else
        _MetaRow(
          label: l10n.gameInfoPrize,
          value: '${formatMoney(game.prizeAmount)} ETB',
        ),
      _MetaRow(
        label: l10n.bigGameEntryFee,
        value: game.hasFreeEntry
            ? l10n.gameBonusFreeEntry
            : '${formatMoney(game.entryFee)} ETB',
      ),
      if (!compact && game.maxCartelasPerPlayer != null)
        _MetaRow(
          label: l10n.bigGameMaxCartelas,
          value: game.maxCartelasPerPlayer.toString(),
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 20),
          rows[i],
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
