import 'package:flutter/foundation.dart';
import '../../../shared/domain/entities/payment_provider.dart';
import '../../domain/parsers/smart_deposit_parse_result.dart';
import 'deposit_confirmation_state.dart';

enum DepositEntryTab { smart, regular }

@immutable
class DepositState {
  const DepositState({
    this.entryTab = DepositEntryTab.smart,
    this.provider,
    this.isChoosingProvider = true,
    this.smartParseResult,
    this.isSubmitting = false,
    this.checkInFlight = false,
    this.confirmation,
    this.trackedDepositId,
    this.pendingAttemptId,
    this.checkAgainCooldownRemaining = 0,
    this.amountServerError,
    this.transactionRefServerError,
    this.previewNotice,
    this.guideTabIndex = 0,
  });

  final DepositEntryTab entryTab;
  final PaymentProvider? provider;
  final bool isChoosingProvider;
  final SmartDepositParseResult? smartParseResult;
  final bool isSubmitting;
  final bool checkInFlight;
  final DepositConfirmationState? confirmation;
  final String? trackedDepositId;
  final String? pendingAttemptId;
  final int checkAgainCooldownRemaining;
  final String? amountServerError;
  final String? transactionRefServerError;
  final String? previewNotice;
  final int guideTabIndex;

  bool get isCooldownActive => checkAgainCooldownRemaining > 0;

  DepositState copyWith({
    DepositEntryTab? entryTab,
    PaymentProvider? provider,
    bool clearProvider = false,
    bool? isChoosingProvider,
    SmartDepositParseResult? smartParseResult,
    bool clearSmartParseResult = false,
    bool? isSubmitting,
    bool? checkInFlight,
    DepositConfirmationState? confirmation,
    bool clearConfirmation = false,
    String? trackedDepositId,
    bool clearTrackedId = false,
    String? pendingAttemptId,
    bool clearPendingAttemptId = false,
    int? checkAgainCooldownRemaining,
    String? amountServerError,
    bool clearAmountServerError = false,
    String? transactionRefServerError,
    bool clearTransactionRefServerError = false,
    String? previewNotice,
    bool clearPreviewNotice = false,
    int? guideTabIndex,
  }) {
    return DepositState(
      entryTab: entryTab ?? this.entryTab,
      provider: clearProvider ? null : (provider ?? this.provider),
      isChoosingProvider: isChoosingProvider ?? this.isChoosingProvider,
      smartParseResult: clearSmartParseResult
          ? null
          : (smartParseResult ?? this.smartParseResult),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      checkInFlight: checkInFlight ?? this.checkInFlight,
      confirmation:
          clearConfirmation ? null : (confirmation ?? this.confirmation),
      trackedDepositId: clearTrackedId
          ? null
          : (trackedDepositId ?? this.trackedDepositId),
      pendingAttemptId: clearPendingAttemptId
          ? null
          : (pendingAttemptId ?? this.pendingAttemptId),
      checkAgainCooldownRemaining:
          checkAgainCooldownRemaining ?? this.checkAgainCooldownRemaining,
      amountServerError: clearAmountServerError
          ? null
          : (amountServerError ?? this.amountServerError),
      transactionRefServerError: clearTransactionRefServerError
          ? null
          : (transactionRefServerError ?? this.transactionRefServerError),
      previewNotice:
          clearPreviewNotice ? null : (previewNotice ?? this.previewNotice),
      guideTabIndex: guideTabIndex ?? this.guideTabIndex,
    );
  }
}
