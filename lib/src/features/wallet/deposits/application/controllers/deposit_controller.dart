import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/realtime/socket_service.dart';
import '../../../../../core/realtime/wallet_entity_realtime.dart';
import '../../../../../core/storage/app_preferences_storage.dart';
import '../../../../auth/application/controllers/auth_controller.dart';
import '../../../overview/application/providers/wallet_provider.dart';
import '../../../shared/domain/entities/payment_provider.dart';
import '../../../transactions/application/providers/wallet_transactions_provider.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/pending_deposit_verification.dart';
import '../../data/repositories/deposits_repository.dart';
import '../../domain/parsers/cbe_manual_receipt_reference.dart';
import '../../domain/parsers/cbe_smart_deposit_parser.dart';
import '../../domain/parsers/smart_deposit_parse_result.dart';
import '../../domain/parsers/telebirr_smart_deposit_parser.dart';
import '../../domain/utils/deposit_submission_preparer.dart';
import '../models/deposit_confirmation_state.dart';
import '../models/deposit_state.dart';
import '../providers/deposit_config_provider.dart';
import '../providers/deposit_history_provider.dart';

final depositControllerProvider =
    NotifierProvider<DepositController, DepositState>(DepositController.new);

class DepositController extends Notifier<DepositState> {
  Timer? _autoDismissTimer;
  Timer? _cooldownTimer;
  SocketService? _socketService;
  static const _approvedDismissDelay = Duration(seconds: 8);

  @override
  DepositState build() {
    ref.onDispose(() {
      _autoDismissTimer?.cancel();
      _cooldownTimer?.cancel();
      _socketService?.off('wallet:updated', _onWalletUpdatedWhilePending);
    });

    try {
      _socketService = ref.read(socketServiceProvider);
      _socketService?.off('wallet:updated', _onWalletUpdatedWhilePending);
      _socketService?.on('wallet:updated', _onWalletUpdatedWhilePending);
    } catch (_) {
      // Allow testing without socketService initialized
    }

    return const DepositState();
  }

  void switchTab(DepositEntryTab tab) {
    if (state.entryTab == tab) return;
    final provider = state.provider;
    if (tab == DepositEntryTab.smart &&
        provider != null &&
        !provider.supportsSmartDepositEntry) {
      return;
    }
    state = state.copyWith(entryTab: tab);
  }

  void selectProvider(PaymentProvider provider) {
    if (state.provider == provider && !state.isChoosingProvider) return;
    state = state.copyWith(
      provider: provider,
      isChoosingProvider: false,
      entryTab: provider.supportsSmartDepositEntry
          ? DepositEntryTab.smart
          : DepositEntryTab.regular,
      clearSmartParseResult: true,
      clearConfirmation: true,
      clearTrackedId: true,
      clearAmountServerError: true,
      clearTransactionRefServerError: true,
      clearPreviewNotice: true,
      guideTabIndex: 0,
    );
  }

  void changeProvider() {
    state = state.copyWith(
      isChoosingProvider: true,
      entryTab: DepositEntryTab.smart,
      clearSmartParseResult: true,
      clearConfirmation: true,
      clearTrackedId: true,
      clearAmountServerError: true,
      clearTransactionRefServerError: true,
      clearPreviewNotice: true,
      guideTabIndex: 0,
    );
  }

  void setGuideTabIndex(int index) {
    state = state.copyWith(guideTabIndex: index);
  }

  void clearConfirmation() {
    _autoDismissTimer?.cancel();
    _cooldownTimer?.cancel();
    state = state.copyWith(
      clearConfirmation: true,
      clearTrackedId: true,
      clearPendingAttemptId: true,
      checkAgainCooldownRemaining: 0,
    );
  }

  void clearServerErrors() {
    state = state.copyWith(
      clearAmountServerError: true,
      clearTransactionRefServerError: true,
    );
  }

