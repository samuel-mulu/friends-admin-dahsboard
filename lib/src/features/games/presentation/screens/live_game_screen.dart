import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/friends_bingo_loading.dart';
import '../../domain/cartela_availability.dart';
import '../../domain/live_connection_status.dart';
import '../utils/cartela_mark_helpers.dart';
import '../widgets/called_numbers_strip.dart';
import '../widgets/cartela_number_chip.dart';
import '../widgets/cartela_registration_sheet.dart';
import '../widgets/collapsible_game_info_bar.dart';
import '../widgets/live_cartela_card.dart';
import '../widgets/live_status_chip.dart';
import '../widgets/registration_open_pulse.dart';
import '../widgets/winner_window_countdown_chip.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/games_repository.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../providers/games_providers.dart';

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({this.gameId, this.showAppBar = false, super.key});

  final String? gameId;
  final bool showAppBar;

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _errorMessage;
  String? _emptyMessage;
  GameModel? _game;
  String? _joinedGameId;
  List<CalledNumberModel> _calledNumbers = const [];
  List<GameCartelaModel> _myCartelas = const [];
  final Set<String> _claimingCartelaIds = <String>{};
  final Set<String> _processedClaimedIds = <String>{};
  final Set<String> _processedResolvedClaimIds = <String>{};
  final Set<String> _processedCalledNumberIds = <String>{};
  final Set<String> _pendingClaimCartelaIds = <String>{};
  final Set<String> _manualMarkedNumbers = <String>{};
  String? _marksSessionId;
  bool _awaitingPrizeWalletRefresh = false;
  DateTime? _winnerWindowEndsAt;
  Timer? _winnerWindowTicker;
  LiveConnectionStatus _connectionStatus = LiveConnectionStatus.reconnecting;

  GamesRepository get _gamesRepository => ref.read(gamesRepositoryProvider);
  SocketService get _socketService => ref.read(socketServiceProvider);
  // Session ID used for API calls and socket event filtering.
  // null when the current game is a NEXT slot (no session yet).
  String? get _activeSessionId => _game?.sessionId ?? _joinedGameId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerSocketListeners();
    _syncConnectionStatus();
    unawaited(_loadInitialState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _winnerWindowTicker?.cancel();
    _removeSocketListeners();
    _switchJoinedGame(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverFromAppResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: FriendsBingoLoading(compact: true),
            )
          else if (_errorMessage != null)
            _LiveErrorState(message: _errorMessage!, onRetry: _refresh)
          else if (_game == null)
            _LiveInfoCard(
              title: 'No selected game',
              message:
                  _emptyMessage ??
                  'There is no active or upcoming game right now.',
            )
          else ...[
            if (_game!.isRegistrationOpen) ...[
              const RegistrationOpenPulse(),
              const SizedBox(height: 10),
            ] else if (_showsInlinePlayCartelas) ...[
              LiveStatusChip(connectionStatus: _connectionStatus),
              const SizedBox(height: 8),
            ] else ...[
              _LiveGameHeader(game: _game!),
              const SizedBox(height: 8),
              _ConnectionStatusChip(status: _connectionStatus),
              const SizedBox(height: 10),
            ],
            CollapsibleGameInfoBar(game: _game!),
            if (_game!.playerStatus == PlayerGameStatus.winnerWindow) ...[
              const SizedBox(height: 8),
              WinnerWindowCountdownChip(
                endsAt: _winnerWindowEndsAt ?? _game!.winnerWindowEndsAt,
              ),
            ],
            if (_buildLiveStatusBanner() case final banner?) ...[
              const SizedBox(height: 12),
              banner,
            ],
            if (!_game!.isRegistrationOpen &&
                !_showsInlinePlayCartelas &&
                _subtitleForRegisteredCartelas().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _subtitleForRegisteredCartelas(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_game?.isRegistrationOpen == true) const SizedBox(height: 10),
            if (_game?.isRegistrationOpen == true)
              _CartelaRegistrationPanel(
                slotId: _game!.id,
                sessionId: _game!.sessionId,
                gameStatus: _game!.status,
                entryFee: _game!.entryFee,
                prizePerCartela: _game!.prizePerCartela,
                registeredCartelas: _myCartelas,
                registeredCartelasSummary: _game!.registeredCartelasSummary,
                onRegistered: _handleCartelasRegistered,
                onSessionIdResolved: _handleRegistrationSessionResolved,
              )
            else if (_myCartelas.isEmpty)
              _LiveInfoCard(
                title: 'No registered cartelas',
                message: _canRegisterCartelas
                    ? 'Select cartela numbers above. You can register more than one as long as your wallet balance is enough.'
                    : 'Registration is closed for this live game right now.',
              )
            else if (_showsInlinePlayCartelas) ...[
              const SizedBox(height: 10),
              CalledNumbersStrip(calledNumbers: _calledNumbers),
              const SizedBox(height: 10),
              _InlineRegisteredCartelaList(
                cartelas: _myCartelas,
                canClaimBingoFor: _canClaimBingoForCartela,
                claimingCartelaIds: _claimingCartelaIds,
                pendingClaimCartelaIds: _pendingClaimCartelaIds,
                showManualReviewState: !_isAutomaticRule,
                manualMarkedNumbers: _manualMarkedNumbers,
                onMarkedNumberToggled: _toggleMarkedNumber,
                onClaimBingo: _claimBingo,
                winnerWindowEndsAt:
                    _winnerWindowEndsAt ?? _game!.winnerWindowEndsAt,
                showWinnerWindowSeconds:
                    _game!.playerStatus == PlayerGameStatus.winnerWindow,
              ),
            ]
            else
              _RegisteredCartelaList(cartelas: _myCartelas),
          ],
        ],
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live game')),
      body: body,
    );
  }

  bool get _canRegisterCartelas {
    final game = _game;
    return game != null && game.status.allowsRegistration;
  }

  bool get _showsInlinePlayCartelas {
    final status = _game?.playerStatus;
    return status == PlayerGameStatus.playing ||
        status == PlayerGameStatus.winnerWindow ||
        status == PlayerGameStatus.checking;
  }

  String _subtitleForRegisteredCartelas() {
    final game = _game;
    if (game == null) {
      return 'You do not have any registered cartelas for this game yet.';
    }

    // Use simplified player status for display
    return switch (game.playerStatus) {
      PlayerGameStatus.registrationOpen => _myCartelas.isEmpty
          ? 'Tap a cartela number below to register it. The round starts when the admin confirms.'
          : '${_myCartelas.length} cartela${_myCartelas.length == 1 ? '' : 's'} registered. Tap more numbers below to add.',
      PlayerGameStatus.playing => _myCartelas.isEmpty
          ? 'Registration is open - you can still join!'
          : 'Mark numbers on your cartelas below as they are called live. You can still register more.',
      PlayerGameStatus.winnerWindow =>
        'Valid bingo! Other players can still claim during the winner window.',
      PlayerGameStatus.checking =>
        'A bingo claim is being reviewed. Hold on — do not mark new numbers yet.',
      PlayerGameStatus.finished =>
        'This round is finished. Cartelas are shown for reference only.',
      PlayerGameStatus.cancelled => 'This round was cancelled.',
    };
  }

  Future<void> _loadInitialState({bool showLoading = true}) async {
    if (showLoading || _game == null) {
      setState(() {
        _isLoading = showLoading;
        _errorMessage = null;
        if (showLoading) {
          _emptyMessage = null;
        }
      });
    }

    try {
      final game = await _loadGame();
      if (!mounted) {
        return;
      }

      if (game == null) {
        _switchJoinedGame(null);
        setState(() {
          _game = null;
          _calledNumbers = const [];
          _myCartelas = const [];
          _claimingCartelaIds.clear();
          _processedClaimedIds.clear();
          _processedResolvedClaimIds.clear();
          _processedCalledNumberIds.clear();
          _pendingClaimCartelaIds.clear();
          _manualMarkedNumbers.clear();
          _marksSessionId = null;
          _emptyMessage =
              'No game is open right now. Pull down to refresh when the next round starts.';
          _isLoading = false;
        });
        return;
      }

      // Only join a socket room for active sessions (not for NEXT slots which
      // have no session yet — they arrive via games:public broadcasts).
      _switchJoinedGame(game.sessionId);

      List<CalledNumberModel> calledNumbers = const [];
      List<GameCartelaModel> myCartelas = const [];

      if (game.sessionId != null) {
        final results = await Future.wait<dynamic>([
          _gamesRepository.getCalledNumbers(game.sessionId!),
          _gamesRepository.getMyGameCartelas(game.sessionId!),
        ]);

        if (!mounted) {
          return;
        }

        final snapshot = results[0] as dynamic;
        myCartelas =
            List<GameCartelaModel>.from(results[1] as List<GameCartelaModel>)
              ..sort((left, right) {
                return left.cartela.number.compareTo(right.cartela.number);
              });
        calledNumbers = List<CalledNumberModel>.from(
          snapshot.calledNumbers as List<CalledNumberModel>,
        )..sort((left, right) => left.order.compareTo(right.order));
      }

      if (!mounted) {
        return;
      }

      if (game.sessionId != _marksSessionId) {
        _manualMarkedNumbers.clear();
        _marksSessionId = game.sessionId;
        _pendingClaimCartelaIds.clear();
      }

      setState(() {
        _game = game;
        _winnerWindowEndsAt = game.winnerWindowEndsAt;
        _calledNumbers = calledNumbers;
        _myCartelas = myCartelas;
        _processedCalledNumberIds
          ..clear()
          ..addAll(_calledNumbers.map((item) => item.id));
        _isLoading = false;
      });
      _syncWinnerWindowTicker();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (showLoading) {
          _game = null;
          _errorMessage = error is ApiException
              ? error.message
              : 'Could not load live game data.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _syncOperationsSnapshot() async {
    if (!mounted || _game == null) {
      return;
    }

    try {
      final operations = await _gamesRepository.getCurrentGameOperations();
      if (!mounted) {
        return;
      }

      final current = operations.currentGameForPlayer;
      if (current == null) {
        return;
      }

      if (current.id != _game!.id || current.sessionId != _game!.sessionId) {
        await _loadInitialState(showLoading: false);
        return;
      }

      final isTerminal =
          _game!.status == GameStatus.finished ||
          _game!.status == GameStatus.cancelled;

      setState(() {
        _game = _game!.copyWith(
          sessionId: current.sessionId ?? _game!.sessionId,
          prizeAmount: current.prizeAmount,
          registeredCartelasCount: isTerminal
              ? _game!.registeredCartelasCount
              : current.registeredCartelasCount,
          calledNumbersCount: current.calledNumbersCount,
          entryFee: current.entryFee,
          registeredCartelasSummary: isTerminal
              ? _game!.registeredCartelasSummary
              : current.registeredCartelasSummary,
          status: isTerminal ? _game!.status : current.status,
          winnerWindowEndsAt: current.winnerWindowEndsAt,
        );
      });
      _syncWinnerWindowTicker();

      if (current.sessionId != null && current.sessionId != _joinedGameId) {
        _switchJoinedGame(current.sessionId);
      }
    } catch (_) {
      // Keep the current UI if a background sync fails.
    }
  }

  void _syncConnectionStatus() {
    if (!mounted) {
      return;
    }

    final nextStatus = _socketService.isConnected
        ? LiveConnectionStatus.live
        : _socketService.hasActiveSocket
        ? LiveConnectionStatus.reconnecting
        : LiveConnectionStatus.offline;

    if (nextStatus == _connectionStatus) {
      return;
    }

    setState(() {
      _connectionStatus = nextStatus;
    });
  }

  Future<void> _recoverFromAppResume() async {
    if (!mounted) {
      return;
    }

    _syncConnectionStatus();
    ref.invalidate(currentGameOperationsProvider);
    ref.invalidate(myWalletProvider);

    final sessionId = _game?.sessionId;
    if (sessionId != null) {
      ref.invalidate(myGameCartelasProvider(sessionId));
      await Future.wait<void>([
        _refreshCalledNumbersSilently(),
        _refreshMyCartelasSilently(),
      ]);
    }

    await _loadInitialState(showLoading: false);
  }

  Future<void> _refreshCalledNumbersSilently() async {
    final sessionId = _game?.sessionId;
    if (sessionId == null || !mounted) {
      return;
    }

    try {
      final snapshot = await _gamesRepository.getCalledNumbers(sessionId);
      if (!mounted) {
        return;
      }

      setState(() {
        _calledNumbers = List<CalledNumberModel>.from(snapshot.calledNumbers)
          ..sort((left, right) => left.order.compareTo(right.order));
        _processedCalledNumberIds
          ..clear()
          ..addAll(_calledNumbers.map((item) => item.id));
      });
    } catch (_) {
      // Keep current called numbers if the silent refresh fails.
    }
  }

  Future<void> _refreshMyCartelasSilently() async {
    final sessionId = _game?.sessionId;
    if (sessionId == null || !mounted) {
      return;
    }

    try {
      final myCartelas = await _gamesRepository.getMyGameCartelas(sessionId);
      if (!mounted) {
        return;
      }

      setState(() {
        _myCartelas = myCartelas
          ..sort((left, right) {
            return left.cartela.number.compareTo(right.cartela.number);
          });
      });
    } catch (_) {
      // Keep current cartelas if the silent refresh fails.
    }
  }

  Future<GameModel?> _loadGame() async {
    // If a specific game/session was passed in via the widget, load it directly.
    final gameId = widget.gameId;
    if (gameId != null) {
      // Try as a session first; fall back to slot if not found.
      try {
        return await _gamesRepository.getSessionDetail(gameId);
      } catch (_) {
        return _gamesRepository.getSlotDetail(gameId);
      }
    }

    final operations =
        await ref.read(gamesRepositoryProvider).getCurrentGameOperations();
    return operations.currentGameForPlayer;
  }

  Future<void> _refreshGameData(String sessionId) async {
    final results = await Future.wait<dynamic>([
      _gamesRepository.getCalledNumbers(sessionId),
      _gamesRepository.getMyGameCartelas(sessionId),
    ]);

    if (!mounted) {
      return;
    }

    final calledNumbers = results[0] as dynamic;
    final myCartelas =
        List<GameCartelaModel>.from(results[1] as List<GameCartelaModel>)
          ..sort((left, right) {
            return left.cartela.number.compareTo(right.cartela.number);
          });

    setState(() {
      _calledNumbers = List<CalledNumberModel>.from(
        calledNumbers.calledNumbers as List<CalledNumberModel>,
      )..sort((left, right) => left.order.compareTo(right.order));
      _myCartelas = myCartelas;
      _processedCalledNumberIds
        ..clear()
        ..addAll(_calledNumbers.map((item) => item.id));
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(currentGameOperationsProvider);
    await _loadInitialState(showLoading: _game == null);
    ref.invalidate(myWalletProvider);
    final sid = _game?.sessionId;
    if (sid != null) {
      ref.invalidate(myGameCartelasProvider(sid));
    }
  }

  void _switchJoinedGame(String? gameId) {
    if (_joinedGameId == gameId) {
      return;
    }

    final previousGameId = _joinedGameId;
    _joinedGameId = gameId;

    if (previousGameId != null) {
      _socketService.leaveGame(previousGameId);
    }

    if (gameId != null) {
      _socketService.joinGame(gameId);
    }
  }

  void _registerSocketListeners() {
    _socketService.on('connect', _onSocketConnected);
    _socketService.on('disconnect', _onSocketDisconnected);
    _socketService.on('connect_error', _onSocketConnectError);
    _socketService.on('game:status_changed', _onGameStatusChanged);
    _socketService.on('slot:status_changed', _onSlotStatusChanged);
    _socketService.on('game:number_called', _onNumberCalled);
    _socketService.on('game:bingo_claimed', _onBingoClaimed);
    _socketService.on('game:bingo_valid', _onBingoValid);
    _socketService.on('game:bingo_invalid', _onBingoInvalid);
    _socketService.on('game:winner_window_started', _onWinnerWindowEvent);
    _socketService.on('game:winner_window_joined', _onWinnerWindowEvent);
    _socketService.on('game:finished', _onGameFinished);
    _socketService.on('session:prize_updated', _onSessionPrizeUpdated);
    _socketService.on('session:cartelas_updated', _onSessionCartelasUpdated);
    _socketService.on('my_cartela:registered', _onMyCartelaRegistered);
    _socketService.on('wallet:updated', _onWalletUpdated);
    _socketService.on('game:operation_updated', _onGameOperationUpdated);
    _socketService.on('slot:entry_fee_updated', _onSlotEntryFeeUpdated);
  }

  void _removeSocketListeners() {
    _socketService.off('connect', _onSocketConnected);
    _socketService.off('disconnect', _onSocketDisconnected);
    _socketService.off('connect_error', _onSocketConnectError);
    _socketService.off('game:status_changed', _onGameStatusChanged);
    _socketService.off('slot:status_changed', _onSlotStatusChanged);
    _socketService.off('game:number_called', _onNumberCalled);
    _socketService.off('game:bingo_claimed', _onBingoClaimed);
    _socketService.off('game:bingo_valid', _onBingoValid);
    _socketService.off('game:bingo_invalid', _onBingoInvalid);
    _socketService.off('game:winner_window_started', _onWinnerWindowEvent);
    _socketService.off('game:winner_window_joined', _onWinnerWindowEvent);
    _socketService.off('game:finished', _onGameFinished);
    _socketService.off('session:prize_updated', _onSessionPrizeUpdated);
    _socketService.off('session:cartelas_updated', _onSessionCartelasUpdated);
    _socketService.off('my_cartela:registered', _onMyCartelaRegistered);
    _socketService.off('wallet:updated', _onWalletUpdated);
    _socketService.off('game:operation_updated', _onGameOperationUpdated);
    _socketService.off('slot:entry_fee_updated', _onSlotEntryFeeUpdated);
  }

  // Called when a session status changes (PLAYING / CHECKING / FINISHED / CANCELLED).
  // Payload is a full serialized session object from the backend.
  void _onSocketConnected(dynamic _) {
    if (!mounted) {
      return;
    }

    _syncConnectionStatus();

    final joinedGameId = _joinedGameId;
    if (joinedGameId != null) {
      _socketService.joinGame(joinedGameId);
    }

    ref.invalidate(currentGameOperationsProvider);
    ref.invalidate(myWalletProvider);

    final sessionId = _game?.sessionId;
    if (sessionId != null) {
      ref.invalidate(myGameCartelasProvider(sessionId));
      unawaited(_refreshCalledNumbersSilently());
    }

    unawaited(_loadInitialState(showLoading: false));
  }

  void _onSocketDisconnected(dynamic _) {
    if (!mounted) {
      return;
    }

    _syncConnectionStatus();
  }

  void _onSocketConnectError(dynamic _) {
    if (!mounted) {
      return;
    }

    _syncConnectionStatus();
  }

  void _onGameStatusChanged(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final incomingGame = GameModel.fromSessionJson(payload);

    if (!_isTrackableLiveStatus(incomingGame.status)) {
      // Session finished or cancelled — reflect it immediately, then reload the
      // current live game so the player moves to the next available round.
      if (_game?.sessionId == incomingGame.sessionId) {
        setState(() {
          _game = _game!.copyWith(
            status: incomingGame.status,
            finishedAt: incomingGame.finishedAt,
            winnerCartelaId: incomingGame.winnerCartelaId,
          );
        });
        unawaited(_loadInitialState(showLoading: false));
      }
      return;
    }

    final activeSessionId = _activeSessionId;

    // If we have no active session (watching a NEXT slot) and a new session
    // just started, reload so we pick up the live session and join its room.
    if (activeSessionId == null) {
      unawaited(_loadInitialState(showLoading: false));
      return;
    }

    // Ignore events for a different session.
    if (incomingGame.sessionId != activeSessionId) {
      return;
    }

    final previousStatus = _game!.status;
    setState(() {
      _game = incomingGame;
      _winnerWindowEndsAt = incomingGame.winnerWindowEndsAt;
    });
    _syncWinnerWindowTicker();

    if (previousStatus != incomingGame.status) {
      unawaited(_refreshGameData(incomingGame.sessionId!));
    }
  }

  // Called when a slot status changes (NEXT / CANCELLED / FINISHED / etc).
  // Reload on any status change to ensure live sync.
  void _onSlotStatusChanged(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final slotId = payload['id'] as String? ?? payload['slotId'] as String?;
    if (slotId == null) return;

    // Reload for any status change affecting the current game
    if (_game?.id == slotId || _game?.sessionId == payload['sessionId']) {
      unawaited(_loadInitialState(showLoading: false));
    }
  }

  bool _isTrackableLiveStatus(GameStatus status) {
    return status == GameStatus.next ||
        status == GameStatus.ready ||
        status == GameStatus.playing ||
        status == GameStatus.winnerWindow ||
        status == GameStatus.checking;
  }

  void _onNumberCalled(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['gameSessionId'] != _activeSessionId) {
      return;
    }

    final calledNumber = CalledNumberModel.fromJson(payload);
    if (_processedCalledNumberIds.contains(calledNumber.id)) {
      return;
    }

    setState(() {
      _processedCalledNumberIds.add(calledNumber.id);
      _calledNumbers = [..._calledNumbers, calledNumber]
        ..sort((left, right) => left.order.compareTo(right.order));
    });
  }

  void _onBingoClaimed(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['sessionId'] != _activeSessionId) {
      return;
    }

    final claimId = payload['claimId'] as String?;
    if (claimId == null || _processedClaimedIds.contains(claimId)) {
      return;
    }

    _processedClaimedIds.add(claimId);

    final gameCartelaId = payload['gameCartelaId'] as String?;
    if (gameCartelaId != null) {
      setState(() {
        _pendingClaimCartelaIds.add(gameCartelaId);
      });
    }

    // Claim feedback is shown once from the Bingo button action.
  }

  void _onBingoValid(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['sessionId'] != _activeSessionId) {
      return;
    }

    final claimId = payload['claimId'] as String?;
    if (claimId == null || _processedResolvedClaimIds.contains(claimId)) {
      return;
    }

    _processedResolvedClaimIds.add(claimId);
    final gameCartelaId = payload['gameCartelaId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;

    setState(() {
      if (gameCartelaId != null) {
        _pendingClaimCartelaIds.remove(gameCartelaId);
      }
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id != gameCartelaId) {
              return cartela;
            }

            return cartela.copyWith(
              status: GameCartelaStatus.winner,
              isWinner: true,
              blockedAt: null,
            );
          })
          .toList(growable: false);
    });

    if (payload['userId'] == currentUserId) {
      _awaitingPrizeWalletRefresh = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _winnerMessage(
              includeWalletHint: true,
              prizeAmount: _game?.prizeAmount,
            ),
          ),
        ),
      );
    }
  }

  void _onWinnerWindowEvent(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['sessionId'] != _activeSessionId) {
      return;
    }

    final endsAtRaw = payload['winnerWindowEndsAt'];
    final endsAt = endsAtRaw is String ? DateTime.tryParse(endsAtRaw) : null;
    final gameCartelaId = payload['gameCartelaId'] as String?;
    final userId = payload['userId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;

    setState(() {
      _game = _game?.copyWith(status: GameStatus.winnerWindow);
      _winnerWindowEndsAt = endsAt ?? _winnerWindowEndsAt;
      if (gameCartelaId != null) {
        _myCartelas = _myCartelas
            .map((cartela) {
              if (cartela.id != gameCartelaId) {
                return cartela;
              }

              return cartela.copyWith(
                status: GameCartelaStatus.winner,
                isWinner: true,
                blockedAt: null,
              );
            })
            .toList(growable: false);
      }
    });
    _syncWinnerWindowTicker();

    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valid bingo! Winner window is open.'),
        ),
      );
    }
  }

  void _syncWinnerWindowTicker() {
    _winnerWindowTicker?.cancel();
    _winnerWindowTicker = null;

    if (_game?.status != GameStatus.winnerWindow || _winnerWindowEndsAt == null) {
      return;
    }

    _winnerWindowTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      if (_winnerWindowEndsAt == null ||
          DateTime.now().isAfter(_winnerWindowEndsAt!)) {
        _winnerWindowTicker?.cancel();
        return;
      }

      setState(() {});
    });
  }

  void _onBingoInvalid(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['sessionId'] != _activeSessionId) {
      return;
    }

    final claimId = payload['claimId'] as String?;
    if (claimId == null || _processedResolvedClaimIds.contains(claimId)) {
      return;
    }

    _processedResolvedClaimIds.add(claimId);
    final gameCartelaId = payload['gameCartelaId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;

    setState(() {
      if (gameCartelaId != null) {
        _pendingClaimCartelaIds.remove(gameCartelaId);
      }
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id != gameCartelaId) {
              return cartela;
            }

            return cartela.copyWith(
              status: GameCartelaStatus.blocked,
              isWinner: false,
              blockedAt: DateTime.now(),
            );
          })
          .toList(growable: false);
    });

    if (payload['userId'] == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_invalidBingoMessage),
        ),
      );
    }
  }

  void _onGameFinished(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    // The backend now sends a normalized slot payload for game:finished.
    // The payload has slot-level fields: id (slot ID), sessionId, status (slot
    // status = NEXT), finishedAt, winnerCartelaId from the latest session.
    final payloadSessionId = payload['sessionId'] as String?;
    if (payloadSessionId != _activeSessionId || _game == null) {
      return;
    }

    final winnerCartelaId = payload['winnerCartelaId'] as String?;
    final finishedAtRaw = payload['finishedAt'];
    final finishedAt = finishedAtRaw is String
        ? DateTime.tryParse(finishedAtRaw)
        : finishedAtRaw is DateTime
        ? finishedAtRaw
        : DateTime.now();

    final didWin = _myCartelas.any((cartela) => cartela.isWinner);
    final winnerPayoutsSummary = WinnerPayoutSummary.parseList(
      payload['winnerPayoutsSummary'],
    );

    setState(() {
      _game = _game!.copyWith(
        status: GameStatus.finished,
        finishedAt: finishedAt,
        winnerCartelaId: winnerCartelaId,
        winnerPayoutsSummary: winnerPayoutsSummary,
      );
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.isWinner || cartela.id == winnerCartelaId) {
              return cartela.copyWith(
                status: GameCartelaStatus.winner,
                isWinner: true,
                blockedAt: null,
              );
            }
            return cartela;
          })
          .toList(growable: false);
      _pendingClaimCartelaIds.clear();
      _manualMarkedNumbers.clear();
    });

    unawaited(_refreshMyCartelasSilently());

    // Show winner/loser message briefly, then refetch next game
    _showGameFinishedSnackbar(didWin: didWin);

    // Auto-refetch after 3 seconds to show next upcoming game
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        unawaited(_loadInitialState(showLoading: false));
      }
    });
  }

  void _showGameFinishedSnackbar({required bool didWin}) {
    final game = _game;
    if (game == null) return;

    if (didWin) {
      final myPayoutAmount = _myWinnerPayoutAmount(game);
      final message = myPayoutAmount != null
          ? '🎉 You won ${formatMoney(myPayoutAmount)} ETB'
          : 'You won! Prize is being updated.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('Game finished. Better luck next time!'),
        ),
      );
    }
  }

  void _onSessionPrizeUpdated(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final sessionId = payload['sessionId'] as String? ?? payload['id'] as String?;
    if (sessionId == null || sessionId != _activeSessionId) {
      return;
    }

    // Update prize amount and registered cartelas count from payload immediately
    final prizeAmount = payload['prizeAmount']?.toString();
    final registeredCartelasCount = payload['registeredCartelasCount'] as int?;
    final calledNumbersCount = payload['calledNumbersCount'] as int?;

    setState(() {
      if (_game != null) {
        _game = _game!.copyWith(
          prizeAmount: prizeAmount ?? _game!.prizeAmount,
          registeredCartelasCount:
              registeredCartelasCount ?? _game!.registeredCartelasCount,
          calledNumbersCount:
              calledNumbersCount ?? _game!.calledNumbersCount,
        );
      }
    });

    ref.invalidate(currentGameOperationsProvider);
    // Also refresh my cartelas to ensure we have latest data
    unawaited(_refreshGameData(sessionId));
  }

  // Called when any player reserves, registers, or releases a cartela hold.
  void _onSessionCartelasUpdated(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final sessionId = payload['sessionId'] as String?;
    final slotId = payload['slotId'] as String?;
    final game = _game;
    if (game == null) {
      return;
    }

    final matchesSession =
        sessionId != null &&
        (sessionId == _activeSessionId || game.sessionId == sessionId);
    final matchesSlot = slotId != null && slotId == game.id;

    if (!matchesSession && !matchesSlot) {
      return;
    }

    final prizeAmount = payload['prizeAmount']?.toString();
    final registeredCartelasCount = payload['registeredCartelasCount'] as int?;

    setState(() {
      _game = game.copyWith(
        sessionId: sessionId ?? game.sessionId,
        prizeAmount: prizeAmount ?? game.prizeAmount,
        registeredCartelasCount:
            registeredCartelasCount ?? game.registeredCartelasCount,
      );
    });

    if (sessionId != null && sessionId != _joinedGameId) {
      _switchJoinedGame(sessionId);
    }

    ref.invalidate(currentGameOperationsProvider);
    unawaited(_syncOperationsSnapshot());
  }

  // Called when current user successfully registers a cartela
  void _onMyCartelaRegistered(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final sessionId = payload['sessionId'] as String?;
    if (sessionId == null || sessionId != _activeSessionId) {
      return;
    }

    // Update prize amount and registered count
    final prizeAmount = payload['prizeAmount']?.toString();
    final registeredCartelasCount = payload['registeredCartelasCount'] as int?;

    setState(() {
      if (_game != null) {
        _game = _game!.copyWith(
          prizeAmount: prizeAmount ?? _game!.prizeAmount,
          registeredCartelasCount:
              registeredCartelasCount ?? _game!.registeredCartelasCount,
        );
      }
    });

    ref.invalidate(myWalletProvider);
    ref.invalidate(currentGameOperationsProvider);
    final sid = _game?.sessionId;
    if (sid != null) {
      ref.invalidate(myGameCartelasProvider(sid));
    }
    unawaited(_refreshMyCartelasSilently());
    unawaited(_syncOperationsSnapshot());
  }

  void _onWalletUpdated(dynamic payload) {
    if (_awaitingPrizeWalletRefresh && mounted) {
      _awaitingPrizeWalletRefresh = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _winnerMessage(
              includeWalletHint: false,
              prizeAmount: _game?.prizeAmount,
            ),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onGameOperationUpdated(dynamic payload) {
    if (!mounted) {
      return;
    }

    ref.invalidate(currentGameOperationsProvider);
    unawaited(_loadInitialState(showLoading: false));

    if (payload is Map<String, dynamic> &&
        payload['updatedReason'] == 'number_called') {
      unawaited(_refreshCalledNumbersSilently());
    }
  }

  void _onSlotEntryFeeUpdated(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final slotId = payload['id'] as String?;
    if (slotId == null || _game?.id != slotId) {
      return;
    }

    final entryFee = payload['entryFee'] as String?;
    if (entryFee != null && _game != null) {
      setState(() {
        _game = _game!.copyWith(entryFee: entryFee);
      });
    }

    ref.invalidate(currentGameOperationsProvider);
  }

  bool _canClaimBingoForCartela(GameCartelaModel gameCartela) {
    final game = _game;
    if (game == null ||
        (game.status != GameStatus.playing &&
            game.status != GameStatus.winnerWindow)) {
      return false;
    }

    if (gameCartela.status == GameCartelaStatus.blocked ||
        gameCartela.status == GameCartelaStatus.cancelled ||
        gameCartela.isWinner) {
      return false;
    }

    if (_pendingClaimCartelaIds.contains(gameCartela.id)) {
      return false;
    }

    return true;
  }

  Future<void> _claimBingo(GameCartelaModel gameCartela) async {
    final sessionId = _activeSessionId;
    if (sessionId == null || _claimingCartelaIds.contains(gameCartela.id)) {
      return;
    }

    setState(() {
      _claimingCartelaIds.add(gameCartela.id);
    });

    try {
      final result = await _gamesRepository.claimBingo(
        sessionId: sessionId,
        gameCartelaId: gameCartela.id,
      );

      if (!mounted) {
        return;
      }

      if (result.gameCartelaStatus == GameCartelaStatus.blocked) {
        setState(() {
          _processedResolvedClaimIds.add(result.claim.id);
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.id != gameCartela.id) {
                  return cartela;
                }

                return cartela.copyWith(
                  status: GameCartelaStatus.blocked,
                  isWinner: false,
                  blockedAt: DateTime.now(),
                );
              })
              .toList(growable: false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_invalidBingoMessage),
          ),
        );
        return;
      }

      if (result.isWinner && result.gameStatus == GameStatus.winnerWindow) {
        setState(() {
          _processedResolvedClaimIds.add(result.claim.id);
          _game = _game?.copyWith(status: GameStatus.winnerWindow);
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.id != gameCartela.id) {
                  return cartela;
                }

                return cartela.copyWith(
                  status: GameCartelaStatus.winner,
                  isWinner: true,
                  blockedAt: null,
                );
              })
              .toList(growable: false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_validBingoAcceptedMessage),
          ),
        );
        return;
      }

      setState(() {
        _processedClaimedIds.add(result.claim.id);
        _pendingClaimCartelaIds.add(gameCartela.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.claim.reason ?? 'Waiting for admin confirmation',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (error is ApiException && error.isConnectivityFailure) {
        final recovered = await _recoverClaimAfterConnectivityFailure(
          sessionId: sessionId,
          gameCartela: gameCartela,
        );
        if (recovered) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not submit bingo claim.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _claimingCartelaIds.remove(gameCartela.id);
        });
      }
    }
  }

  Future<bool> _recoverClaimAfterConnectivityFailure({
    required String sessionId,
    required GameCartelaModel gameCartela,
  }) async {
    try {
      final myCartelas = await _gamesRepository.getMyGameCartelas(sessionId);
      if (!mounted) {
        return true;
      }

      GameCartelaModel? refreshed;
      for (final cartela in myCartelas) {
        if (cartela.id == gameCartela.id) {
          refreshed = cartela;
          break;
        }
      }

      if (refreshed == null) {
        return false;
      }

      final resolvedCartela = refreshed;

      if (resolvedCartela.isWinner ||
          resolvedCartela.status == GameCartelaStatus.winner) {
        setState(() {
          _game = _game?.copyWith(status: GameStatus.winnerWindow);
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.id != gameCartela.id) {
                  return cartela;
                }

                return resolvedCartela.copyWith(
                  status: GameCartelaStatus.winner,
                  isWinner: true,
                  blockedAt: null,
                );
              })
              .toList(growable: false);
        });

        if (!mounted) {
          return true;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_validBingoAcceptedMessage)),
        );
        return true;
      }

      if (resolvedCartela.status == GameCartelaStatus.blocked) {
        setState(() {
          _myCartelas = _myCartelas
              .map((cartela) {
                if (cartela.id != gameCartela.id) {
                  return cartela;
                }

                return resolvedCartela;
              })
              .toList(growable: false);
        });

        if (!mounted) {
          return true;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_invalidBingoMessage)),
        );
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  void _handleRegistrationSessionResolved(String sessionId) {
    if (!mounted || _game == null || _game!.sessionId == sessionId) {
      return;
    }

    setState(() {
      _game = _game!.copyWith(sessionId: sessionId);
    });
    _switchJoinedGame(sessionId);
  }

  void _handleCartelasRegistered(List<GameCartelaModel> registeredCartelas) {
    if (!mounted || registeredCartelas.isEmpty) {
      return;
    }

    final game = _game;
    if (game == null) {
      return;
    }

    setState(() {
      _myCartelas =
          _mergeRegisteredCartelas(
            current: _myCartelas,
            incoming: registeredCartelas,
          )..sort((left, right) {
            return left.cartela.number.compareTo(right.cartela.number);
          });
    });

    ref.invalidate(currentGameOperationsProvider);
    ref.invalidate(myWalletProvider);
    final sid = game.sessionId;
    if (sid != null) {
      ref.invalidate(myGameCartelasProvider(sid));
    }
    unawaited(_syncOperationsSnapshot());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          registeredCartelas.length == 1
              ? 'Cartela registered successfully.'
              : '${registeredCartelas.length} cartelas registered successfully.',
        ),
      ),
    );
  }

  void _toggleMarkedNumber(String header, String value) {
    setState(() {
      final next = toggleManualMarkedNumber(
        manualMarkedNumbers: _manualMarkedNumbers,
        header: header,
        value: value,
      );
      _manualMarkedNumbers
        ..clear()
        ..addAll(next);
    });
  }

  List<GameCartelaModel> _mergeRegisteredCartelas({
    required List<GameCartelaModel> current,
    required List<GameCartelaModel> incoming,
  }) {
    final byId = <String, GameCartelaModel>{
      for (final cartela in current) cartela.id: cartela,
    };

    for (final cartela in incoming) {
      byId[cartela.id] = cartela;
    }

    return byId.values.toList(growable: false);
  }

  Widget? _buildLiveStatusBanner() {
    final game = _game;
    if (game == null) {
      return null;
    }

    // Use simplified player status for display
    return switch (game.playerStatus) {
      PlayerGameStatus.registrationOpen => null,
      PlayerGameStatus.playing => null,
      PlayerGameStatus.winnerWindow => null,
      PlayerGameStatus.checking => null,
      PlayerGameStatus.finished => _didCurrentUserWin()
          ? _LiveStatusBanner(
              color: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              title: 'You Won!',
              message: _finishedWinnerBannerMessage(game),
            )
          : _LiveStatusBanner(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              title: 'Game Finished',
              message: 'This game is finished. Better luck next time!',
            ),
      PlayerGameStatus.cancelled => _LiveStatusBanner(
        color: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        title: 'Game Cancelled',
        message: 'This game was cancelled by the admin.',
      ),
    };
  }

  bool _didCurrentUserWin() {
    return _myCartelas.any((cartela) => cartela.isWinner);
  }

  Set<String> get _myCartelaIds =>
      _myCartelas.map((cartela) => cartela.cartelaId).toSet();

  String? _myWinnerPayoutAmount(GameModel game) {
    return game.myWinnerPayoutAmount(_myCartelaIds);
  }

  bool get _isAutomaticRule => _game?.isAutomaticRule ?? true;

  String get _invalidBingoMessage => _isAutomaticRule
      ? 'Not a valid Bingo. This cartela is blocked.'
      : 'Invalid bingo claim. This cartela is blocked.';

  String get _validBingoAcceptedMessage =>
      'Bingo accepted. Waiting 15 seconds for other winners.';

  String _finishedWinnerBannerMessage(GameModel game) {
    final myPayoutAmount = _myWinnerPayoutAmount(game);
    if (myPayoutAmount != null) {
      return 'Congratulations! You won ${formatMoney(myPayoutAmount)} ETB.';
    }

    return 'Congratulations! Your cartela won. Prize is being updated.';
  }

  String _winnerMessage({
    required bool includeWalletHint,
    required String? prizeAmount,
  }) {
    final prizeText = (prizeAmount != null && prizeAmount.isNotEmpty)
        ? ' ${formatMoney(prizeAmount)}'
        : '';

    if (includeWalletHint) {
      return 'Bingo approved! You won.$prizeText prize payout will reflect in your wallet shortly.';
    }

    return 'Prize received in wallet.$prizeText';
  }
}

