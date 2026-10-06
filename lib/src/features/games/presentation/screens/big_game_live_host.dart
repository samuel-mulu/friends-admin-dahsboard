import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../../data/models/game_model.dart';
import '../utils/big_game_live_bootstrap.dart';
import '../utils/big_game_live_presentation.dart';
import 'big_game_phase_views.dart';
import 'live_game_screen.dart';

/// Big-Game-only host for registration / PLAYING embeds.
///
/// Owns bootstrap + chrome; mounts production [LiveGameScreen] as a black box
/// so Normal / Bonus / BIG_GOTD live paths stay untouched.
///
/// During live → finished → next READY, nested Live owns the transition.
/// This host must not remount Live on terminal status or next-round link updates.
class BigGameLiveHost extends ConsumerStatefulWidget {
  const BigGameLiveHost({
    required this.game,
    required this.clock,
    this.headerTitle,
    this.countdownLabel,
    this.countdownTarget,
    this.showCountdown = true,
    this.showBanner = true,
    this.onCountdownExpired,
    /// When true, outer shell must not wrap this host in RefreshIndicator
    /// (sticky live scroller owns scroll). Registration embeds may allow PTR
    /// from the parent shell.
    this.isLivePlaying = false,
    this.preserveLiveInstanceOnTerminalTransition = false,
    super.key,
  });

  final GameModel game;
  final ServerClockService clock;
  final String? headerTitle;
  final String? countdownLabel;
  final DateTime? countdownTarget;
  final bool showCountdown;
  final bool showBanner;
  final Future<void> Function()? onCountdownExpired;
  final bool isLivePlaying;

  /// PLAYING → FINISHED on the same session: keep nested [LiveGameScreen] so
  /// the 60s post-game summary is not torn down by bootstrap remount.
  final bool preserveLiveInstanceOnTerminalTransition;

  @override
  ConsumerState<BigGameLiveHost> createState() => _BigGameLiveHostState();
}

class _BigGameLiveHostState extends ConsumerState<BigGameLiveHost> {
  GameModel? _bootstrapped;
  bool _bootstrapping = true;
  Object? _bootstrapError;

  /// Session id of the mounted Live instance. Stable across terminal + nextReg
  /// patches so finish → next READY is not remounted by the shell.
  String? _mountedLiveSessionId;

  bool _isTerminalStatus(GameStatus status) {
    return status == GameStatus.finished || status == GameStatus.noWinner;
  }

