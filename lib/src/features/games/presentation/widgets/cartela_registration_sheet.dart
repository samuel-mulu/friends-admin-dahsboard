import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/friends_bingo_loading.dart';
import '../../data/games_repository.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_category_theme.dart';
import '../../domain/cartela_availability.dart';
import '../../domain/cartela_board_preview_cache.dart';
import '../../domain/registration_state_patch.dart';
import '../providers/registration_state_patch_provider.dart';
import '../providers/games_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/current_game_operations_provider.dart';
import '../utils/registration_error_helpers.dart';
import '../utils/registration_ux_metrics.dart';
import 'cartela_board_preview.dart';
import 'cartela_number_badge.dart';

class CartelaRegistrationSheet extends ConsumerStatefulWidget {
  const CartelaRegistrationSheet({
    required this.cartela,
    required this.entryFee,
    required this.walletBalance,
    this.bonusCartelaBalance = 0,
    this.isFirstTimePlayer = false,
    required this.slotId,
    required this.cartelaHoldSeconds,
    this.category = GameCategory.normal,
    this.fixedPrizeAmount,
    this.maxCartelasPerPlayer,
    this.sessionId,
    this.existingReservationId,
    this.existingReservationExpiresAt,
    this.onSessionIdResolved,
    super.key,
  });

  final CartelaModel cartela;
  final String entryFee;
  final String? walletBalance;
  final int bonusCartelaBalance;
  final bool isFirstTimePlayer;
  final String slotId;
  final String? sessionId;
  final String? existingReservationId;
  final DateTime? existingReservationExpiresAt;
  final int cartelaHoldSeconds;
  final GameCategory category;
  final String? fixedPrizeAmount;
  final int? maxCartelasPerPlayer;
  final ValueChanged<String>? onSessionIdResolved;

  @override
  ConsumerState<CartelaRegistrationSheet> createState() =>
      _CartelaRegistrationSheetState();
}

