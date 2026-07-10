import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/local_reauth_dialog.dart';
import '../../data/models/payment_provider.dart';
import '../../data/models/withdrawal_model.dart';
import '../models/withdrawal_confirmation_state.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';
import '../../data/wallet_repository.dart';
import '../widgets/withdraw_balance_strip.dart';
import '../widgets/withdraw_provider_chips.dart';
import '../widgets/withdrawal_confirmation_banner.dart';
import '../widgets/withdrawal_requests_table.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  static const _approvedDismissDelay = Duration(seconds: 8);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiverController = TextEditingController();

  PaymentProvider _provider = PaymentProvider.telebirr;
  bool _isSubmitting = false;
  WithdrawalConfirmationState? _confirmation;
  String? _trackedWithdrawalId;
  String? _availableBalance;
  Timer? _autoDismissTimer;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _socketService.on('withdrawal:updated', _onWithdrawalUpdated);
    _amountController.addListener(_onFormFieldChanged);
    _receiverController.addListener(_onFormFieldChanged);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _socketService.off('withdrawal:updated', _onWithdrawalUpdated);
    _amountController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  void _onWithdrawalUpdated(dynamic payload) {
    if (!mounted || payload is! Map) {
      return;
    }

    ref.invalidate(withdrawalHistoryProvider);

    final withdrawalId = payload['id']?.toString();
    if (withdrawalId == null ||
        (_trackedWithdrawalId != null && withdrawalId != _trackedWithdrawalId)) {
      return;
    }

    final status = payload['status']?.toString().toUpperCase();
    final adminNote = payload['adminNote']?.toString();

    if (status == 'PAID') {
      setState(() {
        _confirmation = WithdrawalConfirmationState(
          kind: WithdrawalConfirmationKind.approved,
          provider: _provider,
          amount: payload['amount']?.toString(),
          withdrawalId: withdrawalId,
        );
      });
      _scheduleApprovedDismiss();
      ref.invalidate(myWalletProvider);
      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(walletTransactionsProvider);
    } else if (status == 'REJECTED') {
      setState(() {
        _confirmation = WithdrawalConfirmationState(
          kind: WithdrawalConfirmationKind.rejected,
          provider: _provider,
          amount: payload['amount']?.toString(),
          withdrawalId: withdrawalId,
          message: adminNote,
        );
        _trackedWithdrawalId = null;
      });
      ref.invalidate(myWalletProvider);
      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(walletTransactionsProvider);
    }
  }

  void _scheduleApprovedDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(_approvedDismissDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _confirmation = null;
        _trackedWithdrawalId = null;
      });
    });
  }

  void _clearConfirmation() {
    _autoDismissTimer?.cancel();
    setState(() {
      _confirmation = null;
      _trackedWithdrawalId = null;
    });
  }

  void _onFormFieldChanged() {
    if (_confirmation != null) {
      _clearConfirmation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final walletAsync = ref.watch(myWalletProvider);
    final withdrawalsAsync = ref.watch(withdrawalHistoryProvider);
    final availableBalance = walletAsync.asData?.value.balance;
    if (availableBalance != null) {
      _availableBalance = availableBalance;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.withdrawScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                walletAsync.maybeWhen(
                  data: (wallet) => WithdrawBalanceStrip(
                    availableBalance: wallet.balance,
                    lockedBalance: wallet.lockedBalance,
                    totalBalance: wallet.totalBalance,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                WithdrawProviderChips(
                  value: _provider,
                  onChanged: (provider) {
                    setState(() {
                      _provider = provider;
                      _clearConfirmation();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.withdrawAmount,
                    hintText: '100',
                    helperText: l10n.withdrawAmountLockedHelper,
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receiverController,
                  keyboardType: _provider == PaymentProvider.telebirr
                      ? TextInputType.phone
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _provider.receiverFieldLabel,
                    hintText: _provider.receiverFieldHint,
                  ),
                  validator: _validateReceiver,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppBranding.goldAccent,
                    foregroundColor: AppBranding.brandPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.withdrawSubmit),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _confirmation == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: WithdrawalConfirmationBanner(
                              key: ValueKey(_confirmation!.switchKey),
                              state: _confirmation!,
                              onDismiss: _clearConfirmation,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  l10n.withdrawRequestsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                withdrawalsAsync.when(
                  data: (result) {
                    if (result.items.isEmpty) {
                      return Text(
                        l10n.withdrawHistoryEmptyMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }

                    return WithdrawalRequestsTable(
                      withdrawals: result.items,
                      compact: true,
                      initialFilter: result.items.any(
                            (w) => w.status == WithdrawalStatus.pending,
                          )
                          ? WithdrawalHistoryFilter.pending
                          : WithdrawalHistoryFilter.all,
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: FriendsBingoLoader.inline(),
                  ),
                  error: (_, _) => Text(
                    l10n.withdrawHistoryCouldNotLoad,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (ref.read(authControllerProvider).session == null) {
      return;
    }

    final confirmed = await showLocalReauthDialog(context);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final receiverValue = _receiverController.text.trim();
      final amount = _amountController.text.trim();
      final withdrawal = await ref
          .read(walletRepositoryProvider)
          .createWithdrawal(
            provider: _provider,
            amount: amount,
            receiverPhone: _provider == PaymentProvider.telebirr
                ? receiverValue
                : null,
            receiverAccount: _provider == PaymentProvider.cbe
                ? receiverValue
                : null,
          );

      ref.invalidate(myWalletProvider);
      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _trackedWithdrawalId = withdrawal.id;
        _confirmation = WithdrawalConfirmationState.pending(
          provider: _provider,
          amount: amount,
          withdrawalId: withdrawal.id,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : context.l10n.withdrawCouldNotSubmit,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateAmount(String? value) {
    final l10n = context.l10n;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.validatorAmountRequired;
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmed)) {
      return l10n.validatorAmountInvalid;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return l10n.validatorAmountPositive;
    }

    final available = double.tryParse(_availableBalance ?? '');
    if (available != null && parsed > available) {
      return l10n.withdrawAmountExceedsAvailable;
    }

    return null;
  }

  String? _validateReceiver(String? value) {
    final l10n = context.l10n;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '${_provider.receiverFieldLabel} ${l10n.validatorPhoneRequired.replaceFirst('Phone number', '').trim()}';
    }
    if (_provider == PaymentProvider.telebirr &&
        !RegExp(r'^\d{10,15}$').hasMatch(trimmed)) {
      return l10n.validatorPhoneInvalid;
    }
    return null;
  }
}