  SmartDepositParseResult parseSmartInput(String value) {
    final provider = state.provider;
    if (provider == null) {
      return const SmartDepositParseResult.unsupported();
    }
    final SmartDepositParseResult result;
    if (provider == PaymentProvider.telebirr) {
      result = parseTelebirrSmartDepositInput(value);
    } else if (provider == PaymentProvider.cbe) {
      final config = ref.read(depositConfigProvider).asData?.value;
      final cbeConfig = config?.providerForKey(PaymentProvider.cbe.apiValue);
      final baseUrl = (cbeConfig?.receiptBaseUrl.isEmpty ?? true)
          ? kDefaultCbeReceiptBaseUrl
          : cbeConfig!.receiptBaseUrl;
      result = parseCbeSmartDepositInput(value, receiptBaseUrl: baseUrl);
    } else {
      result = const SmartDepositParseResult.unsupported();
    }

    state = state.copyWith(
      smartParseResult: value.trim().isEmpty ? null : result,
      clearSmartParseResult: value.trim().isEmpty,
    );
    return result;
  }

  void _onWalletUpdatedWhilePending(dynamic _) {
    if (state.confirmation?.kind != DepositConfirmationKind.pending ||
        state.trackedDepositId == null) {
      return;
    }
    unawaited(refreshTrackedDepositFromServer());
  }

  Future<void> refreshTrackedDepositFromServer() async {
    final depositId = state.trackedDepositId;
    if (depositId == null ||
        state.confirmation?.kind != DepositConfirmationKind.pending) {
      return;
    }

    try {
      final page = await ref
          .read(depositsRepositoryProvider)
          .getMyDeposits(page: 1, pageSize: 20);
      DepositModel? match;
      for (final item in page.items) {
        if (item.id == depositId) {
          match = item;
          break;
        }
      }
      if (match == null) return;

      if (match.status == DepositStatus.approved) {
        applyDepositTerminalStatus(
          kind: DepositConfirmationKind.approved,
          depositId: match.id,
          provider: match.provider,
          amount: match.amount,
          transactionRef: match.transactionRef,
        );
        ref.invalidate(myWalletProvider);
        ref.invalidate(walletTransactionsProvider);
        ref.invalidate(depositHistoryProvider);
      } else if (match.status == DepositStatus.rejected) {
        applyDepositTerminalStatus(
          kind: DepositConfirmationKind.rejected,
          depositId: match.id,
          provider: match.provider,
          amount: match.amount,
          transactionRef: match.transactionRef,
          message: match.rejectionReason,
          canRetry: true,
        );
        ref.invalidate(depositHistoryProvider);
      }
    } catch (_) {}
  }

  void handleRealtimeUpdate(WalletEntityUpdate update) {
    if (!update.isTerminal) return;

    final matchesTrackedId =
        state.trackedDepositId != null && update.id == state.trackedDepositId;
    final matchesPendingRef =
        state.confirmation?.kind == DepositConfirmationKind.pending &&
            update.transactionRef != null &&
            update.transactionRef!.isNotEmpty &&
            state.confirmation?.transactionRef == update.transactionRef;
    final matchesConfirmationId = state.confirmation?.depositId != null &&
        state.confirmation!.depositId == update.id &&
        (state.confirmation?.kind == DepositConfirmationKind.pending ||
            state.confirmation?.kind == DepositConfirmationKind.underReview);

    if (!matchesTrackedId && !matchesPendingRef && !matchesConfirmationId) {
      return;
    }

    PaymentProvider? provider;
    try {
      final rawProvider = update.provider;
      if (rawProvider != null && rawProvider.isNotEmpty) {
        provider = PaymentProvider.fromApi(rawProvider);
      }
    } catch (_) {
      provider = state.provider;
    }

    if (update.isApproved) {
      applyDepositTerminalStatus(
        kind: DepositConfirmationKind.approved,
        depositId: update.id,
        provider: provider ?? state.provider,
        amount: update.amount,
        transactionRef: update.transactionRef,
      );
    } else if (update.isRejected) {
      applyDepositTerminalStatus(
        kind: DepositConfirmationKind.rejected,
        depositId: update.id,
        provider: provider ?? state.provider,
        amount: update.amount,
        transactionRef: update.transactionRef,
        message: update.message?.trim().isNotEmpty == true
            ? update.message
            : null,
        canRetry: true,
      );
    }
  }