  bool _isTerminalTransition({
    required GameStatus from,
    required GameStatus to,
  }) {
    final wasLive = from == GameStatus.playing ||
        from == GameStatus.checking ||
        from == GameStatus.winnerWindow;
    return wasLive && _isTerminalStatus(to);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_runBootstrap(widget.game));
  }

  @override
  void didUpdateWidget(covariant BigGameLiveHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.game.sessionId;
    final nextId = widget.game.sessionId;
    final statusChanged = oldWidget.game.status != widget.game.status;
    final nextRegChanged =
        oldWidget.game.nextRoundRegistration?.sessionId !=
        widget.game.nextRoundRegistration?.sessionId;
    final sameSession = oldId != null && oldId == nextId;
    final terminalOnSameSession = sameSession &&
        widget.preserveLiveInstanceOnTerminalTransition &&
        statusChanged &&
        _isTerminalTransition(
          from: oldWidget.game.status,
          to: widget.game.status,
        );
    final stayOnTerminalSameSession = sameSession &&
        widget.preserveLiveInstanceOnTerminalTransition &&
        _isTerminalStatus(oldWidget.game.status) &&
        _isTerminalStatus(widget.game.status);

    // Backend operational primary flipped to Round N+1 while Live is still
    // pinning Round N's finished summary — attach N+1 as secondary and keep
    // the nested Live instance (shared Normal finish machine owns Continue).
    if (widget.preserveLiveInstanceOnTerminalTransition &&
        isBigGameIncomingNextRoundAfterMounted(
          incoming: widget.game,
          mountedSessionId: _mountedLiveSessionId,
          mountedGame: _bootstrapped,
        )) {
      final base = _bootstrapped;
      if (base != null && _isTerminalStatus(base.status)) {
        setState(() {
          _bootstrapped = base.copyWith(
            nextRoundRegistration: widget.game.nextRoundRegistration ??
                widget.game,
            nextRoundStartsAt:
                widget.game.scheduledStartAt ?? widget.game.nextRoundStartsAt,
          );
        });
        return;
      }
    }

    // Shell still reports the finished Round N while Live has already advanced
    // to Round N+1 READY — never remount that Live instance from the card.
    if (sameSession &&
        widget.preserveLiveInstanceOnTerminalTransition &&
        (terminalOnSameSession || stayOnTerminalSameSession)) {
      _patchBootstrappedCard(widget.game);
      return;
    }

    if (oldId != nextId ||
        (statusChanged &&
            widget.isLivePlaying &&
            !terminalOnSameSession)) {
      unawaited(_runBootstrap(widget.game));
      return;
    }

    // Keep nested next READY in sync without remounting live play.
    if (nextRegChanged ||
        widget.game.nextRoundRegistration !=
            oldWidget.game.nextRoundRegistration) {
      _patchBootstrappedCard(widget.game);
    }
  }

  void _patchBootstrappedCard(GameModel card) {
    final base = _bootstrapped ?? card;
    setState(() {
      _bootstrapped = base.copyWith(
        status: card.status,
        finishedAt: card.finishedAt,
        nextRoundStartsAt: card.nextRoundStartsAt,
        nextRoundRegistration: card.nextRoundRegistration,
        scheduledStartAt: card.scheduledStartAt,
        registrationOpensAt: card.registrationOpensAt,
        canRegister: card.canRegister,
        registrationOpen: card.registrationOpen,
      );
    });
  }

  Future<void> _runBootstrap(GameModel seed) async {
    setState(() {
      _bootstrapping = true;
      _bootstrapError = null;
      _mountedLiveSessionId = null;
    });
    try {
      final prepared = await BigGameLiveBootstrap.prepareEmbeddedGame(
        ref,
        seed: seed,
      );
      if (!mounted) {
        return;
      }
      final next = prepared ?? seed;
      setState(() {
        _bootstrapped = next;
        _bootstrapping = false;
        _mountedLiveSessionId = next.sessionId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _bootstrapped = seed;
        _bootstrapping = false;
        _mountedLiveSessionId = seed.sessionId;
        _bootstrapError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = widget.game;
    final game = _bootstrapped ?? seed;
    final sessionId = _mountedLiveSessionId ?? game.sessionId;
    if (sessionId == null) {
      return BigGameEmptyView(onRefresh: () => _runBootstrap(seed));
    }

    if (_bootstrapping && _bootstrapped == null) {
      return const Center(
        child: FriendsBingoLoader.inline(compact: true),
      );
    }

    final showMissedRegistration = game.showBigGameMissedRoundRegistration;
    final registrationRoundIndex =
        game.nextRoundRegistration?.displayRoundIndex ?? game.displayRoundIndex;
    final headerTitle = widget.headerTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showBanner && headerTitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: BigGameCollapsibleBanner(
              game: game,
              title: showMissedRegistration
                  ? context.l10n.bigGameMissedRoundRegistrationTitle(
                      registrationRoundIndex,
                    )
                  : headerTitle,
              countdownLabel: widget.showCountdown ? widget.countdownLabel : null,
              countdownTarget:
                  widget.showCountdown ? widget.countdownTarget : null,
              clock: widget.clock,
              onCountdownExpired: widget.onCountdownExpired,
              compact: true,
            ),
          ),
        if (_bootstrapError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              context.l10n.gameHistoryRetry,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        Expanded(
          child: LiveGameScreen(
            key: ValueKey(bigGameEmbeddedLiveInstanceKey(sessionId)),
            gameId: sessionId,
            showAppBar: false,
            initialGame: game,
            embedded: true,
            showBigGameMissedRoundRegistration: showMissedRegistration,
          ),
        ),
      ],
    );
  }
}
