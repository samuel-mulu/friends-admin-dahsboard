import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/utils/formatters.dart';
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

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
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
  final Map<String, Set<String>> _manualMarkedCells = <String, Set<String>>{};
  bool _awaitingPrizeWalletRefresh = false;

  GamesRepository get _gamesRepository => ref.read(gamesRepositoryProvider);
  SocketService get _socketService => ref.read(socketServiceProvider);
  // Session ID used for API calls and socket event filtering.
  // null when the current game is a NEXT slot (no session yet).
  String? get _activeSessionId => _game?.sessionId ?? _joinedGameId;
  // Kept for places that still need any game/slot id.
  String? get _activeGameId => _game?.id ?? widget.gameId ?? _joinedGameId;

  @override
  void initState() {
    super.initState();
    _registerSocketListeners();
    unawaited(_loadInitialState());
  }

  @override
  void dispose() {
    _removeSocketListeners();
    _switchJoinedGame(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
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
            _LiveGameHeader(game: _game!),
            const SizedBox(height: 16),
            _GameFactsWrap(game: _game!),
            if (_buildLiveStatusBanner() case final banner?) ...[
              const SizedBox(height: 16),
              banner,
            ],
            const SizedBox(height: 16),
            if (_game!.status != GameStatus.next)
              _CalledNumbersBoard(calledNumbers: _calledNumbers),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My registered cartelas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_canRegisterCartelas)
                  IconButton.filledTonal(
                    onPressed: _showRegistrationBottomSheet,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Register new cartela',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _subtitleForRegisteredCartelas(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (_myCartelas.isEmpty)
              _LiveInfoCard(
                title: 'No registered cartelas',
                message: _canRegisterCartelas
                    ? 'Select cartela numbers above. You can register more than one as long as your wallet balance is enough.'
                    : 'Registration is closed for this live game right now.',
              )
            else if (_showsInlinePlayCartelas)
              _InlineRegisteredCartelaList(
                cartelas: _myCartelas,
                canClaimBingoFor: _canClaimBingoForCartela,
                claimingCartelaIds: _claimingCartelaIds,
                pendingClaimCartelaIds: _pendingClaimCartelaIds,
                manualMarkedCells: _manualMarkedCells,
                onMarkedCellsChanged: _setMarkedCells,
                onClaimBingo: _claimBingo,
              )
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
    final status = _game?.status;
    return status == GameStatus.playing || status == GameStatus.checking;
  }

  String _subtitleForRegisteredCartelas() {
    final game = _game;
    if (game == null) {
      return 'You do not have any registered cartelas for this game yet.';
    }

    if (_myCartelas.isEmpty) {
      return game.status == GameStatus.playing
          ? 'Register a cartela now — the game is live and registration is open.'
          : 'You do not have any registered cartelas for this game yet.';
    }

    return switch (game.status) {
      GameStatus.next =>
        'The round has not started yet. Cartela registration opens when the admin starts the game.',
      GameStatus.playing =>
        'Mark numbers on your cartelas below as they are called live. You can still register more.',
      GameStatus.checking =>
        'A bingo claim is being reviewed. Hold on — do not mark new numbers yet.',
      GameStatus.finished =>
        'This round is finished. Cartelas are shown for reference only.',
      GameStatus.cancelled => 'This round was cancelled.',
    };
  }

  Future<void> _loadInitialState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emptyMessage = null;
    });

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
          _manualMarkedCells.clear();
          _emptyMessage =
              'Waiting for the backend to open a NEXT, PLAYING, or CHECKING round.';
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

      setState(() {
        _game = game;
        _calledNumbers = calledNumbers;
        _myCartelas = myCartelas;
        _processedCalledNumberIds
          ..clear()
          ..addAll(_calledNumbers.map((item) => item.id));
        _manualMarkedCells.removeWhere(
          (cartelaId, _) =>
              !myCartelas.any((cartela) => cartela.id == cartelaId),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _game = null;
        _errorMessage = error is ApiException
            ? error.message
            : 'Could not load live game data.';
        _isLoading = false;
      });
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

    return ref.read(gamesRepositoryProvider).getCurrentLiveGame();
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
      _manualMarkedCells.removeWhere(
        (cartelaId, _) =>
            !myCartelas.any((cartela) => cartela.id == cartelaId),
      );
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(currentLiveGameProvider);
    await _loadInitialState();
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
    _socketService.on('game:status_changed', _onGameStatusChanged);
    _socketService.on('slot:status_changed', _onSlotStatusChanged);
    _socketService.on('game:number_called', _onNumberCalled);
    _socketService.on('game:bingo_claimed', _onBingoClaimed);
    _socketService.on('game:bingo_valid', _onBingoValid);
    _socketService.on('game:bingo_invalid', _onBingoInvalid);
    _socketService.on('game:finished', _onGameFinished);
    _socketService.on('wallet:updated', _onWalletUpdated);
  }

  void _removeSocketListeners() {
    _socketService.off('game:status_changed', _onGameStatusChanged);
    _socketService.off('slot:status_changed', _onSlotStatusChanged);
    _socketService.off('game:number_called', _onNumberCalled);
    _socketService.off('game:bingo_claimed', _onBingoClaimed);
    _socketService.off('game:bingo_valid', _onBingoValid);
    _socketService.off('game:bingo_invalid', _onBingoInvalid);
    _socketService.off('game:finished', _onGameFinished);
    _socketService.off('wallet:updated', _onWalletUpdated);
  }

  // Called when a session status changes (PLAYING / CHECKING / FINISHED / CANCELLED).
  // Payload is a full serialized session object from the backend.
  void _onGameStatusChanged(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final incomingGame = GameModel.fromSessionJson(payload);

    if (!_isTrackableLiveStatus(incomingGame.status)) {
      // Session finished or cancelled — clear if it was our current session.
      if (_game?.sessionId == incomingGame.sessionId) {
        setState(() {
          _game = _game!.copyWith(status: incomingGame.status);
        });
      }
      return;
    }

    final activeSessionId = _activeSessionId;

    // If we have no active session (watching a NEXT slot) and a new session
    // just started, reload so we pick up the live session and join its room.
    if (activeSessionId == null) {
      unawaited(_loadInitialState());
      return;
    }

    // Ignore events for a different session.
    if (incomingGame.sessionId != activeSessionId) {
      return;
    }

    final previousStatus = _game!.status;
    setState(() {
      _game = incomingGame;
    });

    if (previousStatus != incomingGame.status) {
      unawaited(_refreshGameData(incomingGame.sessionId!));
    }
  }

  // Called when a slot status changes (NEXT / CANCELLED).
  // When the current NEXT slot is cancelled, clear the display.
  void _onSlotStatusChanged(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    final slotId = payload['id'] as String?;
    if (slotId == null) return;

    // If we're watching this slot and it was cancelled, clear the display.
    final statusStr = payload['status'] as String?;
    if (statusStr != null &&
        statusStr.toUpperCase() == 'CANCELLED' &&
        _game?.id == slotId &&
        _game?.sessionId == null) {
      setState(() {
        _game = null;
        _calledNumbers = const [];
        _myCartelas = const [];
        _emptyMessage = 'This game slot was cancelled.';
      });
    }
  }

  bool _isTrackableLiveStatus(GameStatus status) {
    return status == GameStatus.next ||
        status == GameStatus.playing ||
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

    final userId = payload['userId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;
    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bingo claim received. Waiting for admin confirmation.',
          ),
        ),
      );
    }
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
      final reason = payload['reason'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason ?? 'Invalid bingo claim. This cartela is blocked.',
          ),
        ),
      );
    }
  }

  void _onGameFinished(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['sessionId'] != _activeSessionId || _game == null) {
      return;
    }

    setState(() {
      _game = _game!.copyWith(
        status: GameStatus.finished,
        finishedAt: payload['finishedAt'] is String
            ? DateTime.tryParse(payload['finishedAt'] as String)
            : DateTime.now(),
        winnerCartelaId: payload['winnerCartelaId'] as String?,
      );
      _myCartelas = _myCartelas
          .map((cartela) {
            if (cartela.id == _game!.winnerCartelaId) {
              return cartela.copyWith(
                status: GameCartelaStatus.winner,
                isWinner: true,
                blockedAt: null,
              );
            }

            return cartela;
          })
          .toList(growable: false);
    });
  }

  void _onWalletUpdated(dynamic payload) {
    ref.invalidate(myWalletProvider);

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

  bool _canClaimBingoForCartela(GameCartelaModel gameCartela) {
    final game = _game;
    if (game == null || game.status != GameStatus.playing) {
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

  void _showRegistrationBottomSheet() {
    final game = _game;
    if (game == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              child: _CartelaRegistrationPanel(
                sessionId: game.sessionId ?? game.id,
                entryFee: game.entryFee,
                registeredCartelas: _myCartelas,
                onRegistered: (registered) {
                  Navigator.of(context).pop();
                  _handleCartelasRegistered(registered);
                },
              ),
            );
          },
        );
      },
    );
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
      _game = _game?.copyWith(
        registeredCartelasCount:
            (_game?.registeredCartelasCount ?? 0) + registeredCartelas.length,
      );
    });

    ref.invalidate(currentLiveGameProvider);
    ref.invalidate(myWalletProvider);
    final sid = game.sessionId;
    if (sid != null) {
      ref.invalidate(myGameCartelasProvider(sid));
    }

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

  void _setMarkedCells(String gameCartelaId, Set<String> markedCells) {
    setState(() {
      _manualMarkedCells[gameCartelaId] = Set<String>.from(markedCells);
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

    if (game.status == GameStatus.next) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: 'Up next',
        message:
            'This game is queued and will start soon. Registration opens once the admin starts the round.',
      );
    }

    if (game.status == GameStatus.playing) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        title: 'Game in progress — registration open',
        message:
            'Numbers are being called live. Register your cartelas and mark them as numbers are announced.',
      );
    }

    if (game.status == GameStatus.checking) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        title: 'Checking bingo claim',
        message:
            'A bingo claim is under review. Wait for admin confirmation before another claim can continue.',
      );
    }

    if (_didCurrentUserWin()) {
      return _LiveStatusBanner(
        color: Colors.amber.shade100,
        foregroundColor: Colors.amber.shade900,
        title: 'Winner confirmed',
        message:
            'Backend confirmed your winning cartela.${game.prizeAmount.isNotEmpty ? ' Prize: ${formatMoney(game.prizeAmount)}.' : ''}',
      );
    }

    if (game.status == GameStatus.finished) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: 'Game finished',
        message:
            'This game is finished. Bingo claims are now disabled for all cartelas.',
      );
    }

    if (_pendingClaimCartelaIds.isNotEmpty) {
      return _LiveStatusBanner(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        title: 'Waiting for admin confirmation',
        message:
            'A bingo claim is pending manual review. The backend will confirm the result.',
      );
    }

    return null;
  }

  bool _didCurrentUserWin() {
    final winnerCartelaId = _game?.winnerCartelaId;
    if (winnerCartelaId == null) {
      return _myCartelas.any((cartela) => cartela.isWinner);
    }

    return _myCartelas.any(
      (cartela) => cartela.id == winnerCartelaId && cartela.isWinner,
    );
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
    final statusColors = _statusColors(theme, game.status);

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
                'Code ${game.code}',
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
            game.status.label,
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

class _GameFactsWrap extends StatelessWidget {
  const _GameFactsWrap({required this.game});

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _FactCard(label: 'Rule', value: game.ruleName),
        _FactCard(label: 'Order', value: game.playOrder?.toString() ?? '-'),
        _FactCard(label: 'Entry', value: '${game.entryFee} ETB'),
        _FactCard(label: 'Prize', value: '${game.prizeAmount} ETB'),
        _FactCard(
          label: 'Registered',
          value: '${game.registeredCartelasCount}',
        ),
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalledNumbersBoard extends StatelessWidget {
  const _CalledNumbersBoard({required this.calledNumbers});

  final List<CalledNumberModel> calledNumbers;

  @override
  Widget build(BuildContext context) {
    final orderedNumbers = calledNumbers.reversed.toList(growable: false);
    final latestCalledNumber = orderedNumbers.isEmpty
        ? null
        : orderedNumbers.first;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Called numbers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${calledNumbers.length} total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: _NumberBall(
                calledNumber: latestCalledNumber,
                size: 116,
                label: 'Latest',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Latest first',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (orderedNumbers.isEmpty)
              Text(
                'No numbers have been called yet.',
                style: theme.textTheme.bodyMedium,
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: orderedNumbers
                      .map(
                        (calledNumber) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _NumberBall(
                            calledNumber: calledNumber,
                            size: 56,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumberBall extends StatelessWidget {
  const _NumberBall({
    required this.calledNumber,
    required this.size,
    this.label,
  });

  final CalledNumberModel? calledNumber;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = calledNumber == null;
    final largeBall = size >= 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isEmpty
                  ? [
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.surfaceContainerLow,
                    ]
                  : [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.tertiaryContainer,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isEmpty
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: isEmpty
                ? Text(
                    '--',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        calledNumber!.letter,
                        style:
                            (largeBall
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.labelLarge)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${calledNumber!.number}',
                        style:
                            (largeBall
                                    ? theme.textTheme.headlineSmall
                                    : theme.textTheme.titleSmall)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
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
    required this.manualMarkedCells,
    required this.onMarkedCellsChanged,
    required this.onClaimBingo,
  });

  final List<GameCartelaModel> cartelas;
  final bool Function(GameCartelaModel) canClaimBingoFor;
  final Set<String> claimingCartelaIds;
  final Set<String> pendingClaimCartelaIds;
  final Map<String, Set<String>> manualMarkedCells;
  final void Function(String gameCartelaId, Set<String> markedCells)
  onMarkedCellsChanged;
  final Future<void> Function(GameCartelaModel) onClaimBingo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: cartelas
          .map(
            (gameCartela) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _InlineRegisteredCartelaCard(
                gameCartela: gameCartela,
                canClaimBingo: canClaimBingoFor(gameCartela),
                isClaiming: claimingCartelaIds.contains(gameCartela.id),
                pendingReview: pendingClaimCartelaIds.contains(gameCartela.id),
                markedCells:
                    manualMarkedCells[gameCartela.id] ?? const <String>{},
                onMarkedCellsChanged: (markedCells) {
                  onMarkedCellsChanged(gameCartela.id, markedCells);
                },
                onClaimBingo: () => onClaimBingo(gameCartela),
              ),
            ),
          )
          .toList(growable: false),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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

class _InlineRegisteredCartelaCard extends StatefulWidget {
  const _InlineRegisteredCartelaCard({
    required this.gameCartela,
    required this.canClaimBingo,
    required this.isClaiming,
    required this.pendingReview,
    required this.markedCells,
    required this.onMarkedCellsChanged,
    required this.onClaimBingo,
  });

  final GameCartelaModel gameCartela;
  final bool canClaimBingo;
  final bool isClaiming;
  final bool pendingReview;
  final Set<String> markedCells;
  final ValueChanged<Set<String>> onMarkedCellsChanged;
  final VoidCallback onClaimBingo;

  @override
  State<_InlineRegisteredCartelaCard> createState() =>
      _InlineRegisteredCartelaCardState();
}

class _InlineRegisteredCartelaCardState
    extends State<_InlineRegisteredCartelaCard> {
  late Set<String> _markedCells;

  @override
  void initState() {
    super.initState();
    _markedCells = Set<String>.from(widget.markedCells);
  }

  @override
  void didUpdateWidget(covariant _InlineRegisteredCartelaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markedCells != widget.markedCells) {
      _markedCells = Set<String>.from(widget.markedCells);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = _cartelaStatusColors(theme, widget.gameCartela.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cartela #${widget.gameCartela.cartela.number}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColors.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.gameCartela.isWinner
                        ? 'Winner'
                        : widget.gameCartela.status.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MarkedCartelaGrid(
              columns: widget.gameCartela.cartela.columns,
              markedCells: _markedCells,
              onToggleMarkedCell: _toggleMarkedCell,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap boxes to mark numbers as they are called.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.pendingReview) ...[
              const SizedBox(height: 12),
              Text(
                'Waiting for admin confirmation.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (widget.gameCartela.status == GameCartelaStatus.blocked) ...[
              const SizedBox(height: 12),
              Text(
                'Blocked / Invalid Bingo. This cartela cannot claim again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (widget.gameCartela.isWinner) ...[
              const SizedBox(height: 12),
              Text(
                'Winner confirmed and prize paid automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: widget.canClaimBingo && !widget.isClaiming
                    ? widget.onClaimBingo
                    : null,
                child: widget.isClaiming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bingo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMarkedCell({
    required int columnIndex,
    required int rowIndex,
    required String value,
  }) {
    if (value == 'FREE') {
      return;
    }

    final cellKey = '$columnIndex:$rowIndex';
    setState(() {
      if (_markedCells.contains(cellKey)) {
        _markedCells.remove(cellKey);
      } else {
        _markedCells.add(cellKey);
      }
    });
    widget.onMarkedCellsChanged(_markedCells);
  }
}

class _CartelaRegistrationPanel extends ConsumerStatefulWidget {
  const _CartelaRegistrationPanel({
    required this.sessionId,
    required this.entryFee,
    required this.registeredCartelas,
    required this.onRegistered,
  });

  final String sessionId;
  final String entryFee;
  final List<GameCartelaModel> registeredCartelas;
  final ValueChanged<List<GameCartelaModel>> onRegistered;

  @override
  ConsumerState<_CartelaRegistrationPanel> createState() =>
      _CartelaRegistrationPanelState();
}

class _CartelaRegistrationPanelState
    extends ConsumerState<_CartelaRegistrationPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartelasAsync = ref.watch(cartelasProvider);
    final walletAsync = ref.watch(myWalletProvider);
    final wallet = walletAsync is AsyncData<WalletModel>
        ? walletAsync.value
        : null;
    final registeredNumbers = widget.registeredCartelas
        .map((cartela) => cartela.cartela.number)
        .toList(growable: false)
      ..sort();
    final theme = Theme.of(context);
    final listHeight = MediaQuery.sizeOf(context).height.clamp(520, 900) * 0.42;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registration room',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scroll all cartela numbers, or search to narrow the list. Tap a number to preview and register.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _RegistrationSummaryCard(
              registeredNumbers: registeredNumbers,
              entryFee: widget.entryFee,
              walletBalance: wallet?.balance,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Search cartela number',
                hintText: 'Optional filter, e.g. 42',
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: listHeight,
              child: cartelasAsync.when(
                data: (cartelas) {
                  final options = _registerOptions(
                    availableCartelas: cartelas,
                    registeredCartelas: widget.registeredCartelas,
                  );

                  if (options.isEmpty) {
                    return const _LiveInfoCard(
                      title: 'No matches',
                      message:
                          'No cartela numbers match your search. Try another number.',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${options.length} cartela${options.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];

                            return _CartelaNumberChip(
                              number: option.cartela.number,
                              isRegistered: option.isRegistered,
                              onTap: () => _openCartelaModal(option),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _LiveInfoCard(
                  title: 'Could not load cartelas',
                  message: error is ApiException
                      ? error.message
                      : 'Please try again.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCartelaModal(_RegisterCartelaOption option) async {
    final walletAsync = ref.read(myWalletProvider);
    final walletBalance = walletAsync is AsyncData<WalletModel>
        ? walletAsync.value.balance
        : null;

    final registeredCartela =
        await showModalBottomSheet<GameCartelaModel?>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) {
            return _CartelaPreviewRegistrationSheet(
              cartela: option.cartela,
              entryFee: widget.entryFee,
              walletBalance: walletBalance,
              isRegistered: option.isRegistered,
              sessionId: widget.sessionId,
            );
          },
        );

    if (!mounted || registeredCartela == null) {
      return;
    }

    widget.onRegistered([registeredCartela]);
  }

  List<_RegisterCartelaOption> _registerOptions({
    required List<CartelaModel> availableCartelas,
    required List<GameCartelaModel> registeredCartelas,
  }) {
    final registeredIds = registeredCartelas
        .map((cartela) => cartela.cartela.id)
        .toSet();
    final query = _searchQuery;

    return availableCartelas
        .where(
          (cartela) =>
              query.isEmpty || cartela.number.toString().contains(query),
        )
        .map(
          (cartela) => _RegisterCartelaOption(
            cartela: cartela,
            isRegistered: registeredIds.contains(cartela.id),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) {
        return left.cartela.number.compareTo(right.cartela.number);
      });
  }
}

class _CartelaPreviewRegistrationSheet extends ConsumerStatefulWidget {
  const _CartelaPreviewRegistrationSheet({
    required this.cartela,
    required this.entryFee,
    required this.walletBalance,
    required this.isRegistered,
    required this.sessionId,
  });

  final CartelaModel cartela;
  final String entryFee;
  final String? walletBalance;
  final bool isRegistered;
  final String sessionId;

  @override
  ConsumerState<_CartelaPreviewRegistrationSheet> createState() =>
      _CartelaPreviewRegistrationSheetState();
}

class _CartelaPreviewRegistrationSheetState
    extends ConsumerState<_CartelaPreviewRegistrationSheet> {
  static const _autoCloseSeconds = 10;

  Timer? _autoCloseTimer;
  int _secondsRemaining = _autoCloseSeconds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isRegistered) {
      _startAutoCloseTimer();
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _startAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextValue = _secondsRemaining - 1;
      if (nextValue <= 0) {
        timer.cancel();
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _secondsRemaining = nextValue;
      });
    });
  }

  void _cancelTimer() {
    _autoCloseTimer?.cancel();
  }

  bool get _hasEnoughBalance {
    final balance = widget.walletBalance;
    if (balance == null) {
      return true;
    }

    return _parseMoney(balance) >= _parseMoney(widget.entryFee);
  }

  bool get _canRegister {
    return !widget.isRegistered && !_isSubmitting && _hasEnoughBalance;
  }

  Future<void> _register() async {
    if (!_canRegister) {
      return;
    }

    _cancelTimer();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final registeredCartela = await ref
          .read(gamesRepositoryProvider)
          .registerCartela(
            sessionId: widget.sessionId,
            cartelaId: widget.cartela.id,
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(myWalletProvider);
      Navigator.of(context).pop(registeredCartela);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not register this cartela.',
          ),
        ),
      );

      setState(() {
        _isSubmitting = false;
        _secondsRemaining = _autoCloseSeconds;
      });
      _startAutoCloseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cartela #${widget.cartela.number}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!widget.isRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_secondsRemaining}s',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.isRegistered
                  ? 'This cartela is already registered for you.'
                  : 'Preview this cartela and register before the timer closes.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _ReadOnlyCartelaPreview(columns: widget.cartela.columns),
            const SizedBox(height: 12),
            Text(
              'Entry fee: ${formatMoney(widget.entryFee)}',
              style: theme.textTheme.bodyMedium,
            ),
            if (widget.walletBalance != null) ...[
              const SizedBox(height: 4),
              Text(
                'Wallet balance: ${formatMoney(widget.walletBalance!)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (!widget.isRegistered && !_hasEnoughBalance) ...[
              const SizedBox(height: 8),
              Text(
                'Insufficient balance to register this cartela.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                if (!widget.isRegistered) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canRegister ? _register : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyCartelaPreview extends StatelessWidget {
  const _ReadOnlyCartelaPreview({required this.columns});

  final List<List<String>> columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const headers = ['B', 'I', 'N', 'G', 'O'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: List.generate(headers.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      headers[index],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
            ...List.generate(5, (rowIndex) {
              return Row(
                children: List.generate(headers.length, (columnIndex) {
                  final value = columns[columnIndex].length > rowIndex
                      ? columns[columnIndex][rowIndex]
                      : '';

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: value == 'FREE'
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MarkedCartelaGrid extends StatelessWidget {
  const _MarkedCartelaGrid({
    required this.columns,
    required this.markedCells,
    required this.onToggleMarkedCell,
  });

  final List<List<String>> columns;
  final Set<String> markedCells;
  final void Function({
    required int columnIndex,
    required int rowIndex,
    required String value,
  })
  onToggleMarkedCell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const headers = ['B', 'I', 'N', 'G', 'O'];

    return Column(
      children: [
        Row(
          children: List.generate(headers.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  headers[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ),
        ...List.generate(5, (rowIndex) {
          return Row(
            children: List.generate(headers.length, (columnIndex) {
              final value = columns[columnIndex].length > rowIndex
                  ? columns[columnIndex][rowIndex]
                  : '';
              final cellKey = '$columnIndex:$rowIndex';
              final isMarked = value == 'FREE' || markedCells.contains(cellKey);

              return Expanded(
                child: InkWell(
                  onTap: value == 'FREE'
                      ? null
                      : () => onToggleMarkedCell(
                          columnIndex: columnIndex,
                          rowIndex: rowIndex,
                          value: value,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isMarked
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isMarked
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isMarked
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
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
    final hasEnoughBalance = availableBalance == null ||
        availableBalance >= _parseMoney(entryFee);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registered cartelas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (registeredNumbers.isEmpty)
            Text(
              'No cartelas registered yet. Tap a number below to preview and register.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: registeredNumbers
                  .map(
                    (number) => Chip(
                      label: Text('#$number'),
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 12),
          Text(
            'Entry fee: ${formatMoney(entryFee)} each',
            style: theme.textTheme.bodyMedium,
          ),
          if (walletBalance != null) ...[
            const SizedBox(height: 4),
            Text(
              'Wallet balance: ${formatMoney(walletBalance!)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (!hasEnoughBalance) ...[
            const SizedBox(height: 8),
            Text(
              'Insufficient balance to register another cartela.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartelaNumberChip extends StatelessWidget {
  const _CartelaNumberChip({
    required this.number,
    required this.isRegistered,
    required this.onTap,
  });

  final int number;
  final bool isRegistered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final background = isRegistered
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerLow;
    final foreground = isRegistered
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRegistered
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$number',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isRegistered)
                Text(
                  'Ready',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
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

class _RegisterCartelaOption {
  const _RegisterCartelaOption({
    required this.cartela,
    required this.isRegistered,
  });

  final CartelaModel cartela;
  final bool isRegistered;
}

double _parseMoney(String value) => double.tryParse(value.trim()) ?? 0;

({Color background, Color foreground}) _statusColors(
  ThemeData theme,
  GameStatus status,
) {
  return switch (status) {
    GameStatus.next => (
      background: theme.colorScheme.primaryContainer,
      foreground: theme.colorScheme.onPrimaryContainer,
    ),
    GameStatus.checking => (
      background: theme.colorScheme.tertiaryContainer,
      foreground: theme.colorScheme.onTertiaryContainer,
    ),
    GameStatus.playing => (
      background: theme.colorScheme.secondaryContainer,
      foreground: theme.colorScheme.onSecondaryContainer,
    ),
    GameStatus.finished => (
      background: theme.colorScheme.surfaceContainerHighest,
      foreground: theme.colorScheme.onSurface,
    ),
    GameStatus.cancelled => (
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
