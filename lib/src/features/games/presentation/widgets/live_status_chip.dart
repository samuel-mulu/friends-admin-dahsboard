import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../domain/live_connection_status.dart';

class LiveStatusChip extends StatelessWidget {
  const LiveStatusChip({
    required this.connectionStatus,
    super.key,
  });

  final LiveConnectionStatus connectionStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppBranding.casinoPurpleDeep,
                AppBranding.casinoPurple,
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppBranding.gold.withValues(alpha: 0.65),
            ),
          ),
          child: Text(
            'LIVE',
            style: AppBranding.wordmarkGold(size: 16),
          ),
        ),
        const SizedBox(width: 8),
        _ConnectionDot(status: connectionStatus, theme: theme),
      ],
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.status, required this.theme});

  final LiveConnectionStatus status;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      LiveConnectionStatus.live => 'Live',
      LiveConnectionStatus.reconnecting => 'Reconnecting',
      LiveConnectionStatus.offline => 'Offline',
    };
    final color = switch (status) {
      LiveConnectionStatus.live => Colors.greenAccent,
      LiveConnectionStatus.reconnecting => Colors.orangeAccent,
      LiveConnectionStatus.offline => theme.colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
