import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';
import '../../domain/game_category_theme.dart';
import '../providers/big_game_prompt_dismiss_provider.dart';
import '../providers/current_big_game_provider.dart';
import '../providers/current_game_operations_provider.dart';
import '../utils/big_game_navigation.dart';

/// Persistent strip on the normal games tab when Big Game is actionable.
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
    final phase =
        bigGame == null ? null : resolveBigGamePhase(bigGame, now: now);

    final hasMoreRoundsAfterCurrent = bigGame != null &&
        bigGame.displayRoundIndex < bigGame.displayRoundCount;
    final nextWhileLive = bigGame?.nextRoundRegistration;
    final nextRegistrationOpenWhileLive = phase == BigGamePhase.live &&
        nextWhileLive != null &&
        nextWhileLive.canRegister;
    final finishedWithFollowUp = phase == BigGamePhase.finishedReview &&
        hasMoreRoundsAfterCurrent &&
        (nextWhileLive != null || bigGame.nextRoundStartsAt != null);

    final shouldShow = elsewhere != null ||
        bigGame?.heldWaitingForLiveSlot == true ||
        phase == BigGamePhase.live ||
        phase == BigGamePhase.registrationOpen ||
        phase == BigGamePhase.betweenRounds ||
        phase == BigGamePhase.waitingToPlay ||
        finishedWithFollowUp;

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final promptKind = _resolvePromptKind(
      elsewhere: elsewhere,
      bigGame: bigGame,
      phase: phase,
      nextRegistrationOpenWhileLive: nextRegistrationOpenWhileLive,
    );
    final registrationRound = _registrationRound(
      bigGame: bigGame,
      phase: phase,
      nextRegistrationOpenWhileLive: nextRegistrationOpenWhileLive,
      nextWhileLive: nextWhileLive,
    );
    final playingRound = bigGame?.displayRoundIndex ?? 1;

    final contextKey = _promptContextKey(
      elsewhere: elsewhere,
      bigGame: bigGame,
      promptKind: promptKind,
      registrationRound: registrationRound,
      playingRound: playingRound,
    );
    if (ref.watch(bigGamePromptDismissProvider) == contextKey) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final promptText = _resolvePromptText(
      l10n: l10n,
      promptKind: promptKind,
      registrationRound: registrationRound,
      playingRound: playingRound,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.bigGame,
      isDark: isDark,
    );

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
            IconButton(
              tooltip: l10n.bigGamePromptDismiss,
              onPressed: () => ref
                  .read(bigGamePromptDismissProvider.notifier)
                  .dismissForContext(contextKey),
              icon: Icon(Icons.close_rounded, color: accent, size: 20),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BigGamePromptKind {
  held,
  registrationOpen,
  betweenRounds,
  playing,
}

_BigGamePromptKind _resolvePromptKind({
  required BigGameLiveElsewhere? elsewhere,
  required GameModel? bigGame,
  required BigGamePhase? phase,
  required bool nextRegistrationOpenWhileLive,
}) {
  final isHeld = elsewhere?.isHeld == true ||
      bigGame?.heldWaitingForLiveSlot == true ||
      phase == BigGamePhase.waitingToPlay;
  if (isHeld) {
    return _BigGamePromptKind.held;
  }

  final isRegistrationOpen = phase == BigGamePhase.registrationOpen ||
      nextRegistrationOpenWhileLive ||
      (phase == BigGamePhase.finishedReview &&
          bigGame?.nextRoundRegistration?.canRegister == true);
  if (isRegistrationOpen) {
    return _BigGamePromptKind.registrationOpen;
  }

  if (phase == BigGamePhase.betweenRounds ||
      phase == BigGamePhase.finishedReview) {
    return _BigGamePromptKind.betweenRounds;
  }

  return _BigGamePromptKind.playing;
}

String _resolvePromptText({
  required AppLocalizations l10n,
  required _BigGamePromptKind promptKind,
  required int registrationRound,
  required int playingRound,
}) {
  return switch (promptKind) {
    _BigGamePromptKind.held => l10n.bigGameHeldPrompt,
    _BigGamePromptKind.registrationOpen =>
      l10n.bigGameRegistrationOpenPrompt(registrationRound),
    _BigGamePromptKind.betweenRounds => l10n.bigGameBetweenRoundsPrompt,
    _BigGamePromptKind.playing => l10n.bigGamePlayingPrompt(playingRound),
  };
}

int _registrationRound({
  required GameModel? bigGame,
  required BigGamePhase? phase,
  required bool nextRegistrationOpenWhileLive,
  required GameModel? nextWhileLive,
}) {
  if (nextRegistrationOpenWhileLive && nextWhileLive != null) {
    return nextWhileLive.displayRoundIndex;
  }
  final next = bigGame?.nextRoundRegistration;
  if (phase == BigGamePhase.finishedReview && next?.canRegister == true) {
    return next!.displayRoundIndex;
  }
  return bigGame?.displayRoundIndex ?? 1;
}

String _promptContextKey({
  required BigGameLiveElsewhere? elsewhere,
  required GameModel? bigGame,
  required _BigGamePromptKind promptKind,
  required int registrationRound,
  required int playingRound,
}) {
  final sessionId =
      bigGame?.sessionId ?? bigGame?.id ?? elsewhere?.sessionId ?? 'none';
  final round = promptKind == _BigGamePromptKind.registrationOpen
      ? registrationRound
      : playingRound;
  return '$sessionId:${promptKind.name}:$round';
}
