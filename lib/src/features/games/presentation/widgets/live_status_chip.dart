import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/theme/app_branding.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';

class LiveStatusChip extends StatelessWidget {
  const LiveStatusChip({
    required this.connectionState,
    this.nextGame,
    super.key,
  });

  final LiveConnectionState connectionState;
  final GameModel? nextGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConnectionStatusDot(status: connectionState, theme: theme),
        if (nextGame != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: NextGameQueueBanner(game: nextGame!),
          ),
        ],
      ],
    );
  }
}

/// Compact queue hint shown inside the collapsible game-info section.
class NextGameQueueBanner extends StatelessWidget {
  const NextGameQueueBanner({
    required this.game,
    this.onTap,
    this.expanded = false,
    this.embedded = false,
    super.key,
  });

  final GameModel game;
  final VoidCallback? onTap;
  final bool expanded;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: embedded
            ? BorderRadius.zero
            : BorderRadius.circular(10),
        child: _GameContextChip(
          theme: theme,
          eyebrow: l10n.gameNextGame,
          icon: Icons.queue_play_next_rounded,
          trailingIcon: expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          tooltip: expanded ? l10n.gameNextGameHide : l10n.gameNextGameShow,
          embedded: embedded,
        ),
      ),
    );
  }
}

class ConnectionStatusDot extends StatelessWidget {
  const ConnectionStatusDot({
    required this.status,
    this.theme,
    super.key,
  });

  final LiveConnectionState status;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? Theme.of(context);
    final isLight = resolvedTheme.brightness == Brightness.light;
    final label = switch (status) {
      LiveConnectionState.online => context.l10n.statusOnline,
      LiveConnectionState.reconnecting => 'Reconnecting...',
      LiveConnectionState.syncing => 'Syncing...',
      LiveConnectionState.offline => context.l10n.statusOffline,
      LiveConnectionState.error => 'Error',
      LiveConnectionState.current => 'Current',
    };
    final color = switch (status) {
      LiveConnectionState.online =>
        isLight ? const Color(0xFF0F6B34) : Colors.greenAccent,
      LiveConnectionState.reconnecting =>
        isLight ? const Color(0xFFB45309) : Colors.orangeAccent,
      LiveConnectionState.syncing =>
        isLight ? const Color(0xFF0F5E9C) : Colors.lightBlueAccent,
      LiveConnectionState.offline =>
        resolvedTheme.colorScheme.onSurfaceVariant,
      LiveConnectionState.error => resolvedTheme.colorScheme.error,
      LiveConnectionState.current =>
        isLight ? const Color(0xFF0B7285) : Colors.tealAccent,
    };
    final showSpinner =
        status == LiveConnectionState.reconnecting ||
        status == LiveConnectionState.syncing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLight ? 0.14 : 0.15),
        borderRadius: BorderRadius.circular(999),
        border: isLight
            ? Border.all(color: color.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: resolvedTheme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameContextChip extends StatelessWidget {
  const _GameContextChip({
    required this.theme,
    required this.eyebrow,
    required this.icon,
    this.trailingIcon,
    this.tooltip,
    this.embedded = false,
  });

  final ThemeData theme;
  final String eyebrow;
  final IconData icon;
  final IconData? trailingIcon;
  final String? tooltip;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(
          icon,
          size: embedded ? 15 : 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: embedded ? 4 : 6),
        Expanded(
          child: Text(
            eyebrow,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: embedded ? 12 : null,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 4),
          Icon(
            trailingIcon,
            size: embedded ? 15 : 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );

    final chip = embedded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: content,
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppBranding.panelBackground(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppBranding.gold.withValues(alpha: 0.22),
              ),
            ),
            child: content,
          );

    if (tooltip == null) {
      return chip;
    }

    return Tooltip(message: tooltip, child: chip);
  }
}
