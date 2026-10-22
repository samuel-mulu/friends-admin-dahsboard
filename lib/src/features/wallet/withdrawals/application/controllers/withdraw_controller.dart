import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/realtime/wallet_entity_realtime.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../../core/storage/app_preferences_storage.dart';
import '../../../overview/application/providers/wallet_provider.dart';
import '../../../shared/domain/entities/payment_provider.dart';
import '../../../transactions/application/providers/wallet_transactions_provider.dart';
import '../../data/repositories/withdrawals_repository.dart';
import '../models/withdraw_state.dart';
import '../models/withdrawal_confirmation_state.dart';
import '../providers/withdrawal_history_provider.dart';

final withdrawControllerProvider =
    NotifierProvider<WithdrawController, WithdrawState>(WithdrawController.new);

class WithdrawController extends Notifier<WithdrawState> {
  Timer? _autoDismissTimer;
  Timer? _cbeSaveDebounce;
  static const _approvedDismissDelay = Duration(seconds: 8);

  @override
  WithdrawState build() {
    ref.onDispose(() {
      _autoDismissTimer?.cancel();
      _cbeSaveDebounce?.cancel();
    });

    final session = ref.watch(authControllerProvider).session;
    final phone = session?.user.phoneNumber.trim();
    return WithdrawState(
      ownPhoneNumber: (phone != null && phone.isNotEmpty) ? phone : null,
    );
  }

  void selectProvider(PaymentProvider provider) {
    state = state.copyWith(
      provider: provider,
      isChoosingProvider: false,
      clearConfirmation: true,
      clearTrackedId: true,
    );
  }

  void changeProvider() {
    _autoDismissTimer?.cancel();
    state = state.copyWith(
      isChoosingProvider: true,
      clearConfirmation: true,
      clearTrackedId: true,
    );
  }

  void clearConfirmation() {
    _autoDismissTimer?.cancel();
    state = state.copyWith(clearConfirmation: true, clearTrackedId: true);
  }

  Future<void> loadSavedCbeAccount(String userId) async {
    final storage = await ref.read(appPreferencesStorageProvider.future);
    final saved = storage.readCbeWithdrawAccount(userId);
    state = state.copyWith(savedCbeAccount: saved);
  }

  void schedulePersistCbeAccount(String account) {
    _cbeSaveDebounce?.cancel();
    _cbeSaveDebounce = Timer(const Duration(milliseconds: 400), () async {
      final userId = ref.read(authControllerProvider).session?.user.id;
      if (userId == null) return;
      final trimmed = account.trim();
      if (trimmed.isEmpty || trimmed == state.savedCbeAccount) return;
      final storage = await ref.read(appPreferencesStorageProvider.future);
      await storage.writeCbeWithdrawAccount(userId, trimmed);
      state = state.copyWith(savedCbeAccount: trimmed);
    });
  }

  void handleRealtimeUpdate(WalletEntityUpdate update) {
    if (!update.isTerminal || state.trackedWithdrawalId != update.id) return;
    if (update.isApproved) {
      state = state.copyWith(
        confirmation: WithdrawalConfirmationState(
          kind: WithdrawalConfirmationKind.approved,
          provider: state.provider,
          amount: update.amount,
          withdrawalId: update.id,
        ),
      );
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(_approvedDismissDelay, clearConfirmation);
    } else if (update.isRejected) {
      _autoDismissTimer?.cancel();
      state = state.copyWith(
        clearTrackedId: true,
        confirmation: WithdrawalConfirmationState(
          kind: WithdrawalConfirmationKind.rejected,
          provider: state.provider,
          amount: update.amount,
          withdrawalId: update.id,
          message: update.message,
        ),
      );
    }
  }

  void consumeCachedWithdrawalUpdate() {
    final trackedId = state.trackedWithdrawalId;
    if (trackedId == null) return;
    final update = ref.read(walletEntityRealtimeProvider).find(
      kind: WalletEntityKind.withdrawal,
      id: trackedId,
    );
    if (update != null) {
      handleRealtimeUpdate(update);
    }
  }

  Future<bool> submitWithdrawal({
    required String amount,
    required String receiver,
    required String password,
  }) async {
    final provider = state.provider;
    if (provider == null || state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true);
    try {
      final withdrawal = await ref
          .read(withdrawalsRepositoryProvider)
          .createWithdrawal(
            provider: provider,
            amount: amount,
            password: password,
            receiverPhone:
                provider == PaymentProvider.telebirr ? receiver : null,
            receiverAccount: provider == PaymentProvider.cbe ? receiver : null,
          );

      if (provider == PaymentProvider.cbe) {
        final storage = await ref.read(appPreferencesStorageProvider.future);
        final userId = ref.read(authControllerProvider).session?.user.id;
        if (userId != null) {
          await storage.writeCbeWithdrawAccount(userId, receiver.trim());
        }
      }

      ref.invalidate(myWalletProvider);
      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      state = state.copyWith(
        isSubmitting: false,
        trackedWithdrawalId: withdrawal.id,
        confirmation: WithdrawalConfirmationState.pending(
          provider: provider,
          amount: amount,
          withdrawalId: withdrawal.id,
        ),
      );
      consumeCachedWithdrawalUpdate();
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}
