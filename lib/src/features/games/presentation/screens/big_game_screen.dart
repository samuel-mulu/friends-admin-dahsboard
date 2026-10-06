import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game_category_theme.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/games_repository.dart';
import '../../domain/big_game_phase.dart';
import '../utils/big_game_live_presentation.dart';
import '../debug/big_game_debug.dart';
import '../providers/current_big_game_provider.dart';
import 'big_game_live_host.dart';
import 'big_game_phase_views.dart';

/// Thin Big Game route shell. Live PLAYING is hosted by [BigGameLiveHost]
/// (no outer pull-to-refresh). Non-live phases keep RefreshIndicator.
class BigGameScreen extends ConsumerStatefulWidget {
  const BigGameScreen({super.key});

  @override
  ConsumerState<BigGameScreen> createState() => _BigGameScreenState();
}

class _BigGameScreenState extends ConsumerState<BigGameScreen>
    with WidgetsBindingObserver {
  BigGamePhase? _lastLoggedPhase;
  String? _lastLoggedSessionKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_syncServerClock());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(currentBigGameProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        unawaited(_syncServerClock(snap: true));
        unawaited(ref.read(currentBigGameProvider.notifier).refresh());
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _syncServerClock({bool snap = false}) async {
    try {
      final timing = await ref.read(gamesRepositoryProvider).getTimeConfig();
      final serverNow = timing.serverNow;
      if (serverNow != null) {
        ref.read(serverClockProvider).sync(serverNow, snap: snap);
      }
    } catch (_) {
      // Big Game countdown falls back to device time when sync fails.
    }
  }

  Future<void> _handleRefresh() async {
    await _syncServerClock(snap: true);
    await ref.read(currentBigGameProvider.notifier).refresh();
  }

  DateTime _now(ServerClockService clock) {
    return clock.isSynced ? clock.nowLocal() : DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final bigGameAsync = ref.watch(currentBigGameProvider);
    final clock = ref.watch(serverClockProvider);

    return Theme(
      data: GameCategoryTheme.bigGameTheme(context),
      child: bigGameAsync.when(
        loading: () => const BigGameLoadingView(),
        error: (error, _) => BigGameErrorView(
          message: error.toString(),
          onRetry: _handleRefresh,
        ),
        data: (game) {
          if (game == null) {
            return BigGameEmptyView(onRefresh: _handleRefresh);
          }

          final now = _now(clock);
          // Backend operational primary may already be Round N+1 READY while
          // Round N is FINISHED. Pin Round N locally for the shared finish
          // summary (Normal A/B semantics) without reverting backend primary.
          final presentation = resolveBigGamePresentationSeed(game);
          final phase = resolveBigGamePhase(presentation, now: now);
          final sessionKey =
              '${presentation.sessionId ?? presentation.id}:${presentation.status.name}';
          if (_lastLoggedPhase != phase || _lastLoggedSessionKey != sessionKey) {
            BigGameDebug.phase(
              from: _lastLoggedPhase,
              to: phase,
              game: presentation,
              now: now,
            );
            _lastLoggedPhase = phase;
            _lastLoggedSessionKey = sessionKey;
          }
          if (phase == BigGamePhase.cancelled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              unawaited(ref.read(currentBigGameProvider.notifier).refresh());
            });
            return BigGameEmptyView(onRefresh: _handleRefresh);
          }

          final embedTerminalReview = shouldEmbedBigGameTerminalReviewHost(
            game: presentation,
            phase: phase,
          );

          // PLAYING + FINISHED review: one host so Live owns 60s summary →
          // next READY (same feel as a normal game). Stable key — do not flip
          // on live→finished or the nested Live remounts and drops the summary.
          if (phase == BigGamePhase.live || embedTerminalReview) {
            return BigGameLiveHost(
              key: ValueKey(bigGameLiveHostInstanceKey(presentation)),
              game: presentation,
              clock: clock,
              headerTitle: context.l10n.drawerBigGame,
              showCountdown: false,
              // Live's RoundFinishedBanner owns finished chrome; shell banner
              // would stack "Game Finished" on top of the same transition.
              showBanner: shouldShowBigGameShellBanner(
                phase: phase,
                embedTerminalReview: embedTerminalReview,
              ),
              isLivePlaying: true,
              preserveLiveInstanceOnTerminalTransition: true,
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: switch (phase) {
              BigGamePhase.beforeRegistrationOpens => BigGameScheduledView(
                game: presentation,
                clock: clock,
                countdownTarget: presentation.registrationOpensAt,
                title: context.l10n.bigGameScheduledTitle,
                countdownLabel: context.l10n.bigGameRegistrationOpensIn,
                onCountdownExpired: _handleRefresh,
              ),
              // Round 1 create schedule or Round 2+ time-config READY.
              BigGamePhase.registrationOpen => BigGameLiveHost(
                game: presentation,
                clock: clock,
                headerTitle: context.l10n.bigGameRegistrationOpenTitle,
                countdownLabel: context.l10n.bigGamePlayStartsIn,
                countdownTarget: presentation.scheduledStartAt,
                showBanner: true,
                onCountdownExpired: _handleRefresh,
              ),
              BigGamePhase.waitingToPlay => BigGameWaitingView(
                game: presentation,
                onRefresh: _handleRefresh,
              ),
              BigGamePhase.live ||
              BigGamePhase.finishedReview ||
              BigGamePhase.cancelled ||
              BigGamePhase.none => BigGameEmptyView(onRefresh: _handleRefresh),
            },
          );
        },
      ),
    );
  }
}
