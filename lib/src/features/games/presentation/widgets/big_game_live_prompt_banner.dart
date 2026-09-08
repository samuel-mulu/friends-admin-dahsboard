import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';
import '../../domain/game_category_theme.dart';
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
            resolveBigGamePhase(bigGame, now: now) == BigGamePhase.live) ||
        (bigGame != null &&
            resolveBigGamePhase(bigGame, now: now) ==
                BigGamePhase.registrationOpen &&
            bigGame.displayRoundIndex > 1);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.bigGame,
      isDark: isDark,
    );
    final phase =
        bigGame == null ? null : resolveBigGamePhase(bigGame, now: now);
    final isHeld = elsewhere?.phase == 'held' ||
        bigGame?.heldWaitingForLiveSlot == true;
    final nextWhileLive = bigGame?.nextRoundRegistration;
    final nextRegistrationOpenWhileLive = phase == BigGamePhase.live &&
        nextWhileLive != null &&
        nextWhileLive.canRegister;
    final isRegistrationOpen =
        (phase == BigGamePhase.registrationOpen &&
            (bigGame?.displayRoundIndex ?? 1) > 1) ||
        nextRegistrationOpenWhileLive;
    final registrationRound = nextRegistrationOpenWhileLive
        ? nextWhileLive.displayRoundIndex
        : (bigGame?.displayRoundIndex ?? 1);
    final promptText = isHeld
        ? l10n.bigGameHeldPrompt
        : isRegistrationOpen
            ? l10n.bigGameRegistrationOpenPrompt(registrationRound)
            : l10n.bigGameLivePrompt;

    return Material(
      color: GameCategoryTheme.surfaceColor(
        GameCategory.bigGame,
        isDark: isDark,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: accent, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                promptText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accent,
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