class _CartelaRegistrationSheetState
    extends ConsumerState<CartelaRegistrationSheet> {
  Timer? _autoCloseTimer;
  late int _secondsRemaining;
  bool _isSubmitting = false;
  bool _registered = false;
  bool _released = false;
  bool _holdReady = false;
  late final GamesRepository _repository;

  String? _reservationId;
  String? _resolvedSessionId;
  String? _prepareError;
  CartelaModel? _previewCartela;
  DateTime? _reservationExpiresAt;
  DateTime? _reserveStartedAt;

  CartelaModel? _initialPreviewCartela() {
    final cached = CartelaBoardPreviewCache.get(widget.cartela.id);
    if (cached != null) {
      return cached;
    }

    if (widget.cartela.hasBoardValues) {
      CartelaBoardPreviewCache.put(widget.cartela);
      return widget.cartela;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _repository = ref.read(gamesRepositoryProvider);
    _secondsRemaining = widget.cartelaHoldSeconds;
    _resolvedSessionId = widget.sessionId;
    _previewCartela = _initialPreviewCartela();

    if (_previewCartela?.hasBoardValues != true &&
        _resolvedSessionId != null &&
        _resolvedSessionId!.isNotEmpty) {
      unawaited(_loadPreviewBoard());
    }

    final existingReservationId = widget.existingReservationId;
    final existingExpiresAt = widget.existingReservationExpiresAt;
    if (existingReservationId != null && existingExpiresAt != null) {
      _reservationId = existingReservationId;
      _reservationExpiresAt = existingExpiresAt;
      _holdReady = true;
      _secondsRemaining =
          cartelaReservationSecondsRemaining(
            expiresAt: existingExpiresAt,
            cartelaHoldSeconds: widget.cartelaHoldSeconds,
            clock: ref.read(serverClockProvider),
          ) ??
          widget.cartelaHoldSeconds;
      _startCountdown();
      if (_previewCartela == null) {
        unawaited(_loadPreviewBoard());
      }
      return;
    }

    unawaited(_prepareHold());
  }

  static const _holdCountdownInterval = Duration(milliseconds: 250);

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    if (!_registered &&
        !_released &&
        !_isSubmitting &&
        _reservationId != null) {
      unawaited(_releaseReservation(applyAvailablePatch: false));
    }
    super.dispose();
  }

  Future<void> _prepareHold() async {
    if (_reservationId != null) {
      return;
    }

    _reserveStartedAt = DateTime.now();
    final sessionIdForEarlyBoard = widget.sessionId;
    Future<void>? earlyBoardFuture;
    if (_previewCartela?.hasBoardValues != true &&
        sessionIdForEarlyBoard != null &&
        sessionIdForEarlyBoard.isNotEmpty) {
      earlyBoardFuture = _loadPreviewBoard();
    }

    try {
      final repository = ref.read(gamesRepositoryProvider);
      final reservation = widget.sessionId != null
          ? await repository.reserveCartela(
              sessionId: widget.sessionId!,
              cartelaId: widget.cartela.id,
              preserveOtherReservations: false,
            )
          : await repository.reserveCartelaForSlot(
              slotId: widget.slotId,
              cartelaId: widget.cartela.id,
              preserveOtherReservations: false,
            );

      if (!mounted || _registered || _released) {
        if (!_registered && !_released) {
          try {
            await repository.cancelReservation(reservation.id);
          } catch (_) {}
        }
        return;
      }

      widget.onSessionIdResolved?.call(reservation.gameSessionId);
      _resolvedSessionId = reservation.gameSessionId;

      var previewCartela = _previewCartela;
      if (previewCartela?.hasBoardValues != true) {
        if (reservation.cartela != null &&
            reservation.cartela!.hasBoardValues) {
          previewCartela = reservation.cartela!;
        } else if (earlyBoardFuture != null) {
          await earlyBoardFuture;
          previewCartela = _previewCartela;
        } else {
          await _loadPreviewBoard();
          previewCartela = _previewCartela;
        }
        if (previewCartela != null && previewCartela.hasBoardValues) {
          CartelaBoardPreviewCache.put(previewCartela);
        }
      }

      if (!mounted || _registered || _released) {
        if (!_registered && !_released) {
          try {
            await repository.cancelReservation(reservation.id);
          } catch (_) {}
        }
        return;
      }

      setState(() {
        _reservationId = reservation.id;
        _resolvedSessionId = reservation.gameSessionId;
        if (previewCartela != null) {
          _previewCartela = previewCartela;
        }
        _prepareError = null;
        _holdReady = true;
        _reservationExpiresAt = reservation.expiresAt;
        _secondsRemaining =
            cartelaReservationSecondsRemaining(
              expiresAt: reservation.expiresAt,
              cartelaHoldSeconds: widget.cartelaHoldSeconds,
              clock: ref.read(serverClockProvider),
            ) ??
            widget.cartelaHoldSeconds;
      });
      ref
          .read(registrationStatePatchProvider.notifier)
          .applyChanges(reservation.gameSessionId, [
            RegistrationCartelaChange(
              cartelaId: widget.cartela.id,
              cartelaNumber: widget.cartela.number,
              owner: 'RESERVED_ME',
              actorUserId: ref.read(authControllerProvider).session?.user.id,
              expiresAt: reservation.expiresAt,
            ),
          ]);
      _startCountdown();
      final startedAt = _reserveStartedAt;
      if (startedAt != null) {
        RegistrationUxMetrics.reserveSuccess(
          elapsed: DateTime.now().difference(startedAt),
        );
      }
    } catch (error) {
      if (!mounted || _registered || _released) {
        return;
      }

      if (error is ApiException &&
          (isRegistrationClosedError(error) ||
              isSessionNotReadyError(error))) {
        unawaited(ref.read(currentGameOperationsProvider.notifier).refresh());
      }

      setState(() {
        _prepareError = _reserveErrorMessage(error);
      });
      RegistrationUxMetrics.reserveFailure(
        reason: error is ApiException
            ? error.message
            : error.runtimeType.toString(),
      );
    }
  }

  String _reserveErrorMessage(Object error) {
    if (error is ApiException) {
      if (isRegistrationClosedError(error) || isSessionNotReadyError(error)) {
        return 'Registration closed.';
      }

      final message = error.message.toLowerCase();
      if (message.contains('taken') ||
          message.contains('reserved') ||
          message.contains('unavailable')) {
        return 'This cartela was just taken. Please choose another.';
      }
      if (error.isConnectivityFailure) {
        return 'Network error. Try again.';
      }
      return error.displayMessage;
    }
    return 'Could not hold this cartela. Try again.';
  }

  Future<void> _retryPrepareHold() async {
    if (_isSubmitting || _registered || _released) {
      return;
    }

    setState(() {
      _prepareError = null;
      _holdReady = false;
      _reservationId = null;
      _reservationExpiresAt = null;
    });
    await _prepareHold();
  }

  Future<void> _loadPreviewBoard() async {
    final sessionId = _resolvedSessionId ?? widget.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }

    try {
      final repository = ref.read(gamesRepositoryProvider);
      final board = await repository.getCartelaBoard(
        cartelaId: widget.cartela.id,
        sessionId: sessionId,
      );
      final previewCartela = widget.cartela.copyWithBoard(
        b: board.b,
        i: board.i,
        n: board.n,
        g: board.g,
        o: board.o,
      );
      CartelaBoardPreviewCache.put(previewCartela);

      if (!mounted || _registered || _released) {
        return;
      }

      setState(() => _previewCartela = previewCartela);
    } catch (_) {}
  }

  int _remainingSeconds() {
    if (!_holdReady) {
      return 0;
    }

    return cartelaReservationSecondsRemaining(
          expiresAt: _reservationExpiresAt,
          cartelaHoldSeconds: widget.cartelaHoldSeconds,
          clock: ref.read(serverClockProvider),
        ) ??
        0;
  }

  void _startCountdown() {
    _autoCloseTimer?.cancel();

    _autoCloseTimer = Timer.periodic(_holdCountdownInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextValue = _remainingSeconds();
      if (_holdReady && nextValue <= 0) {
        timer.cancel();
        unawaited(_closeSheet(releaseHold: true));
        return;
      }

      if (nextValue != _secondsRemaining) {
        setState(() => _secondsRemaining = nextValue);
      }
    });
  }

  void _stopCountdown() => _autoCloseTimer?.cancel();

  bool get _isBonus => widget.category == GameCategory.bonus;

  bool get _isBigGotd => widget.category == GameCategory.bigGotd;

  bool get _isBonusLike => widget.category.isBonusLike;

  bool get _hasFreeEntry => widget.category.hasFreeEntry;

  bool get _isBigGame => widget.category == GameCategory.bigGame;

  bool get _hasEnoughBalance {
    if (_hasFreeEntry) {
      return true;
    }
    if (widget.bonusCartelaBalance > 0) {
      return true;
    }
    final balance = widget.walletBalance;
    if (balance == null) {
      return true;
    }
    return _parseMoney(balance) >= _parseMoney(widget.entryFee);
  }

  String get _entryPaymentLabel {
    if (_hasFreeEntry) {
      return 'Free entry';
    }
    if (widget.bonusCartelaBalance > 0) {
      if (widget.isFirstTimePlayer) {
        return 'Uses 1 welcome bonus cartela';
      }
      return 'Uses 1 bonus cartela';
    }
    return formatMoney(widget.entryFee);
  }

  bool get _isPreparingHold =>
      !_holdReady && _prepareError == null && !_isSubmitting && !_registered;

  bool get _isHoldExpired =>
      _holdReady && _secondsRemaining <= 0 && !_isSubmitting && !_registered;

  bool get _isBoardLoading =>
      _previewCartela?.hasBoardValues != true && _prepareError == null;

  String? get _primaryActionLabel {
    if (_isSubmitting) {
      return 'Registering...';
    }
    if (_prepareError != null) {
      return 'Try again';
    }
    if (_isPreparingHold) {
      return 'Preparing...';
    }
    if (_isHoldExpired) {
      return 'Hold expired';
    }
    if (!_hasEnoughBalance) {
      return 'Insufficient balance';
    }
    return _hasFreeEntry ? 'Register Free' : 'Register';
  }

  VoidCallback? get _primaryAction {
    if (_isSubmitting) {
      return null;
    }
    if (_prepareError != null) {
      return _retryPrepareHold;
    }
    if (_canRegister) {
      return _register;
    }
    return null;
  }

  List<List<String>> get _displayColumns {
    if (_previewCartela?.hasBoardValues == true) {
      return _previewCartela!.columns;
    }
    return emptyCartelaBoardColumns();
  }

  bool get _canRegister {
    return _holdReady &&
        _prepareError == null &&
        _reservationId != null &&
        !_isSubmitting &&
        !_registered &&
        _hasEnoughBalance &&
        _secondsRemaining > 0;
  }

  Future<void> _releaseReservation({bool applyAvailablePatch = true}) async {
    if (_registered) {
      return;
    }

    final reservationId = _reservationId;
    if (reservationId == null || _released) {
      return;
    }

    _released = true;
    try {
      await _repository.cancelReservation(reservationId);
    } catch (_) {}

    if (!applyAvailablePatch || !mounted) {
      return;
    }

    final sessionId = _resolvedSessionId ?? widget.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      ref
          .read(registrationStatePatchProvider.notifier)
          .applyChanges(sessionId, [
            RegistrationCartelaChange(
              cartelaId: widget.cartela.id,
              cartelaNumber: widget.cartela.number,
              owner: 'AVAILABLE',
            ),
          ]);
      ref.invalidate(registrationStateProvider(sessionId));
    }
  }

  void _closeSheetOnSuccess(GameCartelaModel registeredCartela) {
    if (!mounted || _registered) {
      return;
    }

    final actorUserId = ref.read(authControllerProvider).session?.user.id;
    ref
        .read(registrationStatePatchProvider.notifier)
        .applyChanges(registeredCartela.gameId, [
          RegistrationCartelaChange(
            cartelaId: widget.cartela.id,
            cartelaNumber: widget.cartela.number,
            owner: 'ME',
            actorUserId: actorUserId,
          ),
        ]);

    _registered = true;
    _released = true;
    Navigator.of(context).pop(registeredCartela);
  }

  Future<void> _register() async {
    if (!_canRegister) {
      return;
    }

    final reservationId = _reservationId;
    if (reservationId == null) {
      return;
    }

    _stopCountdown();
    setState(() => _isSubmitting = true);

    try {
      final registeredCartela = await ref
          .read(gamesRepositoryProvider)
          .confirmReservation(reservationId);

      if (!mounted) {
        return;
      }

      _closeSheetOnSuccess(registeredCartela);
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (error is ApiException &&
          (isRegistrationClosedError(error) ||
              isSessionNotReadyError(error))) {
        unawaited(ref.read(currentGameOperationsProvider.notifier).refresh());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(registrationWindowClosedMessage(context, error)),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      if (error is ApiException &&
          (error.message.contains('hold') ||
              error.message.contains('choosing') ||
              error.message.contains('reserve'))) {
        setState(() {
          _isSubmitting = false;
          _prepareError = error.message;
        });
        return;
      }

      if (error is ApiException && error.isConnectivityFailure) {
        final recovered = await _recoverRegistrationAfterConnectivityFailure();
        if (!mounted) {
          return;
        }

        if (recovered != null) {
          _closeSheetOnSuccess(recovered);
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? ((error.message == 'BONUS_CARTELA_LIMIT_REACHED')
                      ? 'You can register up to ${widget.maxCartelasPerPlayer ?? 5} free cartelas for this bonus game.'
                      : (error.message == 'BIG_GOTD_CARTELA_LIMIT_REACHED')
                      ? 'You can register up to ${widget.maxCartelasPerPlayer ?? 5} cartelas for Big GOTD.'
                      : error.displayMessage)
                : 'Could not register this cartela.',
          ),
        ),
      );

      setState(() {
        _isSubmitting = false;
        _secondsRemaining = _remainingSeconds();
      });
      if (_secondsRemaining > 0) {
        _startCountdown();
      }
    }
  }

  Future<void> _closeSheet({bool releaseHold = true}) async {
    if (_isSubmitting || _registered) {
      return;
    }

    _stopCountdown();
    if (releaseHold) {
      await _releaseReservation();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<GameCartelaModel?>
  _recoverRegistrationAfterConnectivityFailure() async {
    try {
      final repository = ref.read(gamesRepositoryProvider);
      var sessionId = _resolvedSessionId;

      if (sessionId == null) {
        final slot = await repository.getSlotDetail(widget.slotId);
        sessionId = slot.sessionId;
      }

      if (sessionId == null) {
        return null;
      }

      final myCartelas = await repository.getMyGameCartelas(sessionId);
      for (final gameCartela in myCartelas) {
        if (gameCartela.cartelaId == widget.cartela.id) {
          return gameCartela;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String get _countdownLabel {
    if (_isSubmitting) {
      return '...';
    }
    if (!_holdReady) {
      return '…';
    }
    if (_secondsRemaining <= 0) {
      return '0s';
    }
    return '${_secondsRemaining}s';
  }

  String get _holdStatusLabel {
    if (_isSubmitting) {
      return 'Registering...';
    }
    if (_prepareError != null) {
      return _prepareError!;
    }
    if (!_holdReady) {
      return 'Preparing hold...';
    }
    if (_isHoldExpired) {
      return 'Hold expired';
    }
    return 'Hold time: $_countdownLabel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_registered && !_released && !_isSubmitting) {
          unawaited(_releaseReservation());
        }
      },
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppBranding.gold,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppBranding.casinoPurpleDeep,
                            AppBranding.casinoPurple,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          CartelaNumberCircleBadge(number: widget.cartela.number),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Cartela #${widget.cartela.number}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isBonus
                                      ? 'Bonus Game'
                                      : _isBigGotd
                                      ? 'Big GOTD'
                                      : _isBigGame
                                      ? 'Big Game'
                                      : 'Preview',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (_hasFreeEntry) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Free entry',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppBranding.goldAccent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                                if ((_isBonusLike || _isBigGame) &&
                                    widget.fixedPrizeAmount != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fixed prize: ${formatMoney(widget.fixedPrizeAmount!)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppBranding.goldAccent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  _holdStatusLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _prepareError != null
                                        ? theme.colorScheme.error
                                        : Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_isBoardLoading) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Loading board...',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppBranding.gold.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              _countdownLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppBranding.goldAccent,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: CartelaBoardPreview(columns: _displayColumns),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasFreeEntry
                                  ? Icons.redeem_rounded
                                  : _isBigGotd
                                  ? Icons.star_rounded
                                  : _isBigGame
                                  ? Icons.emoji_events_rounded
                                  : Icons.payments_outlined,
                              size: 18,
                              color: (_isBigGame || _isBigGotd)
                                  ? GameCategoryTheme.accentColor(
                                      widget.category,
                                      isDark:
                                          theme.brightness == Brightness.dark,
                                    )
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _entryPaymentLabel,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (_isBonusLike) ...[
                                    if (widget.fixedPrizeAmount != null)
                                      Text(
                                        'Fixed prize: ${formatMoney(widget.fixedPrizeAmount!)}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    Text(
                                      'Max ${widget.maxCartelasPerPlayer ?? 5} cartelas',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                  if (_isBigGame &&
                                      widget.maxCartelasPerPlayer != null)
                                    Text(
                                      'Max ${widget.maxCartelasPerPlayer} cartelas',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            if (!_hasFreeEntry &&
                                widget.walletBalance != null) ...[
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatMoney(widget.walletBalance!),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!_hasFreeEntry && !_hasEnoughBalance && _holdReady)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                        child: Text(
                          'Insufficient balance',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _closeSheet(),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _primaryAction,
                              child: _isPreparingHold || _isSubmitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _primaryActionLabel ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _primaryActionLabel ?? 'Register',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSubmitting)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FriendsBingoLoading(compact: true),
                        const SizedBox(height: 12),
                        Text(
                          _hasFreeEntry
                              ? 'Registering free cartela...'
                              : 'Registering cartela...',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

double _parseMoney(String value) {
  return double.tryParse(value.replaceAll(',', '')) ?? 0;
}
