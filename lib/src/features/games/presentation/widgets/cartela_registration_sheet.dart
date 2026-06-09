import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/friends_bingo_loading.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/games_repository.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/cartela_reservation_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../domain/cartela_availability.dart';

class CartelaRegistrationSheet extends ConsumerStatefulWidget {
  const CartelaRegistrationSheet({
    required this.cartela,
    required this.entryFee,
    required this.walletBalance,
    required this.slotId,
    required this.reservationFuture,
    this.sessionId,
    super.key,
  });

  final CartelaModel cartela;
  final String entryFee;
  final String? walletBalance;
  final String slotId;
  final String? sessionId;
  final Future<CartelaReservationModel> reservationFuture;

  @override
  ConsumerState<CartelaRegistrationSheet> createState() =>
      _CartelaRegistrationSheetState();
}

class _CartelaRegistrationSheetState
    extends ConsumerState<CartelaRegistrationSheet> {
  Timer? _autoCloseTimer;
  late final DateTime _holdStartedAt;
  int _secondsRemaining = kCartelaReservationHoldSeconds;
  bool _isSubmitting = false;
  bool _registered = false;
  bool _released = false;

  String? _reservationId;
  String? _resolvedSessionId;
  String? _reserveError;

  @override
  void initState() {
    super.initState();
    _holdStartedAt = DateTime.now();
    _resolvedSessionId = widget.sessionId;
    _startCountdown();
    unawaited(_trackReservation(widget.reservationFuture));
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    if (!_registered && !_released && !_isSubmitting) {
      if (_reservationId != null) {
        unawaited(_releaseReservation());
      } else {
        unawaited(_cancelPendingReservation());
      }
    }
    super.dispose();
  }

  void _applyReservation(CartelaReservationModel reservation) {
    _reservationId = reservation.id;
    _resolvedSessionId = reservation.gameSessionId;
    _reserveError = null;
  }

  Future<void> _trackReservation(
    Future<CartelaReservationModel> reservationFuture,
  ) async {
    try {
      final reservation = await reservationFuture;
      if (!mounted || _registered || _released) {
        return;
      }

      setState(() {
        _applyReservation(reservation);
        _secondsRemaining = _remainingSeconds();
      });
    } catch (error) {
      if (!mounted || _registered || _released) {
        return;
      }

      setState(() {
        _reserveError = error is ApiException
            ? error.message
            : 'Could not hold this cartela.';
      });
    }
  }

  Future<String> _resolveReservationId() async {
    final existingId = _reservationId;
    if (existingId != null) {
      return existingId;
    }

    final reservation = await widget.reservationFuture;
    if (mounted && !_registered && !_released) {
      setState(() {
        _applyReservation(reservation);
        _secondsRemaining = _remainingSeconds();
      });
    }
    return reservation.id;
  }

  int _remainingSeconds() {
    return cartelaReservationSecondsRemaining(holdStartedAt: _holdStartedAt) ??
        0;
  }

  void _startCountdown() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextValue = _remainingSeconds();
      if (nextValue <= 0) {
        timer.cancel();
        unawaited(_closeSheet(releaseHold: true));
        return;
      }

      setState(() => _secondsRemaining = nextValue);
    });
  }

  void _stopCountdown() => _autoCloseTimer?.cancel();

  bool get _hasEnoughBalance {
    final balance = widget.walletBalance;
    if (balance == null) {
      return true;
    }
    return _parseMoney(balance) >= _parseMoney(widget.entryFee);
  }

  bool get _canRegister {
    return _reserveError == null &&
        !_isSubmitting &&
        !_registered &&
        _hasEnoughBalance &&
        _secondsRemaining > 0;
  }

  Future<void> _releaseReservation() async {
    if (_released || _registered) {
      return;
    }

    final reservationId = _reservationId;
    if (reservationId == null) {
      return;
    }

    _released = true;
    try {
      await ref.read(gamesRepositoryProvider).cancelReservation(reservationId);
    } catch (_) {}
  }

  Future<void> _cancelPendingReservation() async {
    if (_released || _registered) {
      return;
    }

    try {
      final reservation = await widget.reservationFuture;
      if (_released || _registered) {
        return;
      }

      _released = true;
      await ref
          .read(gamesRepositoryProvider)
          .cancelReservation(reservation.id);
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_canRegister) {
      return;
    }

    _stopCountdown();
    setState(() => _isSubmitting = true);

    try {
      final reservationId = await _resolveReservationId();
      final registeredCartela = await ref
          .read(gamesRepositoryProvider)
          .confirmReservation(reservationId);

      if (!mounted) {
        return;
      }

      _registered = true;
      _released = true;
      ref.invalidate(myWalletProvider);
      Navigator.of(context).pop(registeredCartela);
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (error is ApiException &&
          (error.message.contains('hold') ||
              error.message.contains('choosing') ||
              error.message.contains('reserve'))) {
        setState(() {
          _isSubmitting = false;
          _reserveError = error.message;
        });
        return;
      }

      if (error is ApiException && error.isConnectivityFailure) {
        final recovered = await _recoverRegistrationAfterConnectivityFailure();
        if (!mounted) {
          return;
        }

        if (recovered != null) {
          _registered = true;
          _released = true;
          ref.invalidate(myWalletProvider);
          Navigator.of(context).pop(recovered);
          return;
        }
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
        _secondsRemaining = _remainingSeconds();
      });
      if (_secondsRemaining > 0) {
        _startCountdown();
      }
    }
  }

  Future<void> _closeSheet({bool releaseHold = true}) async {
    _stopCountdown();
    if (releaseHold) {
      await _releaseReservation();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<GameCartelaModel?> _recoverRegistrationAfterConnectivityFailure() async {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
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
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppBranding.gold, width: 2),
                            color: AppBranding.casinoPurpleDeep,
                          ),
                          child: Text(
                            '${widget.cartela.number}',
                            style: AppBranding.wordmarkGold(size: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Preview',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 1.2,
                            ),
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
                            '${_secondsRemaining}s',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppBranding.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child:
                        _CasinoCartelaPreview(columns: widget.cartela.columns),
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
                        border:
                            Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatMoney(widget.entryFee),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          if (widget.walletBalance != null) ...[
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
                  if (_reserveError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Text(
                        _reserveError!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    )
                  else if (!_hasEnoughBalance)
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
                            onPressed:
                                _isSubmitting ? null : () => _closeSheet(),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppBranding.casinoPurple,
                              foregroundColor: AppBranding.gold,
                              disabledBackgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              disabledForegroundColor:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: _canRegister ? _register : null,
                            child: const Text(
                              'Register',
                              style: TextStyle(fontWeight: FontWeight.w800),
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
                  child: const FriendsBingoLoading(
                    compact: true,
                    message: 'Registering...',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CasinoCartelaPreview extends StatelessWidget {
  const _CasinoCartelaPreview({required this.columns});

  final List<List<String>> columns;

  @override
  Widget build(BuildContext context) {
    const headers = ['B', 'I', 'N', 'G', 'O'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppBranding.feltGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(headers.length, (index) {
              return Expanded(
                child: Text(
                  headers[index],
                  textAlign: TextAlign.center,
                  style: AppBranding.wordmarkGold(size: 18),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          ...List.generate(5, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(headers.length, (columnIndex) {
                  final value = columns[columnIndex].length > rowIndex
                      ? columns[columnIndex][rowIndex]
                      : '';
                  final isFree = value == 'FREE';

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isFree
                            ? AppBranding.gold
                                .withValues(alpha: isDark ? 0.25 : 0.35)
                            : AppBranding.cellBackground(context, marked: false),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isFree
                              ? AppBranding.gold
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight:
                              isFree ? FontWeight.w800 : FontWeight.w600,
                          color: isFree
                              ? AppBranding.casinoPurpleDeep
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

double _parseMoney(String value) {
  return double.tryParse(value.replaceAll(',', '')) ?? 0;
}