  void applyDepositTerminalStatus({
    required DepositConfirmationKind kind,
    required String depositId,
    PaymentProvider? provider,
    String? amount,
    String? transactionRef,
    String? message,
    bool canRetry = false,
  }) {
    state = state.copyWith(
      isSubmitting: false,
      trackedDepositId:
          kind == DepositConfirmationKind.approved ? depositId : null,
      clearTrackedId: kind != DepositConfirmationKind.approved,
      confirmation: DepositConfirmationState(
        kind: kind,
        depositId: depositId,
        provider: provider,
        amount: amount ?? state.confirmation?.amount,
        transactionRef: transactionRef ?? state.confirmation?.transactionRef,
        message: message,
        canRetry: canRetry,
        verifiedAt:
            kind == DepositConfirmationKind.approved ? DateTime.now() : null,
      ),
    );

    if (kind == DepositConfirmationKind.approved) {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(_approvedDismissDelay, clearConfirmation);
      _clearStoredPendingAttempt();
    }
  }

  Future<void> _clearStoredPendingAttempt() async {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null) return;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.clearPendingDepositAttempt(userId);
  }

  Future<void> _persistPendingAttempt(PendingDepositVerification pending) async {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null) return;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writePendingDepositAttempt(
      userId: userId,
      attemptId: pending.attemptId,
      provider: pending.provider.apiValue,
      amount: pending.amount,
      transactionRef: pending.transactionRef,
    );
  }

  void _scheduleCheckAgainCooldown(DateTime availableAt) {
    _cooldownTimer?.cancel();
    final delay = availableAt.difference(DateTime.now());
    if (delay.isNegative || delay == Duration.zero) {
      _setCanCheckAgain(availableAt);
      return;
    }
    _cooldownTimer = Timer(delay, () => _setCanCheckAgain(availableAt));
  }

  void _setCanCheckAgain(DateTime availableAt) {
    if (state.confirmation?.kind ==
        DepositConfirmationKind.verificationInProgress) {
      state = state.copyWith(
        confirmation: DepositConfirmationState(
          kind: DepositConfirmationKind.verificationInProgress,
          message: state.confirmation?.message,
          provider: state.confirmation?.provider,
          amount: state.confirmation?.amount,
          transactionRef: state.confirmation?.transactionRef,
          attemptId: state.confirmation?.attemptId,
          canCheckAgain: true,
          checkAgainAvailableAt: availableAt,
        ),
      );
    }
  }

  Future<void> restorePendingVerificationAttempt() async {
    final session = ref.read(authControllerProvider).session;
    final userId = session?.user.id;
    if (userId == null) return;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    final raw = storage.readPendingDepositAttempt(userId);
    if (raw == null || raw.isEmpty) return;
    final parts = raw.split('|');
    if (parts.length < 4) {
      await storage.clearPendingDepositAttempt(userId);
      return;
    }
    final attemptId = parts[0];
    final provider = PaymentProvider.fromApi(parts[1]);
    final amount = parts[2];
    final transactionRef = parts.sublist(3).join('|');

    try {
      final active = await ref
          .read(depositsRepositoryProvider)
          .getActiveVerificationAttempt(
            provider: provider,
            transactionRef: transactionRef,
          );
      if (active == null) {
        await storage.clearPendingDepositAttempt(userId);
        return;
      }
      final availableAt = DateTime.now().add(
        Duration(seconds: active.retryAfterSeconds),
      );
      state = state.copyWith(
        provider: provider,
        isChoosingProvider: false,
        entryTab: DepositEntryTab.regular,
        pendingAttemptId: active.attemptId,
        confirmation: DepositConfirmationState(
          kind: DepositConfirmationKind.verificationInProgress,
          message: active.message,
          provider: provider,
          amount: amount,
          transactionRef: transactionRef,
          attemptId: active.attemptId,
          canCheckAgain: true,
          checkAgainAvailableAt: availableAt,
        ),
      );
      _scheduleCheckAgainCooldown(availableAt);
    } catch (_) {
      state = state.copyWith(
        provider: provider,
        isChoosingProvider: false,
        entryTab: DepositEntryTab.regular,
        pendingAttemptId: attemptId,
        confirmation: DepositConfirmationState(
          kind: DepositConfirmationKind.verificationInProgress,
          provider: provider,
          amount: amount,
          transactionRef: transactionRef,
          attemptId: attemptId,
          canCheckAgain: true,
        ),
      );
    }
  }

  Future<void> submitDeposit({
    required String amount,
    required String rawTransactionInput,
  }) async {
    final provider = state.provider;
    if (provider == null || state.isSubmitting) return;

    clearConfirmation();
    state = state.copyWith(
      isSubmitting: true,
      clearAmountServerError: true,
      clearTransactionRefServerError: true,
      clearPreviewNotice: true,
      confirmation: const DepositConfirmationState.verifying(),
    );

    try {
      final payload = await DepositSubmissionPreparer.prepare(
        ref: ref,
        provider: provider,
        amount: amount,
        rawTransactionInput: rawTransactionInput,
      );

      if (payload.validationError != null) {
        state = state.copyWith(
          isSubmitting: false,
          clearConfirmation: true,
          transactionRefServerError: payload.validationError,
        );
        return;
      }

      final result = await ref.read(depositsRepositoryProvider).createDeposit(
            provider: provider,
            amount: amount,
            transactionRef:
                payload.cbeManualReceiptUrl ?? payload.transactionRef,
            receiptParseStatus: payload.receiptParseStatus,
            clientReceipt: payload.clientReceipt,
          );

      ref.invalidate(depositHistoryProvider);

      switch (result) {
        case DepositSubmitPendingVerification(:final pending):
          final availableAt = DateTime.now().add(
            Duration(seconds: pending.retryAfterSeconds),
          );
          state = state.copyWith(
            isSubmitting: false,
            pendingAttemptId: pending.attemptId,
            confirmation: DepositConfirmationState(
              kind: DepositConfirmationKind.verificationInProgress,
              message: pending.message,
              provider: pending.provider,
              amount: pending.amount,
              transactionRef: pending.transactionRef,
              attemptId: pending.attemptId,
              canCheckAgain: false,
              checkAgainAvailableAt: availableAt,
            ),
          );
          await _persistPendingAttempt(pending);
          _scheduleCheckAgainCooldown(availableAt);

        case DepositSubmitApproved(:final deposit):
          if (deposit.status == DepositStatus.approved) {
            applyDepositTerminalStatus(
              kind: DepositConfirmationKind.approved,
              depositId: deposit.id,
              provider: deposit.provider,
              amount: deposit.amount,
              transactionRef: deposit.transactionRef,
            );
            ref.invalidate(myWalletProvider);
            ref.invalidate(walletTransactionsProvider);
            ref.invalidate(depositHistoryProvider);
          } else {
            state = state.copyWith(
              isSubmitting: false,
              trackedDepositId: deposit.id,
              clearPendingAttemptId: true,
              confirmation: DepositConfirmationState(
                kind: DepositConfirmationKind.pending,
                depositId: deposit.id,
                provider: deposit.provider,
                amount: deposit.amount,
                transactionRef: deposit.transactionRef,
              ),
            );
          }
      }
    } catch (error) {
      final code = error is ApiException ? error.code : null;
      final isUnavailable = code == 'VERIFICATION_UNAVAILABLE';
      if (isUnavailable) {
        ref.invalidate(depositConfigProvider);
      }
      final displayMessage = error is ApiException
          ? error.displayMessage
          : 'Failed to process deposit. Please check your connection and try again.';
      state = state.copyWith(
        isSubmitting: false,
        clearTrackedId: true,
        confirmation: DepositConfirmationState(
          kind: code == 'UNDER_REVIEW'
              ? DepositConfirmationKind.underReview
              : DepositConfirmationKind.rejected,
          message: isUnavailable
              ? 'Telebirr is temporarily busy. Please tap Try Again in a moment.'
              : displayMessage,
          provider: provider,
          amount: amount,
          transactionRef: rawTransactionInput.toUpperCase(),
          canRetry: code != 'ALREADY_USED' && code != 'UNDER_REVIEW',
          retryLabel: isUnavailable ? 'Try Again' : null,
        ),
      );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
