import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/deposit_config_model.dart';
import '../../data/models/payment_provider.dart';
import '../../data/models/telebirr_client_receipt_payload.dart';
import '../../data/models/telebirr_receipt_preview.dart';
import '../../data/receipt_ocr/receipt_ocr_result.dart';
import '../../data/receipt_ocr/receipt_ocr_service.dart';
import '../../data/telebirr_receipt_preview_service.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet_amount_limits.dart';
import '../providers/deposit_config_provider.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';
import '../debug/telebirr_deposit_debug.dart';
import '../models/deposit_confirmation_state.dart';
import '../utils/deposit_receipt_code.dart';
import '../widgets/deposit_confirmation_banner.dart';
import '../widgets/deposit_form_section.dart';
import '../widgets/deposit_guide_steps.dart';
import '../widgets/deposit_provider_chips.dart';
import '../widgets/deposit_settlement_account_card.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  static const _previewUnavailableMessage =
      'We could not preview the receipt. Server verification will continue.';
  static const _approvedDismissDelay = Duration(seconds: 8);
  static const _comingSoonProviders = {
    PaymentProvider.awash,
    PaymentProvider.boa,
  };

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _depositGuideKey = GlobalKey();
  final _amountController = TextEditingController();
  final _transactionRefController = TextEditingController();

  PaymentProvider _provider = PaymentProvider.cbe;
  bool _isSubmitting = false;
  bool _ocrReviewRequired = false;
  bool _receiptDetailsConfirmed = false;
  DepositConfirmationState? _confirmation;
  Timer? _autoDismissTimer;
  String? _amountServerError;
  String? _transactionRefServerError;
  String? _previewNotice;
  bool _ignoreFieldChanges = false;
  bool _isScanningReceipt = false;

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _scrollController.dispose();
    _amountController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  void _scrollToDepositGuide() {
    final guideContext = _depositGuideKey.currentContext;
    if (guideContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      guideContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  bool get _canSubmitDeposit {
    if (_isSubmitting) {
      return false;
    }
    if (_ocrReviewRequired && !_receiptDetailsConfirmed) {
      return false;
    }
    if (!WalletAmountLimits.isSubmittableDeposit(_amountController.text)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final depositConfig = ref.watch(depositConfigProvider);
    final config = depositConfig.asData?.value;
    final walletAsync = ref.watch(myWalletProvider);
    final availableProviders = _availableProviders(config);
    final receiptOcrService = ref.watch(receiptOcrServiceProvider);
    final activeProviders = availableProviders
        .where((p) => !_comingSoonProviders.contains(p))
        .toList(growable: false);
    final selectedProvider = activeProviders.contains(_provider)
        ? _provider
        : (activeProviders.isNotEmpty ? activeProviders.first : availableProviders.first);
    if (selectedProvider != _provider) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _provider = selectedProvider;
        });
      });
    }
    final receiptLabel = _receiptLabel(config, selectedProvider);
    final providerConfig = config?.providerForKey(selectedProvider.apiValue);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.depositScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                walletAsync.maybeWhen(
                  data: (wallet) => _BalanceStrip(amount: wallet.balance),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                DepositProviderChips(
                  value: selectedProvider,
                  availableProviders: availableProviders,
                  depositConfig: config,
                  comingSoonProviders: _comingSoonProviders,
                  onChanged: (provider) {
                    setState(() {
                      _provider = provider;
                      _clearServerErrors();
                      _previewNotice = null;
                      _clearOcrReviewState();
                      _clearConfirmation();
                    });
                  },
                ),
                if (providerConfig != null &&
                    providerConfig.settlementAccount.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DepositSettlementAccountCard(
                    settlementAccount: providerConfig.settlementAccount,
                    receiverName: providerConfig.receiverName,
                    onShowInstructions: _scrollToDepositGuide,
                  ),
                ],
                const SizedBox(height: 16),
                DepositFormSection(
                  provider: selectedProvider,
                  amountController: _amountController,
                  transactionRefController: _transactionRefController,
                  receiptLabel: receiptLabel,
                  amountValidator: _validateAmount,
                  transactionRefValidator: _validateTransactionRef,
                  onFieldChanged: _onFormFieldChanged,
                  amountServerError: _amountServerError,
                  transactionRefServerError: _transactionRefServerError,
                  previewNotice: _previewNotice,
                  onScanReceipt: receiptOcrService.isAvailable
                      ? _scanReceipt
                      : null,
                  isScanLoading: _isScanningReceipt,
                  scanTooltip: l10n.depositReceiptScan,
                ),
                if (_ocrReviewRequired) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _receiptDetailsConfirmed,
                    onChanged: (checked) {
                      setState(() {
                        _receiptDetailsConfirmed = checked ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.depositReceiptReviewLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ocrReviewRequired
                        ? Theme.of(context).colorScheme.error
                        : AppBranding.goldAccent,
                    foregroundColor: _ocrReviewRequired
                        ? Theme.of(context).colorScheme.onError
                        : AppBranding.brandPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _canSubmitDeposit ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.depositSubmit),
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
                            child: DepositConfirmationBanner(
                              key: ValueKey(_confirmation!.switchKey),
                              state: _confirmation!,
                              onDismiss: _clearConfirmation,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 20),
                KeyedSubtree(
                  key: _depositGuideKey,
                  child: DepositGuideSteps(provider: selectedProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onFormFieldChanged() {
    if (_ignoreFieldChanges) {
      return;
    }
    setState(() {
      if (_ocrReviewRequired) {
        _clearOcrReviewState();
      }
      if (_amountServerError != null || _transactionRefServerError != null) {
        _clearServerErrors();
      }
    });
    _clearConfirmation();
  }

  Future<void> _scanReceipt() async {
    if (_isScanningReceipt) {
      return;
    }

    final service = ref.read(receiptOcrServiceProvider);
    if (!service.isAvailable) {
      return;
    }

    FocusScope.of(context).unfocus();
    _clearConfirmation();
    setState(() {
      _isScanningReceipt = true;
      _clearServerErrors();
      _previewNotice = null;
    });

    try {
      final result = await service.scanReceipt(provider: _provider);
      if (!mounted || result == null) {
        return;
      }

      if (!result.hasDetectedValue || result.isLowConfidence) {
        _showReceiptScanSnackBar(context.l10n.depositReceiptScanFailure);
        return;
      }

      _applyReceiptOcrResult(result);
      _showReceiptScanSnackBar(
        result.hasReference && result.hasAmount
            ? context.l10n.depositReceiptScanSuccess
            : context.l10n.depositReceiptScanPartial,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showReceiptScanSnackBar(context.l10n.depositReceiptScanFailure);
    } finally {
      if (mounted) {
        setState(() {
          _isScanningReceipt = false;
        });
      }
    }
  }

  void _applyReceiptOcrResult(ReceiptOcrResult result) {
    _ignoreFieldChanges = true;
    if (result.hasAmount) {
      _amountController.text = result.amount!;
    }
    if (result.hasReference) {
      final rawReference = result.reference!.trim();
      _transactionRefController.text = _provider == PaymentProvider.telebirr
          ? normalizeDepositReceiptCode(rawReference)
          : rawReference.toUpperCase();
    }
    _ignoreFieldChanges = false;
    setState(() {
      _receiptDetailsConfirmed = false;
      _ocrReviewRequired = result.hasAmount && result.hasReference;
    });
  }

  void _showReceiptScanSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearDepositFormFields() {
    _ignoreFieldChanges = true;
    _amountController.clear();
    _transactionRefController.clear();
    _formKey.currentState?.reset();
    _ignoreFieldChanges = false;
    setState(_clearOcrReviewState);
  }

  void _clearOcrReviewState() {
    _ocrReviewRequired = false;
    _receiptDetailsConfirmed = false;
  }

  void _clearConfirmation() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    if (_confirmation != null) {
      setState(() => _confirmation = null);
    }
  }

  void _scheduleApprovedDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(_approvedDismissDelay, () {
      if (!mounted) {
        return;
      }
      if (_confirmation?.kind == DepositConfirmationKind.approved) {
        _clearConfirmation();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _clearConfirmation();
    setState(() {
      _isSubmitting = true;
      _clearServerErrors();
      _previewNotice = null;
      _confirmation = const DepositConfirmationState.verifying();
    });

    try {
      final rawTransactionInput = _transactionRefController.text.trim();
      final submittedAmount = _amountController.text.trim();
      final walletRepository = ref.read(walletRepositoryProvider);

      TelebirrReceiptParseStatus? receiptParseStatus;
      TelebirrClientReceiptPayload? clientReceipt;
      late final String transactionRef;

      if (_provider == PaymentProvider.telebirr) {
        transactionRef = normalizeDepositReceiptCode(rawTransactionInput);
        TelebirrDepositDebug.log(
          'submit start ref=${TelebirrDepositDebug.maskRef(transactionRef)} amountSet=${submittedAmount.isNotEmpty}',
        );

        final depositConfig = await ref.read(depositConfigProvider.future);
        final preview = await ref
            .read(telebirrReceiptPreviewServiceProvider)
            .preview(
              transactionRef: transactionRef,
              submittedAmount: submittedAmount,
              config: depositConfig.telebirr,
            );

        receiptParseStatus = preview.receiptParseStatus;
        clientReceipt = preview.toClientReceiptPayload();

        if (mounted) {
          if (preview.status ==
              TelebirrReceiptPreviewStatus.previewUnavailable) {
            setState(() {
              _previewNotice = preview.message ?? _previewUnavailableMessage;
            });
          } else if (preview.status != TelebirrReceiptPreviewStatus.valid) {
            final warning = _mapPreviewError(preview);
            setState(() {
              _previewNotice = warning;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(warning)));
          }
        }
      } else {
        transactionRef = rawTransactionInput.toUpperCase();
      }

      final checkResult = await walletRepository.checkDepositReference(
        provider: _provider,
        transactionRef: transactionRef,
      );

      if (!checkResult.isAvailable) {
        if (!mounted) {
          return;
        }

        final message =
            _mapDepositCodeToMessage(checkResult.code) ?? checkResult.message;
        setState(() {
          _transactionRefServerError = message;
          _confirmation = DepositConfirmationState(
            kind: DepositConfirmationKind.rejected,
            message: message,
            provider: _provider,
            amount: submittedAmount,
            transactionRef: transactionRef,
          );
        });
        return;
      }

      final deposit = await walletRepository.createDeposit(
        provider: _provider,
        amount: submittedAmount,
        transactionRef: transactionRef,
        receiptParseStatus: receiptParseStatus,
        clientReceipt: clientReceipt,
      );

      ref.invalidate(myWalletProvider);
      ref.invalidate(depositHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _confirmation = DepositConfirmationState(
          kind: DepositConfirmationKind.approved,
          provider: deposit.provider,
          amount: deposit.amount,
          transactionRef: deposit.transactionRef,
          verifiedAt: deposit.verifiedAt ?? deposit.createdAt,
        );
      });
      _clearDepositFormFields();
      _scheduleApprovedDismiss();
    } catch (error) {
      if (_provider == PaymentProvider.telebirr) {
        TelebirrDepositDebug.error('submit failed', error);
      }
      if (!mounted) {
        return;
      }

      final message = error is ApiException
          ? _handleDepositError(error)
          : context.l10n.depositCouldNotSubmit;

      setState(() {
        _confirmation = DepositConfirmationState(
          kind: DepositConfirmationKind.rejected,
          message: message,
          provider: _provider,
          amount: _amountController.text.trim(),
          transactionRef: _transactionRefController.text.trim().toUpperCase(),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearServerErrors() {
    _amountServerError = null;
    _transactionRefServerError = null;
  }

  String _receiptLabel(DepositConfigModel? config, PaymentProvider provider) {
    return config?.providerForKey(provider.apiValue)?.receiptCodeLabel ??
        provider.transactionRefLabel;
  }

  String _mapPreviewError(TelebirrReceiptPreview preview) {
    switch (preview.status) {
      case TelebirrReceiptPreviewStatus.amountMismatch:
        final settledAmount = preview.settledAmount;
        if (settledAmount != null && settledAmount.isNotEmpty) {
          return context.l10n.depositAmountMismatchSettled(settledAmount);
        }
        return context.l10n.depositAmountMismatch;
      case TelebirrReceiptPreviewStatus.receiverMismatch:
        return context.l10n.depositReceiverMismatch;
      case TelebirrReceiptPreviewStatus.invalidReceipt:
        return context.l10n.depositReceiptInvalid;
      case TelebirrReceiptPreviewStatus.previewUnavailable:
        return preview.message ?? _previewUnavailableMessage;
      case TelebirrReceiptPreviewStatus.valid:
        return '';
    }
  }

  String _handleDepositError(ApiException error) {
    final message = _mapDepositError(error);

    setState(() {
      switch (error.code) {
        case 'AMOUNT_MISMATCH':
          _amountServerError = message;
          break;
        case 'ALREADY_USED':
        case 'INVALID_RECEIPT':
        case 'RECEIVER_MISMATCH':
        case 'SETTLEMENT_MISMATCH':
          _transactionRefServerError = message;
          break;
      }
    });

    return message;
  }

  String _mapDepositError(ApiException error) {
    final mappedByCode = _mapDepositCodeToMessage(error.code);
    if (mappedByCode != null) {
      return mappedByCode;
    }

    final message = error.message;
    if (message.contains('This receipt has already been used')) {
      return context.l10n.depositReceiptDuplicate;
    }
    if (_isAmountMismatchReason(message)) {
      return context.l10n.depositAmountMismatch;
    }
    if (message.contains('This receipt was not paid to Friends Bingo')) {
      return context.l10n.depositReceiverMismatch;
    }
    if (message.contains('Receipt could not be verified')) {
      return context.l10n.depositReceiptInvalid;
    }
    return error.displayMessage;
  }

  String? _mapDepositCodeToMessage(String? code) {
    final l10n = context.l10n;

    switch (code) {
      case 'ALREADY_USED':
        return l10n.depositReceiptDuplicate;
      case 'AMOUNT_MISMATCH':
        return l10n.depositAmountMismatch;
      case 'RECEIVER_MISMATCH':
      case 'SETTLEMENT_MISMATCH':
        return l10n.depositReceiverMismatch;
      case 'INVALID_RECEIPT':
        return l10n.depositReceiptInvalid;
      case 'VERIFICATION_UNAVAILABLE':
        return l10n.depositCouldNotSubmit;
    }

    return null;
  }

  bool _isAmountMismatchReason(String reason) {
    return reason.toLowerCase().contains('amount does not match');
  }

  String? _validateAmount(String? value) {
    final l10n = context.l10n;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.validatorAmountRequired;
    }
    if (!WalletAmountLimits.amountPattern.hasMatch(trimmed)) {
      return l10n.validatorAmountInvalid;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return l10n.validatorAmountPositive;
    }
    if (parsed < WalletAmountLimits.minDeposit) {
      return l10n.validatorDepositAmountMin(
        WalletAmountLimits.formatLimit(WalletAmountLimits.minDeposit),
      );
    }
    if (parsed > WalletAmountLimits.maxDeposit) {
      return l10n.validatorDepositAmountMax(
        WalletAmountLimits.formatLimit(WalletAmountLimits.maxDeposit),
      );
    }
    return null;
  }

  String? _validateTransactionRef(String? value) {
    if (_provider == PaymentProvider.telebirr) {
      final normalized = normalizeDepositReceiptCode(value ?? '');
      if (normalized.contains('/')) {
        return context.l10n.depositReceiptUrlNotAllowed;
      }
      return validateTelebirrReceiptCode(value) != null
          ? context.l10n.depositReceiptCodeInvalid
          : null;
    }

    final trimmed = value?.trim().toUpperCase() ?? '';
    if (trimmed.length < 6) {
      return context.l10n.validatorTransactionRef;
    }
    return null;
  }

  List<PaymentProvider> _availableProviders(DepositConfigModel? config) {
    final configuredProviders =
        config?.providers
            .map((provider) => _providerFromApi(provider.key))
            .whereType<PaymentProvider>()
            .toList(growable: false) ??
        const [];

    if (configuredProviders.isNotEmpty) {
      return configuredProviders;
    }

    return const [
      PaymentProvider.cbe,
      PaymentProvider.telebirr,
      PaymentProvider.awash,
      PaymentProvider.boa,
    ];
  }

  PaymentProvider? _providerFromApi(String key) {
    try {
      return PaymentProvider.fromApi(key);
    } on ArgumentError {
      return null;
    }
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppBranding.casinoPurple, AppBranding.casinoPurpleDeep],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.walletAvailableBalance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${formatMoney(amount)} ETB',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppBranding.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
