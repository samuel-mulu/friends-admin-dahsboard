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
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                          game.code,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _GameStatusChip(status: game.status),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoPill(label: 'Type', value: game.gameType),
                  _InfoPill(label: 'Entry', value: '${game.entryFee} ETB'),
                  _InfoPill(label: 'Prize', value: '${game.prizeAmount} ETB'),
                  _InfoPill(
                    label: 'Starts',
                    value: _formatDateTime(game.startsAt),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '${game.registeredCartelasCount} registered',
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

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'TBD';
    }

    final local = value.toLocal();
    final date =
        '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
    final time = '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
    return '$date $time';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _GameStatusChip extends StatelessWidget {
  const _GameStatusChip({required this.status});

  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = switch (status) {
      GameStatus.next => (
        background: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.onPrimaryContainer,
      ),
      GameStatus.checking => (
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      ),
      GameStatus.playing => (
        background: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.onSecondaryContainer,
      ),
      GameStatus.finished => (
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurface,
      ),
      GameStatus.cancelled => (
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
