import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/chain_round_plan_model.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_category_theme.dart';

/// Every round of a Chain Game with its pattern, prize, and state.
///
/// The ladder is fixed at creation and registration never reopens, so players
/// can see the whole chain — including rounds they have not reached yet.
Future<void> showChainGameRoundsDialog({
  required BuildContext context,
  required ChainRoundPlan plan,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ChainGameRoundsDialog(plan: plan),
  );
}

/// Brief hand-off when a chain resumes on a new round: same balls, same marks,
/// new target. Auto-dismisses so it never blocks the board while numbers fly.
Future<void> showChainRoundNewPatternSheet({
  required BuildContext context,
  required int roundIndex,
  required String patternName,
  Duration visibleFor = const Duration(seconds: 4),
}) async {
  if (patternName.trim().isEmpty) {
    return;
  }

  final navigator = Navigator.of(context);
  final future = showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    builder: (sheetContext) => _ChainRoundNewPatternSheet(
      roundIndex: roundIndex,
      patternName: patternName,
    ),
  );

  unawaited(
    Future<void>.delayed(visibleFor).then((_) {
      if (navigator.canPop()) {
        navigator.maybePop();
      }
    }),
  );

  await future;
}

class _ChainRoundNewPatternSheet extends StatelessWidget {
  const _ChainRoundNewPatternSheet({
    required this.roundIndex,
    required this.patternName,
  });

  final int roundIndex;
  final String patternName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.chainGame,
      isDark: theme.brightness == Brightness.dark,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.chainRoundNewPatternTitle(roundIndex),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chainRoundNewPatternBody(patternName),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainGameRoundsDialog extends StatelessWidget {
  const _ChainGameRoundsDialog({required this.plan});

  final ChainRoundPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.chainGame,
      isDark: theme.brightness == Brightness.dark,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.link_rounded, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.chainRoundsTitle,
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
                l10n.chainRoundsSubtitle(plan.roundCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.chainRoundTotalPrize}: ${plan.totalPrizeAmount}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: plan.rounds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _ChainRoundTile(
                    round: plan.rounds[index],
                    roundCount: plan.roundCount,
                    accent: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChainRoundTile extends StatelessWidget {
  const _ChainRoundTile({
    required this.round,
    required this.roundCount,
    required this.accent,
  });

  final ChainRoundPlanEntry round;
  final int roundCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isCurrent = round.state == ChainRoundState.current;
    final isForfeited = round.state == ChainRoundState.forfeited;

    final statusLabel = switch (round.state) {
      ChainRoundState.won => l10n.chainRoundStatusWon,
      ChainRoundState.forfeited => l10n.chainRoundStatusForfeited,
      ChainRoundState.current => l10n.chainRoundStatusCurrent,
      ChainRoundState.upcoming => l10n.chainRoundStatusUpcoming,
    };
    final statusColor = switch (round.state) {
      ChainRoundState.won => AppBranding.gold,
      ChainRoundState.forfeited => theme.colorScheme.error,
      ChainRoundState.current => accent,
      ChainRoundState.upcoming => theme.colorScheme.onSurfaceVariant,
    };

    return Opacity(
      opacity: isForfeited ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isCurrent ? accent.withValues(alpha: 0.08) : null,
          border: Border.all(
            color: isCurrent
                ? accent.withValues(alpha: 0.55)
                : theme.colorScheme.outlineVariant,
            width: isCurrent ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chainRoundOfTotal(round.roundIndex, roundCount),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    round.gameRuleName ?? round.gameRuleKey ?? '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: isForfeited
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (round.winnerCartelaNumbers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      round.winnerCartelaNumbers
                          .map((number) => '#$number')
                          .join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppBranding.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  round.prizeAmount,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    decoration: isForfeited ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
