import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/core/time/server_clock_provider.dart';
import 'package:friends_bingo_app/src/core/utils/formatters.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/core/widgets/friends_bingo_loader.dart';
import 'package:friends_bingo_app/src/features/auth/application/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/repositories/cartelas_repository.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_board_preview_cache.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_payment_source.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_preview.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_number_badge.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_category_theme.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/current_game_operations_provider.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/games_providers.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_error_helpers.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_state_patch.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_ux_metrics.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/providers/registration_state_patch_provider.dart';

class CartelaRegistrationSheet extends ConsumerStatefulWidget {
  const CartelaRegistrationSheet({
    required this.cartela,
    required this.entryFee,
    required this.walletBalance,
    this.bonusCartelaBalance = 0,
    this.bigGameTicketBalance = 0,
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
    /// When true, opens as a read-only preview for an already-registered cartela
    /// (no hold / register). Shows a "This is yours" label instead.
    this.alreadyOwned = false,
    this.carriedForward = false,
    this.initialPaymentSource,
    super.key,
  });

  final CartelaModel cartela;
  final String entryFee;
  final String? walletBalance;
  final int bonusCartelaBalance;
  final int bigGameTicketBalance;
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
  final bool alreadyOwned;
  final bool carriedForward;
  final String? initialPaymentSource;

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
  late String _paymentSource;

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
    _paymentSource = _resolveInitialPaymentSource();

    if (widget.alreadyOwned) {
      if (_previewCartela?.hasBoardValues != true) {
        unawaited(_loadPreviewBoard());
      }
      return;
    }

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

  String _resolveInitialPaymentSource() {
    if (widget.category != GameCategory.bigGame ||
        widget.bigGameTicketBalance <= 0) {
      return CartelaPaymentSource.moneyWallet;
    }
    final preferred = widget.initialPaymentSource;
    if (preferred == CartelaPaymentSource.moneyWallet ||
        preferred == CartelaPaymentSource.bigGameTicket) {
      return preferred!;
    }
    return CartelaPaymentSource.bigGameTicket;
  }

  bool get _canChooseBigTicketPayment =>
      _isBigGame && widget.bigGameTicketBalance > 0;

  bool get _usingBigTicket =>
      _canChooseBigTicketPayment &&
      _paymentSource == CartelaPaymentSource.bigGameTicket;