class _LiveGameHeader extends StatelessWidget {
  const _LiveGameHeader({required this.game});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = _playerStatusColors(theme, game.playerStatus);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                game.codeLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: statusColors.background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            game.playerStatus.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: statusColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisteredCartelaList extends StatelessWidget {
  const _RegisteredCartelaList({required this.cartelas});

  final List<GameCartelaModel> cartelas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cartelas
          .map(
            (gameCartela) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RegisteredCartelaListTile(gameCartela: gameCartela),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InlineRegisteredCartelaList extends StatelessWidget {
  const _InlineRegisteredCartelaList({
    required this.cartelas,
    required this.canClaimBingoFor,
    required this.claimingCartelaIds,
    required this.pendingClaimCartelaIds,
    required this.showManualReviewState,
    required this.manualMarkedNumbers,
    required this.onMarkedNumberToggled,
    required this.onClaimBingo,
    this.winnerWindowEndsAt,
    this.showWinnerWindowSeconds = false,
  });

  final List<GameCartelaModel> cartelas;
  final bool Function(GameCartelaModel) canClaimBingoFor;
  final Set<String> claimingCartelaIds;
  final Set<String> pendingClaimCartelaIds;
  final bool showManualReviewState;
  final Set<String> manualMarkedNumbers;
  final void Function(String header, String value) onMarkedNumberToggled;
  final Future<void> Function(GameCartelaModel) onClaimBingo;
  final DateTime? winnerWindowEndsAt;
  final bool showWinnerWindowSeconds;

  int? _secondsRemaining() {
    if (!showWinnerWindowSeconds || winnerWindowEndsAt == null) {
      return null;
    }
    return winnerWindowEndsAt!
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 15);
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _secondsRemaining();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: cartelas.length,
      itemBuilder: (context, index) {
        final gameCartela = cartelas[index];
        return LiveCartelaCard(
          gameCartela: gameCartela,
          canClaimBingo: canClaimBingoFor(gameCartela),
          isClaiming: claimingCartelaIds.contains(gameCartela.id),
          pendingReview: showManualReviewState &&
              pendingClaimCartelaIds.contains(gameCartela.id),
          manualMarkedNumbers: manualMarkedNumbers,
          onMarkedNumberToggled: onMarkedNumberToggled,
          onClaimBingo: () => onClaimBingo(gameCartela),
          winnerWindowSeconds: seconds,
        );
      },
    );
  }
}

class _RegisteredCartelaListTile extends StatelessWidget {
  const _RegisteredCartelaListTile({required this.gameCartela});

