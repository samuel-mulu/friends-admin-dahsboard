import 'package:flutter/foundation.dart';
import '../../../shared/domain/entities/payment_provider.dart';
import 'withdrawal_confirmation_state.dart';

@immutable
class WithdrawState {
  const WithdrawState({
    this.provider,
    this.isChoosingProvider = true,
    this.isSubmitting = false,
    this.confirmation,
    this.trackedWithdrawalId,
    this.savedCbeAccount = '',
    this.ownPhoneNumber,
  });

  final PaymentProvider? provider;
  final bool isChoosingProvider;
  final bool isSubmitting;
  final WithdrawalConfirmationState? confirmation;
  final String? trackedWithdrawalId;
  final String savedCbeAccount;
  final String? ownPhoneNumber;

  WithdrawState copyWith({
    PaymentProvider? provider,
    bool? isChoosingProvider,
    bool? isSubmitting,
    WithdrawalConfirmationState? confirmation,
    bool clearConfirmation = false,
    String? trackedWithdrawalId,
    bool clearTrackedId = false,
    String? savedCbeAccount,
    String? ownPhoneNumber,
  }) {
    return WithdrawState(
      provider: provider ?? this.provider,
      isChoosingProvider: isChoosingProvider ?? this.isChoosingProvider,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      confirmation:
          clearConfirmation ? null : (confirmation ?? this.confirmation),
      trackedWithdrawalId: clearTrackedId
          ? null
          : (trackedWithdrawalId ?? this.trackedWithdrawalId),
      savedCbeAccount: savedCbeAccount ?? this.savedCbeAccount,
      ownPhoneNumber: ownPhoneNumber ?? this.ownPhoneNumber,
    );
  }
}
