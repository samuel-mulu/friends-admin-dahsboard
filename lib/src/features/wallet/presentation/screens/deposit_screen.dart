import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../../../core/realtime/wallet_entity_realtime.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/deposit_config_model.dart';
import '../../data/models/payment_provider.dart';
import '../../data/models/telebirr_client_receipt_payload.dart';
import '../../data/models/telebirr_receipt_preview.dart';
import '../../data/telebirr_receipt_preview_service.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet_amount_limits.dart';
import '../providers/deposit_config_provider.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';
import '../debug/telebirr_deposit_debug.dart';
import '../models/deposit_confirmation_state.dart';
import '../utils/cbe_manual_receipt_reference.dart';
import '../utils/deposit_receipt_code.dart';
import '../widgets/deposit_confirmation_banner.dart';
import '../widgets/deposit_form_section.dart';
import '../widgets/deposit_guide_steps.dart';
import '../widgets/deposit_provider_chips.dart';
import '../widgets/deposit_settlement_account_card.dart';
import '../guides/deposit_guide_config.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  static const _approvedDismissDelay = Duration(seconds: 8);
  static const _comingSoonProviders = {
    PaymentProvider.awash,
    PaymentProvider.boa,
  };

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _depositGuideKey = GlobalKey();
  final _guideTabIndex = ValueNotifier<int>(0);
  final _amountController = TextEditingController();
  final _transactionRefController = TextEditingController();

  PaymentProvider? _provider;
  bool _isChoosingProvider = true;
  bool _isSubmitting = false;
  DepositConfirmationState? _confirmation;
  String? _trackedDepositId;
  Timer? _autoDismissTimer;
  late final SocketService _socketService;
  String? _amountServerError;
  String? _transactionRefServerError;
  String? _previewNotice;
  bool _ignoreFieldChanges = false;
  String? _lastSeenLocation;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _bindDepositSocketListeners();
  }

  void _bindDepositSocketListeners() {
    _socketService.off('wallet:updated', _onWalletUpdatedWhilePending);
    _socketService.on('wallet:updated', _onWalletUpdatedWhilePending);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(_router, router)) {
      _router?.routerDelegate.removeListener(_onRouteChanged);
      _router = router;
      _router!.routerDelegate.addListener(_onRouteChanged);
      _lastSeenLocation ??= router.state.matchedLocation;
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _socketService.off('wallet:updated', _onWalletUpdatedWhilePending);
    _autoDismissTimer?.cancel();
    _scrollController.dispose();
    _guideTabIndex.dispose();
    _amountController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  void _scrollToDepositGuide({int tabIndex = 1}) {
    _guideTabIndex.value = tabIndex;
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
    if (_provider == null || _isChoosingProvider) {
      return false;
    }
    if (_isSubmitting) {
      return false;
    }
    if (!WalletAmountLimits.isSubmittableDeposit(_amountController.text)) {
      return false;
    }
    return true;
  }

  static const _depositRoute = '/wallet/deposit';

  bool _isDepositLocation(String location) {
    return location == _depositRoute || location.startsWith('$_depositRoute?');
  }

  void _onRouteChanged() {
    final location = _router?.state.matchedLocation;
    if (location == null) {
      return;
    }

    final previous = _lastSeenLocation;
    final onDeposit = _isDepositLocation(location);
    final wasOffDeposit = previous != null && !_isDepositLocation(previous);

    _lastSeenLocation = location;

    if (!wasOffDeposit || !onDeposit || !mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _resetDepositUi();
    });
  }

  void _resetDepositUi() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _trackedDepositId = null;
    _ignoreFieldChanges = true;
    _amountController.clear();
    _transactionRefController.clear();
    _formKey.currentState?.reset();
    _ignoreFieldChanges = false;
    setState(() {
      _clearServerErrors();
      _confirmation = null;
      _previewNotice = null;
      _isSubmitting = false;
      _provider = null;
      _isChoosingProvider = true;
    });
  }

  void _selectProvider(PaymentProvider provider) {
    if (_provider == provider && !_isChoosingProvider) {
      return;
    }
    _ignoreFieldChanges = true;
    _amountController.clear();
    _transactionRefController.clear();
    _formKey.currentState?.reset();
    _ignoreFieldChanges = false;
    setState(() {
      _provider = provider;
      _isChoosingProvider = false;
      _guideTabIndex.value = 0;
      _clearServerErrors();
      _previewNotice = null;
      _clearConfirmation();
    });
  }

  void _changeProvider() {
    _ignoreFieldChanges = true;
    _amountController.clear();
    _transactionRefController.clear();
    _formKey.currentState?.reset();
    _ignoreFieldChanges = false;
    setState(() {
      _isChoosingProvider = true;
      _guideTabIndex.value = 0;
      _clearServerErrors();
      _previewNotice = null;
      _clearConfirmation();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletEntityRealtimeState>(walletEntityRealtimeProvider, (
      previous,
      next,
    ) {
      final update = next.lastUpdate;
      if (update == null || update.kind != WalletEntityKind.deposit) {
        return;
      }
      _handleDepositEntityUpdate(update);
    });

    final l10n = context.l10n;
    final depositConfig = ref.watch(depositConfigProvider);
    final config = depositConfig.asData?.value;
    final availableProviders = _availableProviders(config);
    final activeProviders = availableProviders
        .where((p) => !_comingSoonProviders.contains(p))
        .toList(growable: false);
    final selectedProvider = (_provider != null &&
            activeProviders.contains(_provider))
        ? _provider!
        : null;
    final showDepositDetails =
        !_isChoosingProvider && selectedProvider != null;
    final receiptLabel = selectedProvider == null
        ? ''
        : _receiptLabel(config, selectedProvider);
    final providerConfig = selectedProvider == null
        ? null
        : config?.providerForKey(selectedProvider.apiValue);
    final settlementAccounts = selectedProvider == null
        ? const <_SettlementAccountDisplay>[]
        : _settlementAccounts(
            selectedProvider: selectedProvider,
            config: config,
            providerConfig: providerConfig,
          );
    final helpText = selectedProvider == null
        ? null
        : _localizedDepositInstruction(l10n, selectedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.depositScreenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DepositProviderChips(
                  value: selectedProvider ?? _provider,
                  availableProviders: availableProviders,
                  depositConfig: config,
                  comingSoonProviders: _comingSoonProviders,
                  isChoosing: _isChoosingProvider || selectedProvider == null,
                  onChangePressed: _changeProvider,
                  onChanged: _selectProvider,
                ),
                if (showDepositDetails) ...[
                  VGap.lg,
                  if (settlementAccounts.isNotEmpty)
                    DepositSettlementAccountCard(
                      providerName: selectedProvider.label,
                      helpText: helpText,
                      accounts: [
                        for (
                          var index = 0;
                          index < settlementAccounts.length;
                          index++
                        )
                          DepositSettlementAccountItem(
                            settlementAccount:
                                settlementAccounts[index].settlementAccount,
                            receiverName:
                                settlementAccounts[index].receiverName,
                            accountLabel: _settlementAccountLabel(
                              l10n,
                              index: index,
                              total: settlementAccounts.length,
                            ),
                          ),
                      ],
                      onShowInstructions: () => _scrollToDepositGuide(tabIndex: 1),
                    ),
                  VGap.xl,
                  _DepositStepHeader(
                    step: 2,
                    title: l10n.depositStepSubmitDetails,
                  ),
                  VGap.sm,
                  Text(
                    helpText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  VGap.md,
                  DepositFormSection(
                    provider: selectedProvider,
                    amountController: _amountController,
                    transactionRefController: _transactionRefController,
                    receiptLabel: receiptLabel,
                    amountValidator: _validateAmount,
                    transactionRefValidator: (value) => _validateTransactionRef(
                      value,
                      providerConfig: providerConfig,
                    ),
                    onFieldChanged: _onFormFieldChanged,
                    amountServerError: _amountServerError,
                    transactionRefServerError: _transactionRefServerError,
                    previewNotice: _previewNotice,
                    preserveTransactionRefCase:
                        selectedProvider == PaymentProvider.cbe &&
                        providerConfig?.approvalMode == 'manual',
                  ),
                  VGap.xl,
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppBranding.goldAccent,
                      foregroundColor: AppBranding.brandPurple,
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
                            padding: const EdgeInsets.only(top: AppSpacing.xl),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              child: DepositConfirmationBanner(
                                key: ValueKey(_confirmation!.switchKey),
                                state: _confirmation!,
                                onDismiss: _clearConfirmation,
                                onRetry: _confirmation!.canRetry
                                    ? _prepareRetryAfterReject
                                    : null,
                              ),
                            ),
                          ),
                  ),
                  VGap.xxl,
                  const Divider(),
                  VGap.xl,
                  _DepositStepHeader(
                    step: 3,
                    title: l10n.depositStepInstructions,
                  ),
                  VGap.md,
                  KeyedSubtree(
                    key: _depositGuideKey,
                    child: DepositGuideSteps(
                      provider: selectedProvider,
                      youtubeUrl: resolveDepositGuideYoutubeUrl(
                        provider: selectedProvider,
                        remoteUrl: providerConfig?.guideVideoUrl,
                      ),
                      requestedTabIndex: _guideTabIndex,
                    ),
                  ),
                ],
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
      if (_amountServerError != null || _transactionRefServerError != null) {
        _clearServerErrors();
      }
    });
    // Keep pending / under-review cards while waiting for admin.
    if (_confirmation?.kind == DepositConfirmationKind.pending ||
        _confirmation?.kind == DepositConfirmationKind.underReview) {
      return;
    }
    _clearConfirmation();
  }

  void _prepareRetryAfterReject() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _trackedDepositId = null;
    setState(() {
      _confirmation = null;
      _clearServerErrors();
      _previewNotice = null;
    });
  }

  void _handleDepositEntityUpdate(WalletEntityUpdate update) {
    if (!mounted || !update.isTerminal) {
      return;
    }

    final matchesTrackedId =
        _trackedDepositId != null && update.id == _trackedDepositId;
    final matchesPendingRef =
        _confirmation?.kind == DepositConfirmationKind.pending &&
        update.transactionRef != null &&
        update.transactionRef!.isNotEmpty &&
        _confirmation?.transactionRef == update.transactionRef;
    final matchesConfirmationId =
        _confirmation?.depositId != null &&
        _confirmation!.depositId == update.id &&
        (_confirmation?.kind == DepositConfirmationKind.pending ||
            _confirmation?.kind == DepositConfirmationKind.underReview);

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
      provider = _provider;
    }

    if (update.isApproved) {
      _applyDepositTerminalStatus(
        kind: DepositConfirmationKind.approved,
        depositId: update.id,
        provider: provider ?? _provider,
        amount: update.amount,
        transactionRef: update.transactionRef,
      );
      return;
    }

    if (update.isRejected) {
      _applyDepositTerminalStatus(
        kind: DepositConfirmationKind.rejected,
        depositId: update.id,
        provider: provider ?? _provider,
        amount: update.amount,
        transactionRef: update.transactionRef,
        message: update.message?.trim().isNotEmpty == true
            ? update.message
            : null,
        canRetry: true,
      );
    }
  }

  void _consumeCachedDepositUpdate() {
    final update = ref.read(walletEntityRealtimeProvider).find(
      kind: WalletEntityKind.deposit,
      id: _trackedDepositId,
      transactionRef: _confirmation?.transactionRef,
    );
    if (update != null) {
      _handleDepositEntityUpdate(update);
    }
  }

  void _onWalletUpdatedWhilePending(dynamic _) {
    if (!mounted ||
        _confirmation?.kind != DepositConfirmationKind.pending ||
        _trackedDepositId == null) {
      return;
    }
    unawaited(_refreshTrackedDepositFromServer());
  }

  Future<void> _refreshTrackedDepositFromServer() async {
    final depositId = _trackedDepositId;
    if (!mounted ||
        depositId == null ||
        _confirmation?.kind != DepositConfirmationKind.pending) {
      return;
    }

    try {
      final page = await ref
          .read(walletRepositoryProvider)
          .getMyDeposits(page: 1, pageSize: 20);
      DepositModel? match;
      for (final item in page.items) {
        if (item.id == depositId) {
          match = item;
          break;
        }
      }
      if (!mounted || match == null) {
        return;
      }

      if (match.status == DepositStatus.approved) {
        _applyDepositTerminalStatus(
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
        _applyDepositTerminalStatus(
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
    } catch (_) {
      // Keep pending card; socket event may still arrive.
    }
  }

  void _applyDepositTerminalStatus({
    required DepositConfirmationKind kind,
    required String depositId,
    PaymentProvider? provider,
    String? amount,
    String? transactionRef,
    String? message,
    bool canRetry = false,
  }) {
    if (!mounted) {
      return;
    }

    void apply() {
      if (!mounted) {
        return;
      }
      setState(() {
        _trackedDepositId = kind == DepositConfirmationKind.approved
            ? depositId
            : null;
        _confirmation = DepositConfirmationState(
          kind: kind,
          depositId: depositId,
          provider: provider,
          amount: amount ?? _confirmation?.amount,
          transactionRef: transactionRef ?? _confirmation?.transactionRef,
          message: message,
          canRetry: canRetry,
          verifiedAt: kind == DepositConfirmationKind.approved
              ? DateTime.now()
              : null,
        );
      });
      if (kind == DepositConfirmationKind.approved) {
        _scheduleApprovedDismiss();
      }
    }

    // Socket callbacks can arrive mid-frame; apply on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => apply());
  }

  void _clearDepositFormFields() {
    _ignoreFieldChanges = true;
    _amountController.clear();
    _transactionRefController.clear();
    _formKey.currentState?.reset();
    _ignoreFieldChanges = false;
  }

  void _clearConfirmation() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _trackedDepositId = null;
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
    final provider = _provider;
    if (provider == null || _isChoosingProvider) {
      return;
    }
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
      String? cbeManualReceiptUrl;
      late final String transactionRef;

      if (provider == PaymentProvider.telebirr) {
        transactionRef = normalizeDepositReceiptCode(rawTransactionInput);
        TelebirrDepositDebug.log(
          'submit start ref=${TelebirrDepositDebug.maskRef(transactionRef)} amountSet=${submittedAmount.isNotEmpty}',
        );

        final depositConfig = await ref.read(depositConfigProvider.future);
        final approvalMode = depositConfig
            .providerForKey(PaymentProvider.telebirr.apiValue)
            ?.approvalMode;
        final isLocalMode = approvalMode == 'local';

        // Receipt URL fetch + parse is local-mode only.
        // Automatic → verify.et on backend. Manual → pending for admin.
        // Wallet credit always happens on the backend in all modes.
        if (isLocalMode) {
          final preview = await ref
              .read(telebirrReceiptPreviewServiceProvider)
              .preview(
                transactionRef: transactionRef,
                submittedAmount: submittedAmount,
                config: depositConfig.telebirr,
              );

          receiptParseStatus = preview.receiptParseStatus;
          clientReceipt = preview.toClientReceiptPayload();

          if (preview.status != TelebirrReceiptPreviewStatus.valid ||
              clientReceipt == null) {
            if (!mounted) {
              return;
            }

            _rejectFailedPreview(
              preview: preview,
              submittedAmount: submittedAmount,
              transactionRef: transactionRef,
            );
            return;
          }

          TelebirrDepositDebug.log(
            'local receipt parsed settled=${preview.settledAmount} '
            'account=${preview.creditedPartyAccountNo}',
          );
        }
      } else if (provider == PaymentProvider.cbe) {
        final depositConfig = await ref.read(depositConfigProvider.future);
        final cbeConfig = depositConfig.providerForKey(
          PaymentProvider.cbe.apiValue,
        );
        if (cbeConfig?.approvalMode == 'manual') {
          final normalized = normalizeCbeManualReceiptReference(
            rawTransactionInput,
            receiptBaseUrl: cbeConfig!.receiptBaseUrl.isEmpty
                ? kDefaultCbeReceiptBaseUrl
                : cbeConfig.receiptBaseUrl,
          );
          if (normalized == null) {
            if (mounted) {
              setState(() {
                _transactionRefServerError =
                    'Enter a valid CBE receipt ID or official receipt URL.';
              });
            }
            return;
          }
          transactionRef = normalized;
          if (isReceiptUrlInput(rawTransactionInput)) {
            cbeManualReceiptUrl = rawTransactionInput;
          }
        } else {
          // Automatic CBE behavior stays unchanged.
          transactionRef = rawTransactionInput.toUpperCase();
        }
      } else {
        transactionRef = rawTransactionInput.toUpperCase();
      }

      final checkResult = await walletRepository.checkDepositReference(
        provider: provider,
        transactionRef: transactionRef,
      );

      if (!checkResult.isAvailable) {
        if (!mounted) {
          return;
        }

        final message =
            _mapDepositCodeToMessage(checkResult.code) ?? checkResult.message;
        final isUnderReview = checkResult.code == 'UNDER_REVIEW';
        final isAlreadyUsed = checkResult.code == 'ALREADY_USED';
        setState(() {
          _transactionRefServerError = message;
          _confirmation = DepositConfirmationState(
            kind: isUnderReview
                ? DepositConfirmationKind.underReview
                : DepositConfirmationKind.rejected,
            message: message,
            provider: provider,
            amount: submittedAmount,
            transactionRef: transactionRef,
            canRetry: !isUnderReview && !isAlreadyUsed,
          );
        });
        return;
      }

      final deposit = await walletRepository.createDeposit(
        provider: provider,
        amount: submittedAmount,
        // The backend canonicalizes a CBE manual URL and stores the original
        // URL separately for admin review.
        transactionRef: cbeManualReceiptUrl ?? transactionRef,
        receiptParseStatus: receiptParseStatus,
        clientReceipt: clientReceipt,
      );

      ref.invalidate(depositHistoryProvider);

      if (deposit.status == DepositStatus.approved) {
        ref.invalidate(myWalletProvider);
        ref.invalidate(walletTransactionsProvider);
      }

      if (!mounted) {
        return;
      }

      if (deposit.status == DepositStatus.pending) {
        setState(() {
          _trackedDepositId = deposit.id;
          _confirmation = DepositConfirmationState(
            kind: DepositConfirmationKind.pending,
            depositId: deposit.id,
            provider: deposit.provider,
            amount: deposit.amount,
            transactionRef: deposit.transactionRef,
          );
        });
        _clearDepositFormFields();
        _consumeCachedDepositUpdate();
        return;
      }

      setState(() {
        _trackedDepositId = deposit.id;
        _confirmation = DepositConfirmationState(
          kind: DepositConfirmationKind.approved,
          depositId: deposit.id,
          provider: deposit.provider,
          amount: deposit.amount,
          transactionRef: deposit.transactionRef,
          verifiedAt: deposit.verifiedAt ?? deposit.createdAt,
        );
      });
      _clearDepositFormFields();
      _scheduleApprovedDismiss();
    } catch (error) {
      if (provider == PaymentProvider.telebirr) {
        TelebirrDepositDebug.error('submit failed', error);
      }
      if (!mounted) {
        return;
      }

      final message = error is ApiException
          ? _handleDepositError(error)
          : context.l10n.depositCouldNotSubmit;
      final code = error is ApiException ? error.code : null;
      final canRetry = code != 'ALREADY_USED' && code != 'UNDER_REVIEW';

      setState(() {
        _trackedDepositId = null;
        _confirmation = DepositConfirmationState(
          kind: code == 'UNDER_REVIEW'
              ? DepositConfirmationKind.underReview
              : DepositConfirmationKind.rejected,
          message: message,
          provider: provider,
          amount: _amountController.text.trim(),
          transactionRef: _transactionRefController.text.trim().toUpperCase(),
          canRetry: canRetry,
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

  String _localizedDepositInstruction(
    AppLocalizations l10n,
    PaymentProvider provider,
  ) {
    return switch (provider) {
      PaymentProvider.cbe => l10n.depositInstructionCbe,
      PaymentProvider.telebirr => l10n.depositInstructionTelebirr,
      PaymentProvider.awash => l10n.depositInstructionAwash,
      PaymentProvider.boa => l10n.depositInstructionBoa,
    };
  }

  String _receiptLabel(DepositConfigModel? config, PaymentProvider provider) {
    return config?.providerForKey(provider.apiValue)?.receiptCodeLabel ??
        provider.transactionRefLabel;
  }

  /// Local-mode only: phone already knows the receipt is bad, so do not call
  /// create. Wallet credit stays on the backend after a valid local submit.
  void _rejectFailedPreview({
    required TelebirrReceiptPreview preview,
    required String submittedAmount,
    required String transactionRef,
  }) {
    final message = _mapPreviewError(preview);
    final isAmountProblem =
        preview.status == TelebirrReceiptPreviewStatus.amountMismatch;

    setState(() {
      _previewNotice = null;
      if (isAmountProblem) {
        _amountServerError = message;
      } else {
        _transactionRefServerError = message;
      }
      _confirmation = DepositConfirmationState(
        kind: DepositConfirmationKind.rejected,
        message: message,
        provider: _provider,
        amount: submittedAmount,
        transactionRef: transactionRef,
        canRetry: true,
      );
    });

    TelebirrDepositDebug.log(
      'local submit blocked on client status=${preview.status.name}',
    );
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
        return context.l10n.depositCouldNotSubmit;
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
        case 'UNDER_REVIEW':
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
      case 'UNDER_REVIEW':
        return l10n.depositRefUnderReview;
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

  String? _validateTransactionRef(
    String? value, {
    DepositProviderConfig? providerConfig,
  }) {
    if (_provider == PaymentProvider.telebirr) {
      final normalized = normalizeDepositReceiptCode(value ?? '');
      if (normalized.contains('/')) {
        return context.l10n.depositReceiptUrlNotAllowed;
      }
      return validateTelebirrReceiptCode(value) != null
          ? context.l10n.depositReceiptCodeInvalid
          : null;
    }

    if (_provider == PaymentProvider.cbe &&
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
      return context.l10n.validatorTransactionRef;
    }
    return null;
  }

  List<PaymentProvider> _availableProviders(DepositConfigModel? config) {
    final configuredProviders =
        config?.providers
            .where((provider) => provider.enabled)
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

  List<_SettlementAccountDisplay> _settlementAccounts({
    required PaymentProvider selectedProvider,
    required DepositConfigModel? config,
    required DepositProviderConfig? providerConfig,
  }) {
    if (selectedProvider == PaymentProvider.telebirr && config != null) {
      return config.telebirr
          .resolvedAccounts(
            fallbackSettlementAccount: providerConfig?.settlementAccount ?? '',
          )
          .map(
            (account) => _SettlementAccountDisplay(
              settlementAccount: account.settlementAccount,
              receiverName: account.receiverName,
            ),
          )
          .toList(growable: false);
    }

    if (providerConfig != null &&
        providerConfig.settlementAccount.trim().isNotEmpty) {
      return [
        _SettlementAccountDisplay(
          settlementAccount: providerConfig.settlementAccount,
          receiverName: providerConfig.receiverName,
        ),
      ];
    }

    return const [];
  }

  String? _settlementAccountLabel(
    AppLocalizations l10n, {
    required int index,
    required int total,
  }) {
    if (total <= 1) {
      return null;
    }

    if (index == 0) {
      return l10n.depositTelebirrAccount1;
    }
    if (index == 1) {
      return l10n.depositTelebirrAccount2;
    }

    return null;
  }
}

class _DepositStepHeader extends StatelessWidget {
  const _DepositStepHeader({
    required this.step,
    required this.title,
  });

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppBranding.casinoPurple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$step',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettlementAccountDisplay {
  const _SettlementAccountDisplay({
    required this.settlementAccount,
    required this.receiverName,
  });

  final String settlementAccount;
  final String receiverName;
}
