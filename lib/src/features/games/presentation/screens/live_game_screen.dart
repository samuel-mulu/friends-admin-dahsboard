import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/games_repository.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../providers/games_providers.dart';
import '../widgets/game_summary_card.dart';

class LiveGameScreen extends ConsumerStatefulWidget {
  const LiveGameScreen({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<LiveGameScreen> createState() => _LiveGameScreenState();
}

class _LiveGameScreenState extends ConsumerState<LiveGameScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  GameModel? _game;
  List<CalledNumberModel> _calledNumbers = const [];
  List<GameCartelaModel> _myCartelas = const [];
  final Set<String> _claimingCartelaIds = <String>{};
  final Set<String> _processedClaimIds = <String>{};
  final Set<String> _processedCalledNumberIds = <String>{};
  bool _awaitingPrizeWalletRefresh = false;

  GamesRepository get _gamesRepository => ref.read(gamesRepositoryProvider);
  SocketService get _socketService => ref.read(socketServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialState());
    _registerSocketListeners();
    _socketService.joinGame(widget.gameId);
  }

  @override
  void dispose() {
    _removeSocketListeners();
    _socketService.leaveGame(widget.gameId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live game')),
      body: RefreshIndicator(
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
              _LiveErrorState(
                message: _errorMessage!,
                onRetry: () => _refresh(),
              )
            else if (_game != null) ...[
              GameSummaryCard(game: _game!),
              if (_buildLiveStatusBanner() case final banner?) ...[
                const SizedBox(height: 16),
                banner,
              ],
              const SizedBox(height: 16),
              _LatestCalledNumberCard(
                latestCalledNumber: _calledNumbers.isEmpty
                    ? null
                    : _calledNumbers.last,
                totalCount: _calledNumbers.length,
              ),
              const SizedBox(height: 16),
              _CalledNumbersCard(calledNumbers: _calledNumbers),
              const SizedBox(height: 16),
              Text(
                'My registered cartelas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (_myCartelas.isEmpty)
                const _LiveInfoCard(
                  title: 'No registered cartelas',
                  message:
                      'Register a cartela for this game to play live from here.',
                )
              else
                ..._myCartelas.map(
                  (gameCartela) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LiveCartelaCard(
                      gameCartela: gameCartela,
                      calledNumbers: _calledNumbers,
                      canClaimBingo: _canClaimBingoForCartela(gameCartela),
                      isClaiming: _claimingCartelaIds.contains(gameCartela.id),
                      onClaimBingo: () => _claimBingo(gameCartela),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadInitialState() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _gamesRepository.getGameDetail(widget.gameId),
        _gamesRepository.getCalledNumbers(widget.gameId),
        _gamesRepository.getMyGameCartelas(widget.gameId),
      ]);

      if (!mounted) {
        return;
      }

      final calledNumbers = results[1] as dynamic;

      setState(() {
        _game = results[0] as GameModel;
        _calledNumbers = List<CalledNumberModel>.from(
          calledNumbers.calledNumbers as List<CalledNumberModel>,
        )..sort((left, right) => left.order.compareTo(right.order));
        _myCartelas = List<GameCartelaModel>.from(
          results[2] as List<GameCartelaModel>,
        );
        _processedCalledNumberIds
          ..clear()
          ..addAll(_calledNumbers.map((item) => item.id));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : 'Could not load live game data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadInitialState();
    ref.invalidate(gameDetailProvider(widget.gameId));
    ref.invalidate(myGameCartelasProvider(widget.gameId));
    ref.invalidate(myWalletProvider);
  }

  void _registerSocketListeners() {
    _socketService.on('game:status_changed', _onGameStatusChanged);
    _socketService.on('game:number_called', _onNumberCalled);
    _socketService.on('game:bingo_claimed', _onBingoClaimed);
    _socketService.on('game:bingo_valid', _onBingoValid);
    _socketService.on('game:bingo_invalid', _onBingoInvalid);
    _socketService.on('game:finished', _onGameFinished);
    _socketService.on('wallet:updated', _onWalletUpdated);
  }

  void _removeSocketListeners() {
    _socketService.off('game:status_changed', _onGameStatusChanged);
    _socketService.off('game:number_called', _onNumberCalled);
    _socketService.off('game:bingo_claimed', _onBingoClaimed);
    _socketService.off('game:bingo_valid', _onBingoValid);
    _socketService.off('game:bingo_invalid', _onBingoInvalid);
    _socketService.off('game:finished', _onGameFinished);
    _socketService.off('wallet:updated', _onWalletUpdated);
  }

  void _onGameStatusChanged(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['id'] != widget.gameId) {
      return;
    }

    setState(() {
      _game = GameModel.fromJson(payload);
    });
  }

  void _onNumberCalled(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['gameId'] != widget.gameId) {
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

    if (payload['gameId'] != widget.gameId) {
      return;
    }

    final claimId = payload['claimId'] as String?;
    if (claimId == null || _processedClaimIds.contains(claimId)) {
      return;
    }

    final userId = payload['userId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;
    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bingo claim received. Checking...')),
      );
    }
  }

  void _onBingoValid(dynamic payload) {
    if (!mounted || payload is! Map<String, dynamic>) {
      return;
    }

    if (payload['gameId'] != widget.gameId) {
      return;
    }

    final claimId = payload['claimId'] as String?;
    if (claimId == null || _processedClaimIds.contains(claimId)) {
      return;
    }

    _processedClaimIds.add(claimId);
    final gameCartelaId = payload['gameCartelaId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;

    setState(() {
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

    if (payload['gameId'] != widget.gameId) {
      return;
    }

    final claimId = payload['claimId'] as String?;
    if (claimId == null || _processedClaimIds.contains(claimId)) {
      return;
    }

    _processedClaimIds.add(claimId);
    final gameCartelaId = payload['gameCartelaId'] as String?;
    final currentUserId = ref.read(authControllerProvider).session?.user.id;

    setState(() {
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

    if (payload['gameId'] != widget.gameId || _game == null) {
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

    return true;
  }

  Future<void> _claimBingo(GameCartelaModel gameCartela) async {
    if (_claimingCartelaIds.contains(gameCartela.id)) {
      return;
    }

    setState(() {
      _claimingCartelaIds.add(gameCartela.id);
    });

    try {
      final result = await _gamesRepository.claimBingo(
        gameId: widget.gameId,
        gameCartelaId: gameCartela.id,
      );

      if (!mounted) {
        return;
      }

      _processedClaimIds.add(result.claim.id);
      setState(() {
        _myCartelas = _myCartelas
            .map((cartela) {
              if (cartela.id != gameCartela.id) {
                return cartela;
              }

              return cartela.copyWith(
                status: result.gameCartelaStatus,
                isWinner: result.isWinner,
                blockedAt: result.gameCartelaStatus == GameCartelaStatus.blocked
                    ? DateTime.now()
                    : null,
              );
            })
            .toList(growable: false);

        if (_game != null) {
          _game = _game!.copyWith(
            status: result.gameStatus,
            finishedAt: result.isWinner ? DateTime.now() : _game!.finishedAt,
            winnerCartelaId: result.isWinner
                ? gameCartela.id
                : _game!.winnerCartelaId,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isWinner
                ? _winnerMessage(
                    includeWalletHint: true,
                    prizeAmount: _game?.prizeAmount,
                  )
                : (result.claim.reason ?? 'Invalid bingo claim.'),
          ),
        ),
      );
      if (result.isWinner) {
        _awaitingPrizeWalletRefresh = true;
      }
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

  Widget? _buildLiveStatusBanner() {
    final game = _game;
    if (game == null) {
      return null;
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
      return 'Valid bingo! You won.$prizeText prize payout will reflect in your wallet shortly.';
    }

    return 'Prize received in wallet.$prizeText';
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

class _LatestCalledNumberCard extends StatelessWidget {
  const _LatestCalledNumberCard({
    required this.latestCalledNumber,
    required this.totalCount,
  });

  final CalledNumberModel? latestCalledNumber;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Latest called number',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              latestCalledNumber?.displayValue ?? '--',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('$totalCount numbers called'),
          ],
        ),
      ),
    );
  }
}

class _CalledNumbersCard extends StatelessWidget {
  const _CalledNumbersCard({required this.calledNumbers});

  final List<CalledNumberModel> calledNumbers;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Called numbers',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (calledNumbers.isEmpty)
              const Text('No numbers have been called yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: calledNumbers
                    .map(
                      (calledNumber) =>
                          Chip(label: Text(calledNumber.displayValue)),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveCartelaCard extends StatelessWidget {
  const _LiveCartelaCard({
    required this.gameCartela,
    required this.calledNumbers,
    required this.canClaimBingo,
    required this.isClaiming,
    required this.onClaimBingo,
  });

  final GameCartelaModel gameCartela;
  final List<CalledNumberModel> calledNumbers;
  final bool canClaimBingo;
  final bool isClaiming;
  final VoidCallback onClaimBingo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calledNumberSet = calledNumbers.map((item) => item.number).toSet();
    final statusPresentation = _statusPresentation(theme, gameCartela.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Cartela #${gameCartela.cartela.number}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusPresentation.backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusPresentation.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusPresentation.foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MarkedCartelaGrid(
              columns: gameCartela.cartela.columns,
              calledNumbers: calledNumberSet,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canClaimBingo && !isClaiming ? onClaimBingo : null,
              child: isClaiming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Bingo'),
            ),
            if (gameCartela.status == GameCartelaStatus.blocked) ...[
              const SizedBox(height: 8),
              Text(
                'Blocked / Invalid Bingo. This cartela cannot claim again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (gameCartela.isWinner) ...[
              const SizedBox(height: 8),
              Text(
                'Winner. Backend confirmed this cartela and paid the prize automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _CartelaStatusPresentation _statusPresentation(
    ThemeData theme,
    GameCartelaStatus status,
  ) {
    switch (status) {
      case GameCartelaStatus.registered:
        return _CartelaStatusPresentation(
          label: 'Registered',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
        );
      case GameCartelaStatus.winner:
        return _CartelaStatusPresentation(
          label: 'Winner',
          backgroundColor: Colors.amber.shade100,
          foregroundColor: Colors.amber.shade900,
        );
      case GameCartelaStatus.blocked:
        return _CartelaStatusPresentation(
          label: 'Blocked / Invalid Bingo',
          backgroundColor: theme.colorScheme.errorContainer,
          foregroundColor: theme.colorScheme.onErrorContainer,
        );
      case GameCartelaStatus.cancelled:
        return _CartelaStatusPresentation(
          label: 'Cancelled',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
        );
    }
  }
}

class _MarkedCartelaGrid extends StatelessWidget {
  const _MarkedCartelaGrid({
    required this.columns,
    required this.calledNumbers,
  });

  final List<List<String>> columns;
  final Set<int> calledNumbers;

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
              final isMarked = _isMarked(value);

              return Expanded(
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
                      fontWeight: isMarked ? FontWeight.w700 : FontWeight.w500,
                      color: isMarked
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
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

  bool _isMarked(String value) {
    if (value == 'FREE') {
      return true;
    }

    final number = int.tryParse(value);
    return number != null && calledNumbers.contains(number);
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

class _CartelaStatusPresentation {
  const _CartelaStatusPresentation({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}
