import 'package:flutter/material.dart';
import '../../data/models/game_model.dart';

class GameSummaryCard extends StatelessWidget {
  const GameSummaryCard({
    required this.game,
    this.onTap,
    this.action,
    super.key,
  });

  final GameModel game;
  final VoidCallback? onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.playCode != null
                              ? 'Play ${game.playCode} • Slot ${game.staticCode}'
                              : 'Slot ${game.staticCode}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PlayerGameStatusChip(status: game.playerStatus),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoPill(label: 'Rule', value: game.ruleName),
                  if (game.playOrder != null)
                    _InfoPill(label: 'Order', value: '${game.playOrder}'),
                  _InfoPill(label: 'Entry', value: '${game.entryFee} ETB'),
                  _InfoPill(label: 'Prize', value: '${game.prizeAmount} ETB'),
                  _InfoPill(
                    label: 'Called',
                    value: '${game.calledNumbersCount}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${game.registeredCartelasCount} registered • ${game.registrationOpen ? 'Registration open' : 'Registration closed'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  ...[action].whereType<Widget>(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerGameStatusChip extends StatelessWidget {
  const _PlayerGameStatusChip({required this.status});

  final PlayerGameStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = switch (status) {
      PlayerGameStatus.registrationOpen => (
        background: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.onPrimaryContainer,
      ),
      PlayerGameStatus.checking => (
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      ),
      PlayerGameStatus.playing => (
        background: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.onSecondaryContainer,
      ),
      PlayerGameStatus.winnerWindow => (
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      ),
      PlayerGameStatus.finished => (
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurface,
      ),
      PlayerGameStatus.cancelled => (
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
