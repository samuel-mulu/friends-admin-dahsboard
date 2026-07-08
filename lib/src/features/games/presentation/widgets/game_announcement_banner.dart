import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/big_game_phase.dart';
import '../providers/current_big_game_provider.dart';
import '../providers/game_announcement_dismiss_provider.dart';
import '../utils/big_game_navigation.dart';
import '../widgets/game_countdown.dart';

/// Global dismissible announcement for scheduled, waiting, and live Big Game events.
class GameAnnouncementBanner extends ConsumerWidget {
  const GameAnnouncementBanner({super.key});

  bool _isVisiblePhase(BigGamePhase phase) {
    return switch (phase) {
      BigGamePhase.beforeRegistrationOpens ||
      BigGamePhase.registrationOpen ||
      BigGamePhase.waitingToPlay ||
      BigGamePhase.live => true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authControllerProvider).session == null;
    if (isGuest) {
      return const SizedBox.shrink();
    }

    final bigGame = ref.watch(currentBigGameProvider).value;
    if (bigGame == null) {
      return const SizedBox.shrink();
    }

    final clock = ref.watch(serverClockProvider);
    final now = clock.isSynced ? clock.nowLocal() : DateTime.now();
    final phase = resolveBigGamePhase(bigGame, now: now);
    if (!_isVisiblePhase(phase)) {
      return const SizedBox.shrink();
    }

    final sessionKey = bigGame.sessionId ?? bigGame.id;
    final id = 'big-$sessionKey-${phase.name}';
    final dismissed = ref.watch(gameAnnouncementDismissProvider);
    if (dismissed.contains(id)) {
      return const SizedBox.shrink();
    }

    final dismiss = ref.watch(gameAnnouncementDismissProvider.notifier);
    final l10n = context.l10n;
    final prize = bigGame.fixedPrizeAmount ?? bigGame.prizeAmount;
    const accent = Color(0xFFF5C542);

    final subtitle = switch (phase) {
      BigGamePhase.waitingToPlay => l10n.announcementBigGameWaiting,
      BigGamePhase.live => l10n.announcementBigGameLive,
      _ => l10n.announcementBigGamePrize(formatMoney(prize)),
    };
    final target = phase == BigGamePhase.beforeRegistrationOpens
        ? bigGame.registrationOpensAt
        : phase == BigGamePhase.registrationOpen
        ? bigGame.scheduledStartAt
        : null;
    final showCountdown =
        target != null &&
        phase != BigGamePhase.live &&
        phase != BigGamePhase.waitingToPlay;

    return Material(
      color: accent.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emoji_events_rounded, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.announcementBigGameTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (showCountdown) ...[
                      const SizedBox(height: 4),
                      GameCountdownRow(
                        label: l10n.announcementBigGameStartsIn,
                        target: target,
                        serverClock: clock,
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => requireAuthNavigate(
                        ref,
                        GoRouter.of(context),
                        redirectPath: '/games/big-game',
                        onAuthenticated: () =>
                            BigGameNavigation.goToBigGame(context, ref),
                      ),
                      child: Text(l10n.announcementBigGameAction),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.announcementDismiss,
                onPressed: () => dismiss.dismiss(id),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