  final GameCartelaModel gameCartela;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = _cartelaStatusColors(theme, gameCartela.status);
    final statusLabel = gameCartela.isWinner
        ? 'Winner'
        : gameCartela.status == GameCartelaStatus.blocked
        ? 'Blocked / Invalid Bingo'
        : gameCartela.status.label;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${gameCartela.cartela.number}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartela ${gameCartela.cartela.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColors.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: statusColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCartelaReservation {
  const _PendingCartelaReservation({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.expiresAt,
  });

  final String cartelaId;
  final int cartelaNumber;
  final DateTime expiresAt;
}

class _CartelaRegistrationPanel extends ConsumerStatefulWidget {
  const _CartelaRegistrationPanel({
    required this.slotId,
    required this.sessionId,
    required this.gameStatus,
    required this.entryFee,
    required this.prizePerCartela,
    required this.registeredCartelas,
    required this.onRegistered,
    this.registeredCartelasSummary,
    this.onSessionIdResolved,
  });

  final String slotId;
  final String? sessionId;
  final GameStatus gameStatus;
  final String entryFee;
  final String prizePerCartela;
  final List<GameCartelaModel> registeredCartelas;
  final List<RegisteredCartelaSummary>? registeredCartelasSummary;
  final ValueChanged<List<GameCartelaModel>> onRegistered;
  final ValueChanged<String>? onSessionIdResolved;

  @override
  ConsumerState<_CartelaRegistrationPanel> createState() =>
      _CartelaRegistrationPanelState();
}

class _CartelaRegistrationPanelState
    extends ConsumerState<_CartelaRegistrationPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _cartelaSheetOpen = false;
  final Map<String, _PendingCartelaReservation> _pendingReservations = {};
  Timer? _pendingReservationTicker;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query == _searchQuery) {
        return;
      }
      setState(() {
        _searchQuery = query;
      });
    });
    _pendingReservationTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _pruneExpiredPendingReservations();
    });
  }

  @override
  void didUpdateWidget(covariant _CartelaRegistrationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pendingReservations.isEmpty) {
      return;
    }

    final summary = widget.registeredCartelasSummary ?? const [];
    final stalePendingIds = <String>[];
    for (final cartelaId in _pendingReservations.keys) {
      for (final item in summary) {
        if (item.cartelaId == cartelaId &&
            (item.isMine ||
                item.isTaken ||
                item.isReservedByMe ||
                item.isReservedByOther)) {
          stalePendingIds.add(cartelaId);
          break;
        }
      }
    }

    if (stalePendingIds.isEmpty) {
      return;
    }

    setState(() {
      for (final cartelaId in stalePendingIds) {
        _pendingReservations.remove(cartelaId);
      }
    });
  }

  @override
  void dispose() {
    _pendingReservationTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _pruneExpiredPendingReservations() {
    if (_pendingReservations.isEmpty || !mounted) {
      return;
    }

    final now = DateTime.now();
    final expiredIds = _pendingReservations.entries
        .where((entry) => !entry.value.expiresAt.isAfter(now))
        .map((entry) => entry.key)
        .toList(growable: false);

    if (expiredIds.isEmpty) {
      return;
    }

    setState(() {
      for (final cartelaId in expiredIds) {
        _pendingReservations.remove(cartelaId);
      }
    });
  }

  void _clearPendingReservation(String cartelaId) {
    if (!_pendingReservations.containsKey(cartelaId)) {
      return;
    }

    setState(() {
      _pendingReservations.remove(cartelaId);
    });
  }

  List<RegisteredCartelaSummary> _effectiveRegisteredCartelasSummary() {
    final serverSummary = widget.registeredCartelasSummary ?? const [];
    final merged = <String, RegisteredCartelaSummary>{
      for (final summary in serverSummary) summary.cartelaId: summary,
    };

    for (final pending in _pendingReservations.values) {
      final existing = merged[pending.cartelaId];
      if (existing != null &&
          (existing.isMine ||
              existing.isTaken ||
              existing.isReservedByOther)) {
        continue;
      }

      merged[pending.cartelaId] = RegisteredCartelaSummary(
        cartelaId: pending.cartelaId,
        cartelaNumber: pending.cartelaNumber,
        owner: 'RESERVED_ME',
        status: 'RESERVED',
        expiresAt: pending.expiresAt,
      );
    }

    return merged.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cartelasAsync = ref.watch(cartelasProvider);
    final walletAsync = ref.watch(myWalletProvider);
    final wallet = walletAsync is AsyncData<WalletModel>
        ? walletAsync.value
        : null;
    final registeredNumbers =
        widget.registeredCartelas
            .map((cartela) => cartela.cartela.number)
            .toList(growable: false)
          ..sort();
    final theme = Theme.of(context);
    final listHeight = MediaQuery.sizeOf(context).height.clamp(520, 900) * 0.42;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegistrationSummaryCard(
          registeredNumbers: registeredNumbers,
          entryFee: widget.entryFee,
          walletBalance: wallet?.balance,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodySmall,
          decoration: InputDecoration(
            hintText: 'Search number',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: listHeight,
          child: cartelasAsync.when(
            data: (cartelas) {
              final options = _registerOptions(
                availableCartelas: cartelas,
                registeredCartelasSummary: _effectiveRegisteredCartelasSummary(),
              );

              if (options.isEmpty) {
                return const _LiveInfoCard(
                  title: 'No matches',
                  message: 'Try another number.',
                );
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.2,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];

                  return CartelaNumberChip(
                    number: option.cartela.number,
                    availability: option.availability,
                    reservationExpiresAt: option.reservationExpiresAt,
                    onTap: () => _openCartelaModal(option),
                  );
                },
              );
            },
            loading: () => const FriendsBingoLoading(compact: true),
            error: (error, _) => _LiveInfoCard(
              title: 'Could not load cartelas',
              message: error is ApiException
                  ? error.message
                  : 'Please try again.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCartelaModal(_RegisterCartelaOption option) async {
    if (option.availability != CartelaAvailability.available || _cartelaSheetOpen) {
      return;
    }

    final optimisticExpiresAt =
        DateTime.now().add(const Duration(seconds: 10));
    setState(() {
      _cartelaSheetOpen = true;
      _pendingReservations[option.cartela.id] = _PendingCartelaReservation(
        cartelaId: option.cartela.id,
        cartelaNumber: option.cartela.number,
        expiresAt: optimisticExpiresAt,
      );
    });

    final walletAsync = ref.read(myWalletProvider);
    final walletBalance = walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.balance
        : null;

    final repository = ref.read(gamesRepositoryProvider);
    final reservationFuture = widget.sessionId != null
        ? repository.reserveCartela(
            sessionId: widget.sessionId!,
            cartelaId: option.cartela.id,
          )
        : repository.reserveCartelaForSlot(
            slotId: widget.slotId,
            cartelaId: option.cartela.id,
          );

    unawaited(
      reservationFuture.then((reservation) {
        if (!mounted) {
          return;
        }

        widget.onSessionIdResolved?.call(reservation.gameSessionId);
        final pending = _pendingReservations[option.cartela.id];
        if (pending == null) {
          return;
        }

        setState(() {
          _pendingReservations[option.cartela.id] = _PendingCartelaReservation(
            cartelaId: pending.cartelaId,
            cartelaNumber: pending.cartelaNumber,
            expiresAt: reservation.expiresAt,
          );
        });
      }).catchError((_) {
        if (mounted) {
          _clearPendingReservation(option.cartela.id);
        }
      }),
    );

    GameCartelaModel? registeredCartela;
    try {
      registeredCartela = await showModalBottomSheet<GameCartelaModel?>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return CartelaRegistrationSheet(
            cartela: option.cartela,
            entryFee: widget.entryFee,
            walletBalance: walletBalance,
            slotId: widget.slotId,
            sessionId: widget.sessionId,
            reservationFuture: reservationFuture,
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _cartelaSheetOpen = false);
        if (registeredCartela == null) {
          _clearPendingReservation(option.cartela.id);
        }
      }
    }

    if (!mounted || registeredCartela == null) {
      return;
    }

    _clearPendingReservation(option.cartela.id);
    widget.onRegistered([registeredCartela]);
  }

  List<_RegisterCartelaOption> _registerOptions({
    required List<CartelaModel> availableCartelas,
    required List<RegisteredCartelaSummary>? registeredCartelasSummary,
  }) {
    // Build a map of cartelaId -> availability from the summary
    final availabilityMap = <String, CartelaAvailability>{};
    if (registeredCartelasSummary != null) {
      for (final summary in registeredCartelasSummary) {
        availabilityMap[summary.cartelaId] = _availabilityFromSummary(summary);
      }
    }

    final query = _searchQuery;

    return availableCartelas
        .where(
          (cartela) =>
              query.isEmpty || cartela.number.toString().contains(query),
        )
        .map((cartela) {
          RegisteredCartelaSummary? summary;
          if (registeredCartelasSummary != null) {
            for (final item in registeredCartelasSummary) {
              if (item.cartelaId == cartela.id) {
                summary = item;
                break;
              }
            }
          }

          return _RegisterCartelaOption(
            cartela: cartela,
            availability:
                availabilityMap[cartela.id] ?? CartelaAvailability.available,
            reservationExpiresAt: summary?.expiresAt,
          );
        })
        .toList(growable: false)
      ..sort((left, right) {
        return left.cartela.number.compareTo(right.cartela.number);
      });
  }
}

class _LiveErrorState extends StatelessWidget {
  const _LiveErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationSummaryCard extends StatelessWidget {
  const _RegistrationSummaryCard({
    required this.registeredNumbers,
    required this.entryFee,
    required this.walletBalance,
  });

  final List<int> registeredNumbers;
  final String entryFee;
  final String? walletBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableBalance = walletBalance == null
        ? null
        : _parseMoney(walletBalance!);
    final hasEnoughBalance =
        availableBalance == null || availableBalance >= _parseMoney(entryFee);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                formatMoney(entryFee),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (walletBalance != null) ...[
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  formatMoney(walletBalance!),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (registeredNumbers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: registeredNumbers
                  .map(
                    (number) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$number',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (!hasEnoughBalance) ...[
            const SizedBox(height: 6),
            Text(
              'Insufficient balance',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveInfoCard extends StatelessWidget {
  const _LiveInfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({
    required this.color,
    required this.foregroundColor,
    required this.title,
    required this.message,
  });

  final Color color;
  final Color foregroundColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

CartelaAvailability _availabilityFromSummary(RegisteredCartelaSummary summary) {
  if (summary.isMine) {
    return CartelaAvailability.mine;
  }
  if (summary.isTaken) {
    return CartelaAvailability.taken;
  }
  if (summary.isReservedByMe) {
    return CartelaAvailability.reservedByMe;
  }
  if (summary.isReservedByOther) {
    return CartelaAvailability.reservedByOther;
  }
  return CartelaAvailability.available;
}

class _RegisterCartelaOption {
  const _RegisterCartelaOption({
    required this.cartela,
    required this.availability,
    this.reservationExpiresAt,
  });

  final CartelaModel cartela;
  final CartelaAvailability availability;
  final DateTime? reservationExpiresAt;
}

double _parseMoney(String value) => double.tryParse(value.trim()) ?? 0;

({Color background, Color foreground}) _playerStatusColors(
  ThemeData theme,
  PlayerGameStatus status,
) {
  return switch (status) {
    PlayerGameStatus.registrationOpen => (
      background: theme.colorScheme.primaryContainer,
      foreground: theme.colorScheme.onPrimaryContainer,
    ),
    PlayerGameStatus.checking => (
      background: theme.colorScheme.tertiaryContainer,
      foreground: theme.colorScheme.onTertiaryContainer,
    ),
    PlayerGameStatus.playing => (
      background: theme.colorScheme.secondaryContainer,
      foreground: theme.colorScheme.onSecondaryContainer,
    ),
    PlayerGameStatus.winnerWindow => (
      background: theme.colorScheme.tertiaryContainer,
      foreground: theme.colorScheme.onTertiaryContainer,
    ),
    PlayerGameStatus.finished => (
      background: theme.colorScheme.surfaceContainerHighest,
      foreground: theme.colorScheme.onSurface,
    ),
    PlayerGameStatus.cancelled => (
      background: theme.colorScheme.errorContainer,
      foreground: theme.colorScheme.onErrorContainer,
    ),
  };
}

({Color background, Color foreground}) _cartelaStatusColors(
  ThemeData theme,
  GameCartelaStatus status,
) {
  return switch (status) {
    GameCartelaStatus.registered => (
      background: theme.colorScheme.surfaceContainerHighest,
      foreground: theme.colorScheme.onSurface,
    ),
    GameCartelaStatus.winner => (
      background: Colors.amber.shade100,
      foreground: Colors.amber.shade900,
    ),
    GameCartelaStatus.blocked => (
      background: theme.colorScheme.errorContainer,
      foreground: theme.colorScheme.onErrorContainer,
    ),
    GameCartelaStatus.cancelled => (
      background: theme.colorScheme.surfaceContainerHighest,
      foreground: theme.colorScheme.onSurface,
    ),
  };
}

class _ConnectionStatusChip extends StatelessWidget {
  const _ConnectionStatusChip({required this.status});

  final LiveConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (status) {
      LiveConnectionStatus.live => 'Live',
      LiveConnectionStatus.reconnecting => 'Reconnecting',
      LiveConnectionStatus.offline => 'Offline',
    };
    final color = switch (status) {
      LiveConnectionStatus.live => Colors.green.shade700,
      LiveConnectionStatus.reconnecting => Colors.orange.shade800,
      LiveConnectionStatus.offline => theme.colorScheme.error,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
