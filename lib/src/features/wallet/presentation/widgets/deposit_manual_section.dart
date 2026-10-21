import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/deposit_config_model.dart';
import '../../data/models/payment_provider.dart';
import '../../domain/wallet_amount_limits.dart';
import '../controllers/deposit_controller.dart';
import '../providers/deposit_config_provider.dart';
import '../utils/cbe_manual_receipt_reference.dart';
import '../utils/deposit_receipt_code.dart';
import 'deposit_form_section.dart';

class DepositManualSection extends ConsumerStatefulWidget {
  const DepositManualSection({
    super.key,
    this.initialAmount,
    this.initialTransactionRef,
  });

  final String? initialAmount;
  final String? initialTransactionRef;

  @override
  ConsumerState<DepositManualSection> createState() =>
      _DepositManualSectionState();
}

class _DepositManualSectionState extends ConsumerState<DepositManualSection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _transactionRefController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount);
    _transactionRefController =
        TextEditingController(text: widget.initialTransactionRef);
    _amountController.addListener(_onFieldChanged);
    _transactionRefController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted) return;
    ref.read(depositControllerProvider.notifier).clearServerErrors();
    setState(() {});
  }

  bool _canSubmit(bool isSubmitting) {
    if (isSubmitting) return false;
    if (!WalletAmountLimits.isSubmittableDeposit(_amountController.text)) {
      return false;
    }
    return _transactionRefController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(depositControllerProvider.notifier).submitDeposit(
          amount: _amountController.text.trim(),
          rawTransactionInput: _transactionRefController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(depositControllerProvider);
    final provider = state.provider ?? PaymentProvider.cbe;
    final depositConfig = ref.watch(depositConfigProvider).asData?.value;
    final providerConfig = depositConfig?.providerForKey(provider.apiValue);
    final receiptLabel =
        providerConfig?.receiptCodeLabel ?? provider.transactionRefLabel;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DepositFormSection(
            provider: provider,
            amountController: _amountController,
            transactionRefController: _transactionRefController,
            receiptLabel: receiptLabel,
            amountValidator: (v) => _validateAmount(v, l10n),
            transactionRefValidator: (v) =>
                _validateTransactionRef(v, provider, providerConfig, l10n),
            onFieldChanged: _onFieldChanged,
            amountServerError: state.amountServerError,
            transactionRefServerError: state.transactionRefServerError,
            previewNotice: state.previewNotice,
            preserveTransactionRefCase: provider == PaymentProvider.cbe &&
                providerConfig?.approvalMode == 'manual',
          ),
          VGap.xl,
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppBranding.goldAccent,
              foregroundColor: AppBranding.brandPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _canSubmit(state.isSubmitting) ? _submit : null,
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.depositSubmit),
          ),
        ],
      ),
    );
  }

  String? _validateAmount(String? value, dynamic l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.validatorAmountRequired as String;
    if (!WalletAmountLimits.amountPattern.hasMatch(trimmed)) {
      return l10n.validatorAmountInvalid as String;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return l10n.validatorAmountPositive as String;
    }
    if (parsed < WalletAmountLimits.minDeposit) {
      return l10n.validatorDepositAmountMin(
        WalletAmountLimits.formatLimit(WalletAmountLimits.minDeposit),
      ) as String;
    }
    if (parsed > WalletAmountLimits.maxDeposit) {
      return l10n.validatorDepositAmountMax(
        WalletAmountLimits.formatLimit(WalletAmountLimits.maxDeposit),
      ) as String;
    }
    return null;
  }

  String? _validateTransactionRef(
    String? value,
    PaymentProvider provider,
    DepositProviderConfig? providerConfig,
    dynamic l10n,
  ) {
    if (provider == PaymentProvider.telebirr) {
      final normalized = normalizeDepositReceiptCode(value ?? '');
      if (normalized.contains('/')) {
        return l10n.depositReceiptUrlNotAllowed as String;
      }
      return validateTelebirrReceiptCode(value) != null
          ? l10n.depositReceiptCodeInvalid as String
          : null;
    }

    if (provider == PaymentProvider.cbe &&
        providerConfig?.approvalMode == 'manual') {
      final baseUrl = providerConfig!.receiptBaseUrl.isEmpty
          ? kDefaultCbeReceiptBaseUrl
          : providerConfig.receiptBaseUrl;
      return normalizeCbeManualReceiptReference(
                value ?? '',
                receiptBaseUrl: baseUrl,
              ) ==
              null
          ? 'Enter a valid CBE receipt ID or official receipt URL.'
          : null;
    }

    final trimmed = value?.trim().toUpperCase() ?? '';
    if (trimmed.length < 6) {
      return l10n.validatorTransactionRef as String;
    }
    return null;
  }
}
