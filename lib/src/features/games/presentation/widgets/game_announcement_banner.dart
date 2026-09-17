import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';
import '../../domain/game_category_theme.dart';
import '../providers/current_big_game_provider.dart';
import '../providers/current_game_operations_provider.dart';
import '../providers/game_announcement_dismiss_provider.dart';
import '../utils/big_game_navigation.dart';
import '../widgets/game_countdown.dart';

/// Centered helper card for Big Game on other shell routes.
///
/// Hidden on `/games/big-game`. On `/games` during an active standard live
/// round, hidden too — [BigGameLivePromptBanner] already covers that case
/// without blocking cartelas. Auto-dismisses after 30s (or via close).
class GameAnnouncementBanner extends ConsumerStatefulWidget {
  const GameAnnouncementBanner({super.key});

  static const autoDismissAfter = Duration(seconds: 30);

  @override
  ConsumerState<GameAnnouncementBanner> createState() =>
      _GameAnnouncementBannerState();
}

class _GameAnnouncementBannerState
    extends ConsumerState<GameAnnouncementBanner>
    with SingleTickerProviderStateMixin {
  Timer? _autoDismissTimer;
  String? _armedAnnouncementId;
  GoRouter? _router;
  late final AnimationController _appear;

  @override
  void initState() {
    super.initState();
    _appear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  bool _isVisiblePhase(BigGamePhase phase) {
    return switch (phase) {
      BigGamePhase.beforeRegistrationOpens ||
      BigGamePhase.registrationOpen ||
      BigGamePhase.waitingToPlay ||
      BigGamePhase.live => true,
      _ => false,
    };
  }

  bool _isOnBigGameRoute(BuildContext context) {
    final location = GoRouter.of(context).state.matchedLocation;
    return location == '/games/big-game' ||
        location.endsWith('/games/big-game');
  }

  bool _isOnGamesRoute(BuildContext context) {
    final location = GoRouter.of(context).state.matchedLocation;
    return location == '/games' || location.endsWith('/games');
  }

  /// Standard live round on `/games` already has [BigGameLivePromptBanner].
  bool _hasBlockingStandardLiveGame(GameOperationsCurrentResponse? operations) {
    final live = operations?.liveGame ?? operations?.checkingGame;
    if (live == null || live.isBigGame) {
      return false;
    }
    return switch (live.status) {
      GameStatus.playing ||
      GameStatus.checking ||
      GameStatus.winnerWindow => true,
      _ => false,
    };
  }

  void _onRouteChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(_router, router)) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = router;
      _router!.routerDelegate.addListener(_onRouteChanged);
    }
  }

  void _cancelAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _armedAnnouncementId = null;
  }

  void _scheduleAutoDismiss(String? announcementId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (announcementId == null) {
        _cancelAutoDismiss();
        if (_appear.value > 0) {
          _appear.value = 0;
        }
        return;
      }
      if (_armedAnnouncementId == announcementId &&
          _autoDismissTimer?.isActive == true) {
        return;
      }
      _autoDismissTimer?.cancel();
      _armedAnnouncementId = announcementId;
      _appear.forward(from: 0);
      _autoDismissTimer = Timer(GameAnnouncementBanner.autoDismissAfter, () {
        if (!mounted || _armedAnnouncementId != announcementId) {
          return;
        }
        unawaited(_dismiss(announcementId));
      });
    });
  }

  Future<void> _dismiss(String id) async {
    _cancelAutoDismiss();
    if (_appear.value > 0) {
      await _appear.reverse();
    }
    if (!mounted) {
      return;
    }
    await ref.read(gameAnnouncementDismissProvider.notifier).dismiss(id);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _cancelAutoDismiss();
    _appear.dispose();
    super.dispose();
  }

  String? _phaseChip(BigGamePhase phase, AppLocalizations l10n) {
    return switch (phase) {
      BigGamePhase.live => l10n.announcementBigGameLive,
      BigGamePhase.waitingToPlay => l10n.announcementBigGameStartingSoon,
      BigGamePhase.registrationOpen => null,
      BigGamePhase.beforeRegistrationOpens => null,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authControllerProvider).session == null;
    if (isGuest || _isOnBigGameRoute(context)) {
      _scheduleAutoDismiss(null);
      return const SizedBox.shrink();
    }

    // Playing a normal round on /games: keep only the top strip prompt so the
    // centered card does not cover cartelas (see screenshot bleed-through).
    final operations = ref.watch(currentGameOperationsProvider).value;
    if (_isOnGamesRoute(context) && _hasBlockingStandardLiveGame(operations)) {
      _scheduleAutoDismiss(null);
      return const SizedBox.shrink();
    }

    final bigGame = ref.watch(currentBigGameProvider).value;
    if (bigGame == null) {
      _scheduleAutoDismiss(null);
      return const SizedBox.shrink();
    }

    final clock = ref.watch(serverClockProvider);
    final now = clock.isSynced ? clock.nowLocal() : DateTime.now();
    final phase = resolveBigGamePhase(bigGame, now: now);
    if (!_isVisiblePhase(phase)) {
      _scheduleAutoDismiss(null);
      return const SizedBox.shrink();
    }

    final sessionKey = bigGame.sessionId ?? bigGame.id;
    final id = 'big-$sessionKey-${phase.name}';
    final dismissed = ref.watch(gameAnnouncementDismissProvider);
    if (dismissed.contains(id)) {
      _scheduleAutoDismiss(null);
      return const SizedBox.shrink();
    }

    _scheduleAutoDismiss(id);

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.bigGame,
      isDark: isDark,
    );
    final border = GameCategoryTheme.borderColor(
      GameCategory.bigGame,
      isDark: isDark,
    );
    final prize = bigGame.fixedPrizeAmount ?? bigGame.prizeAmount;

    final helperText = switch (phase) {
      BigGamePhase.waitingToPlay => bigGame.heldWaitingForLiveSlot
          ? l10n.announcementBigGameWaiting
          : l10n.announcementBigGameStartingSoon,
      BigGamePhase.live
          when bigGame.nextRoundRegistration != null &&
              bigGame.nextRoundRegistration!.canRegister =>
        l10n.bigGameRegistrationOpenPrompt(
          bigGame.nextRoundRegistration!.displayRoundIndex,
        ),
      BigGamePhase.live => l10n.announcementBigGameLive,
      BigGamePhase.registrationOpen when bigGame.displayRoundIndex > 1 =>
        l10n.bigGameRegistrationOpenPrompt(bigGame.displayRoundIndex),
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
    // Avoid repeating the same line as both chip and helper body.
    final chipLabel = _phaseChip(phase, l10n);
    final showChip =
        chipLabel != null && chipLabel.trim() != helperText.trim();

    return Positioned.fill(
      // Pass taps through empty space; only the card receives input.
      child: IgnorePointer(
        child: Center(
          child: IgnorePointer(
            ignoring: false,
            child: FadeTransition(
              opacity: _appear,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(
                  CurvedAnimation(
                    parent: _appear,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Material(
                        color: Colors.transparent,
                        elevation: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: border.withValues(
                                alpha: isDark ? 0.55 : 0.4,
                              ),
                            ),
                            // Solid enough that live cartelas do not show through.
                            color: Color.alphaBlend(
                              accent.withValues(alpha: isDark ? 0.22 : 0.12),
                              isDark
                                  ? const Color(0xF01A1228)
                                  : const Color(0xF8FFFFFF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.5 : 0.22,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: isDark ? 0.22 : 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.emoji_events_rounded,
                                      color: accent,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.announcementBigGameTitle,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                            color: accent,
                                          ),
                                        ),
                                        if (showChip) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                alpha: isDark ? 0.24 : 0.14,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              chipLabel,
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.announcementDismiss,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => unawaited(_dismiss(id)),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 22,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  helperText,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              if (showCountdown) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withValues(
                                      alpha: isDark ? 0.35 : 0.72,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: GameCountdownRow(
                                    label: l10n.announcementBigGameStartsIn,
                                    target: target,
                                    serverClock: clock,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => requireAuthNavigate(
                                    ref,
                                    GoRouter.of(context),
                                    redirectPath: '/games/big-game',
                                    onAuthenticated: () =>
                                        BigGameNavigation.goToBigGame(
                                          context,
                                          ref,
                                        ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor:
                                        isDark ? Colors.black : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    l10n.announcementBigGameAction,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
