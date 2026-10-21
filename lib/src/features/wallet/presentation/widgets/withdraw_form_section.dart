import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/security_password_sheet.dart';
import '../../data/models/payment_provider.dart';
import '../../domain/wallet_amount_limits.dart';
import '../controllers/withdraw_controller.dart';
import '../models/withdrawal_confirmation_state.dart';
import '../utils/wallet_validation_utils.dart';
import 'withdraw_confirm_dialog.dart';
import 'withdrawal_confirmation_banner.dart';

class WithdrawFormSection extends ConsumerStatefulWidget {
  const WithdrawFormSection({super.key, this.availableBalance});

  final String? availableBalance;

  @override
  ConsumerState<WithdrawFormSection> createState() => _WithdrawFormSectionState();
}

class _WithdrawFormSectionState extends ConsumerState<WithdrawFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiverController = TextEditingController();
  PaymentProvider? _lastProvider;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onFormChanged);
    _receiverController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!mounted) return;
    final state = ref.read(withdrawControllerProvider);
    if (state.confirmation != null &&
        state.confirmation?.kind != WithdrawalConfirmationKind.pending) {
      ref.read(withdrawControllerProvider.notifier).clearConfirmation();
    }
    setState(() {});
  }

  void _syncProviderDefaults(
    PaymentProvider? provider,
    String? ownPhone,
    String savedCbe,
  ) {
    if (provider == null || provider == _lastProvider) return;
    _lastProvider = provider;
    _amountController.clear();
    if (provider == PaymentProvider.telebirr) {
      _receiverController.text = ownPhone ?? '';
    } else if (provider == PaymentProvider.cbe) {
      _receiverController.text = savedCbe.isNotEmpty ? savedCbe : '1000';
    }
  }

  bool _canSubmit(bool isSubmitting, PaymentProvider? provider) {
    if (provider == null || isSubmitting) return false;
    if (!WalletAmountLimits.isSubmittableWithdraw(_amountController.text)) {
      return false;
    }
    final parsed = WalletAmountLimits.tryParseAmount(_amountController.text);
    final available = double.tryParse(widget.availableBalance ?? '');
    if (parsed != null && available != null && parsed > available) {
      return false;
    }
    return _receiverController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = ref.read(authControllerProvider).session;
    if (session == null) return;

    if (!session.user.hasPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.withdrawSetPasswordFirst)),
      );
      await showSecurityPasswordSheet(context, ref);
      return;
    }

    final password = await showWithdrawConfirmDialog(context);
    if (password == null || !mounted) return;

    try {
      await ref.read(withdrawControllerProvider.notifier).submitWithdrawal(
            amount: _amountController.text.trim(),
            receiver: _receiverController.text.trim(),
            password: password,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException ? e.message : context.l10n.withdrawCouldNotSubmit,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(withdrawControllerProvider);
    final provider = state.provider;

    _syncProviderDefaults(provider, state.ownPhoneNumber, state.savedCbeAccount);

    final isOtherTelebirr = WalletValidationUtils.isOtherTelebirrNumber(
      provider: provider,
      ownPhone: state.ownPhoneNumber,
      enteredPhone: _receiverController.text,
    );
    final minLabel =
        WalletAmountLimits.formatLimit(WalletAmountLimits.minWithdraw);
    final maxLabel =
        WalletAmountLimits.formatLimit(WalletAmountLimits.maxWithdraw);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            provider == PaymentProvider.telebirr
                ? l10n.withdrawTelebirrOnlyHint
                : l10n.withdrawCbeOnlyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              WalletAmountInputFormatter(
                maxAmount: WalletAmountLimits.maxWithdraw,
              ),
            ],
            decoration: InputDecoration(
              labelText: l10n.withdrawAmount,
              hintText: minLabel,
              helperText: l10n.withdrawAmountRangeHelper(minLabel, maxLabel),
            ),
            validator: (v) => WalletValidationUtils.validateAmount(
              value: v,
              availableBalance: widget.availableBalance,
              l10n: l10n,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _receiverController,
            keyboardType: provider == PaymentProvider.telebirr
                ? TextInputType.phone
                : TextInputType.number,
            style: isOtherTelebirr
                ? TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  )
                : null,
            decoration: InputDecoration(
              labelText: provider?.receiverFieldLabel ?? '',
              hintText: provider == PaymentProvider.telebirr
                  ? (state.ownPhoneNumber ?? provider?.receiverFieldHint)
                  : provider?.receiverFieldHint,
              helperText: provider == PaymentProvider.telebirr
                  ? (isOtherTelebirr
                      ? 'Other number — payout goes here (not your account phone).'
                      : 'Own number (recommended)')
                  : (provider == PaymentProvider.cbe
                      ? 'Starts with 1000. Your account is saved on this device.'
                      : null),
              helperStyle: TextStyle(
                color: isOtherTelebirr
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: provider == PaymentProvider.telebirr &&
                      state.ownPhoneNumber != null &&
                      isOtherTelebirr
                  ? TextButton(
                      onPressed: () => _receiverController.text =
                          state.ownPhoneNumber ?? '',
                      child: const Text('Use mine'),
                    )
                  : null,
            ),
            validator: (v) => WalletValidationUtils.validateReceiver(
              value: v,
              provider: provider,
              l10n: l10n,
            ),
            onChanged: (value) {
              if (provider == PaymentProvider.cbe) {
                final trimmed = value.trim();
                if (trimmed.startsWith('1000') && trimmed.length >= 5) {
                  ref
                      .read(withdrawControllerProvider.notifier)
                      .schedulePersistCbeAccount(trimmed);
                }
              }
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppBranding.goldAccent,
              foregroundColor: AppBranding.brandPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _canSubmit(state.isSubmitting, provider) ? _submit : null,
            child: state.isSubmitting
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
            child: state.confirmation == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: WithdrawalConfirmationBanner(
                        key: ValueKey(state.confirmation!.switchKey),
                        state: state.confirmation!,
                        onDismiss: ref
                            .read(withdrawControllerProvider.notifier)
                            .clearConfirmation,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
