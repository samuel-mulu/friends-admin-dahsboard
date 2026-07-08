import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';

/// Unified player-facing status chips — consistent colors app-wide.
class GamePlayerStatusChip extends StatelessWidget {
  const GamePlayerStatusChip({
    required this.status,
    this.compact = false,
    super.key,
  });

  factory GamePlayerStatusChip.forGame(
    GameModel game, {
    bool compact = false,
    bool waitingToPlay = false,
    bool registrationClosed = false,
  }) {
    if (registrationClosed) {
      return GamePlayerStatusChip(
        status: _GamePlayerStatusChipKind.registrationClosed,
        compact: compact,
      );
    }
    if (waitingToPlay) {
      return GamePlayerStatusChip(
        status: _GamePlayerStatusChipKind.waiting,
        compact: compact,
      );
    }
    return GamePlayerStatusChip(
      status: _GamePlayerStatusChipKind.fromPlayerStatus(game.playerStatus),
      compact: compact,
    );
  }

  final _GamePlayerStatusChipKind status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = _paletteFor(status, theme);
    final label = switch (status) {
      _GamePlayerStatusChipKind.registrationOpen =>
        l10n.gameStatusRegistrationOpen,
      _GamePlayerStatusChipKind.preparing => l10n.gameStatusPreparing,
      _GamePlayerStatusChipKind.playing => l10n.gameStatusPlaying,
      _GamePlayerStatusChipKind.winnerWindow => l10n.gameStatusWinnerWindow,
      _GamePlayerStatusChipKind.finished => l10n.gameStatusFinished,
      _GamePlayerStatusChipKind.cancelled => l10n.gameStatusCancelled,
      _GamePlayerStatusChipKind.checking => l10n.gameStatusChecking,
      _GamePlayerStatusChipKind.waiting => l10n.gameStatusWaiting,
      _GamePlayerStatusChipKind.registrationClosed =>
        l10n.gameStatusRegistrationClosed,
    };

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  _StatusPalette _paletteFor(
    _GamePlayerStatusChipKind status,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return switch (status) {
      _GamePlayerStatusChipKind.registrationOpen => _StatusPalette(
        background: const Color(
          0xFF2563EB,
        ).withValues(alpha: isDark ? 0.25 : 0.12),
        border: const Color(0xFF2563EB).withValues(alpha: 0.45),
        foreground: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
      ),
      _GamePlayerStatusChipKind.preparing ||
      _GamePlayerStatusChipKind.waiting => _StatusPalette(
        background: const Color(
          0xFFF59E0B,
        ).withValues(alpha: isDark ? 0.22 : 0.14),
        border: const Color(0xFFF59E0B).withValues(alpha: 0.45),
        foreground: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
      ),
      _GamePlayerStatusChipKind.playing => _StatusPalette(
        background: const Color(
          0xFF16A34A,
        ).withValues(alpha: isDark ? 0.22 : 0.12),
        border: const Color(0xFF16A34A).withValues(alpha: 0.45),
        foreground: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      ),
      _GamePlayerStatusChipKind.winnerWindow => _StatusPalette(
        background: const Color(
          0xFF7C3AED,
        ).withValues(alpha: isDark ? 0.25 : 0.12),
        border: const Color(0xFF7C3AED).withValues(alpha: 0.45),
        foreground: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
      ),
      _GamePlayerStatusChipKind.checking => _StatusPalette(
        background: const Color(
          0xFFEA580C,
        ).withValues(alpha: isDark ? 0.22 : 0.12),
        border: const Color(0xFFEA580C).withValues(alpha: 0.45),
        foreground: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
      ),
      _GamePlayerStatusChipKind.finished => _StatusPalette(
        background: theme.colorScheme.surfaceContainerHighest,
        border: theme.colorScheme.outlineVariant,
        foreground: theme.colorScheme.onSurfaceVariant,
      ),
      _GamePlayerStatusChipKind.cancelled => _StatusPalette(
        background: const Color(
          0xFFDC2626,
        ).withValues(alpha: isDark ? 0.22 : 0.1),
        border: const Color(0xFFDC2626).withValues(alpha: 0.4),
        foreground: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
      ),
      _GamePlayerStatusChipKind.registrationClosed => _StatusPalette(
        background: theme.colorScheme.surfaceContainerHighest,
        border: theme.colorScheme.outlineVariant,
        foreground: theme.colorScheme.onSurfaceVariant,
      ),
    };
  }
}

enum _GamePlayerStatusChipKind {
  registrationOpen,
  preparing,
  playing,
  winnerWindow,
  checking,
  finished,
  cancelled,
  waiting,
  registrationClosed;

  static _GamePlayerStatusChipKind fromPlayerStatus(PlayerGameStatus status) {
    return switch (status) {
      PlayerGameStatus.registrationOpen =>
        _GamePlayerStatusChipKind.registrationOpen,
      PlayerGameStatus.playing => _GamePlayerStatusChipKind.playing,
      PlayerGameStatus.winnerWindow => _GamePlayerStatusChipKind.winnerWindow,
      PlayerGameStatus.checking => _GamePlayerStatusChipKind.checking,
      PlayerGameStatus.finished => _GamePlayerStatusChipKind.finished,
      PlayerGameStatus.cancelled => _GamePlayerStatusChipKind.cancelled,
    };
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