  static const _holdCountdownInterval = Duration(milliseconds: 250);

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    if (!widget.alreadyOwned &&
        !_registered &&
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
      final repository = ref.read(cartelasRepositoryProvider);
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

  bool get _canUseBonusCartelaBalance =>
      widget.category.canUseBonusCartelaBalance;

  bool get _isBigGame => widget.category == GameCategory.bigGame;

  bool get _isChainGame => widget.category == GameCategory.chainGame;

  bool get _hasEnoughBalance {
    if (_hasFreeEntry) {
      return true;
    }
    if (_usingBigTicket) {
      return widget.bigGameTicketBalance > 0;
    }
    if (_canUseBonusCartelaBalance && widget.bonusCartelaBalance > 0) {
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
    if (_usingBigTicket) {
      return context.l10n.registrationUsesBigTicket;
    }
    if (_canUseBonusCartelaBalance && widget.bonusCartelaBalance > 0) {
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
    if (widget.alreadyOwned) {
      return 'This is yours';
    }
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
    if (widget.alreadyOwned) {
      return null;
    }
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
      final GameCartelaModel registeredCartela;
      if (_isBigGame) {
        final sessionId = _resolvedSessionId ?? widget.sessionId;
        if (sessionId != null && sessionId.isNotEmpty) {
          registeredCartela = await ref
              .read(gamesRepositoryProvider)
              .registerCartela(
                sessionId: sessionId,
                cartelaId: widget.cartela.id,
                paymentSource: _paymentSource,
              );
        } else {
          registeredCartela = await ref
              .read(gamesRepositoryProvider)
              .registerCartelaForSlot(
                slotId: widget.slotId,
                cartelaId: widget.cartela.id,
                paymentSource: _paymentSource,
              );
        }
      } else {
        registeredCartela = await ref
            .read(gamesRepositoryProvider)
            .confirmReservation(
              reservationId,
              slotId: widget.slotId,
              cartelaId: widget.cartela.id,
              sessionId: _resolvedSessionId,
            );
      }

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
                      : (error.message == 'CHAIN_GAME_CARTELA_LIMIT_REACHED' ||
                            error.code == 'CHAIN_GAME_CARTELA_LIMIT_REACHED')
                      ? 'You can register up to ${widget.maxCartelasPerPlayer ?? 5} cartelas for this Chain Game.'
                      : (error.message == 'NORMAL_CARTELA_LIMIT_REACHED' ||
                            error.code == 'NORMAL_CARTELA_LIMIT_REACHED')
                      ? context.l10n.registrationNormalLimitReached
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
    if (widget.alreadyOwned) {
      return 'Yours';
    }
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
  bool get _isHoldUrgent =>
      !widget.alreadyOwned &&
      _holdReady &&
      _secondsRemaining <= 3 &&
      _secondsRemaining > 0;

  String? get _headerStatusLabel {
    if (widget.alreadyOwned) {
      return widget.carriedForward
          ? context.l10n.bigGameCartelaCarried
          : 'Already registered to you';
    }
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
    return null;
  }

  String _categoryTitle(AppLocalizations l10n) {
    if (_isBonus) return l10n.gameCategoryBonus;
    if (_isBigGotd) return l10n.gameCategoryNormal;
    if (_isBigGame) return l10n.gameCategoryBigGame;
    if (_isChainGame) return l10n.gameCategoryChainGame;
    return 'Preview';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop &&
            !widget.alreadyOwned &&
            !_registered &&
            !_released &&
            !_isSubmitting) {
          unawaited(_releaseReservation());
        }
      },
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppBranding.gold,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                              CartelaNumberCircleBadge(
                                number: widget.cartela.number,
                                size: 44,
                                baseFontSize: 22,
                                borderWidth: 1.8,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Cartela #${widget.cartela.number}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.22,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            _categoryTitle(l10n),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.95),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10,
                                                  letterSpacing: 0.4,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    if (_hasFreeEntry)
                                      Text(
                                        'Free entry',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: AppBranding.goldAccent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                            ),
                                      )
                                    else if ((_isBonusLike ||
                                            _isBigGame ||
                                            _isChainGame ||
                                            _isBigGotd) &&
                                        widget.fixedPrizeAmount != null)
                                      Text(
                                        l10n.gameBonusFixedPrize(
                                          formatMoney(widget.fixedPrizeAmount!),
                                        ),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: AppBranding.goldAccent,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (_headerStatusLabel != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          _headerStatusLabel!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: _prepareError != null ||
                                                        _isHoldExpired
                                                    ? theme.colorScheme.error
                                                    : Colors.white.withValues(
                                                        alpha: 0.85,
                                                      ),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    else if (_isBoardLoading)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Loading board...',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                                fontStyle: FontStyle.italic,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (widget.alreadyOwned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _countdownLabel,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _isHoldUrgent
                                          ? theme.colorScheme.error
                                          : AppBranding.gold.withValues(
                                              alpha: 0.7,
                                            ),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 13,
                                        color: _isHoldUrgent
                                            ? theme.colorScheme.error
                                            : AppBranding.goldAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _countdownLabel,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: _isHoldUrgent
                                                  ? theme.colorScheme.error
                                                  : AppBranding.goldAccent,
                                              fontWeight: FontWeight.w800,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 300,
                                maxHeight: 300,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: 310,
                                  child: CartelaBoardPreview(
                                    columns: _displayColumns,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!widget.alreadyOwned && _canChooseBigTicketPayment)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: SegmentedButton<String>(
                              segments: [
                                ButtonSegment<String>(
                                  value: CartelaPaymentSource.bigGameTicket,
                                  label: Text(l10n.registrationUseBigTicket),
                                  icon: const Icon(
                                    Icons.confirmation_number_outlined,
                                    size: 16,
                                  ),
                                ),
                                ButtonSegment<String>(
                                  value: CartelaPaymentSource.moneyWallet,
                                  label: Text(l10n.registrationPayEtb),
                                  icon: const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                  ),
                                ),
                              ],
                              selected: {_paymentSource},
                              onSelectionChanged: (selection) {
                                if (_isSubmitting ||
                                    _registered ||
                                    selection.isEmpty) {
                                  return;
                                }
                                setState(() {
                                  _paymentSource = selection.first;
                                });
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
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
                                              theme.brightness ==
                                              Brightness.dark,
                                        )
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _entryPaymentLabel,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      if (_isBonusLike) ...[
                                        if (widget.fixedPrizeAmount != null)
                                          Text(
                                            l10n.gameBonusFixedPrize(
                                              formatMoney(
                                                widget.fixedPrizeAmount!,
                                              ),
                                            ),
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
                                      if ((_isChainGame ||
                                              widget.category ==
                                                  GameCategory.normal) &&
                                          widget.maxCartelasPerPlayer != null)
                                        Text(
                                          l10n.gameBonusMaxCartelas(
                                            widget.maxCartelasPerPlayer!,
                                          ),
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
                        if (!_hasFreeEntry &&
                            !_hasEnoughBalance &&
                            _holdReady &&
                            !widget.alreadyOwned)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: Text(
                              'Insufficient balance',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _closeSheet(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Close'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _primaryAction,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                                                color: theme
                                                    .colorScheme
                                                    .onPrimary,
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
                            const FriendsBingoLoader.inline(compact: true),
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
        ),
      ),
    );
  }
}

double _parseMoney(String value) {
  return double.tryParse(value.replaceAll(',', '')) ?? 0;
}
