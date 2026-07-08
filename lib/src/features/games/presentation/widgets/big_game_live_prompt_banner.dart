import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';
import '../providers/current_big_game_provider.dart';
import '../providers/current_game_operations_provider.dart';
import '../utils/big_game_navigation.dart';

/// Persistent strip on the normal games tab when Big Game is live or held.
class BigGameLivePromptBanner extends ConsumerWidget {
  const BigGameLivePromptBanner({
    required this.currentGame,
    this.embedded = false,
    super.key,
  });

  final GameModel? currentGame;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (embedded || currentGame?.isBigGame == true) {
      return const SizedBox.shrink();
    }

    final operations = ref.watch(currentGameOperationsProvider).value;
    final elsewhere = operations?.bigGameLiveElsewhere;
    final bigGame = ref.watch(currentBigGameProvider).value;
    final clock = ref.watch(serverClockProvider);
    final now = clock.isSynced ? clock.nowLocal() : DateTime.now();

    final shouldShow = elsewhere != null ||
        bigGame?.heldWaitingForLiveSlot == true ||
        (bigGame != null &&
            resolveBigGamePhase(bigGame, now: now) == BigGamePhase.live);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    const accent = AppBranding.gold;

    return Material(
      color: accent.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: accent, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.bigGameLivePrompt,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => BigGameNavigation.goToBigGame(context, ref),
              child: Text(l10n.bigGameGoAction),
            ),
          ],
        ),
      ),
    );
  }
}
