part of 'live_game_screen.dart';

mixin _LiveGameWinnerWindow on _LiveGameOrchestration {
  Widget? _buildLiveStatusBanner() {
    final game = _game;
    if (game == null) {
      return null;
    }

    if (_showsPostGameSummary) {
      return null;
    }

    if (_isSyncingLiveGame) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: context.l10n.gameSyncing,
        message: context.l10n.gameSyncingMessage,
      );
    }

    return switch (_livePresentationPhase) {
      LivePresentationPhase.winnerWindow => _buildWinnerWindowBanner(game),
      LivePresentationPhase.checking => _LiveStatusBanner(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          title: context.l10n.gameCheckingTitle,
          message: context.l10n.gameCheckingMessage,
        ),
      LivePresentationPhase.noPlayersJoined => _LiveStatusBanner(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: context.l10n.gameNoPlayers,
          message: context.l10n.gameNoPlayersMessage,
        ),
      LivePresentationPhase.cancelled => _LiveStatusBanner(
          color: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          title: context.l10n.gameCancelled,
          message: context.l10n.gameCancelledMessage,
        ),
      _ => null,
    };
  }

  Widget _buildWinnerWindowBanner(GameModel game) {
    final windowEndsAt = _effectiveWinnerWindowEndsAt;

    if (!isWinnerWindowActive(
      status: game.status,
      windowEndsAt: windowEndsAt,
      now: _countdownNow(),
    )) {
      if (_winnerWindowExpired && game.status == GameStatus.winnerWindow) {
        return _LiveStatusBanner(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          title: context.l10n.gameWinnerWindowOpen,
          message: context.l10n.gameSyncingMessage,
        );
      }
      return const SizedBox.shrink();
    }

    if (windowEndsAt == null) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        title: context.l10n.gameWinnerWindowOpen,
        message: context.l10n.gameWinnerWindowMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WinnerWindowCountdown(
          endsAt: windowEndsAt,
          serverClock: _serverClock,
          countdownTracker: controllers.countdown.winnerWindowCountdownTracker,
          scopeKey: game.sessionId ?? game.id,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.gameWinnerWindowMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  bool get _isAutomaticRule => _game?.isAutomaticRule ?? true;
}
