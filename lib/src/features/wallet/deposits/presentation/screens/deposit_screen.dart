import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/realtime/wallet_entity_realtime.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../shared/domain/entities/payment_provider.dart';
import '../../application/controllers/deposit_controller.dart';
import '../../application/models/deposit_confirmation_state.dart';
import '../../application/models/deposit_state.dart';
import '../../application/providers/deposit_config_provider.dart';
import '../../data/models/deposit_config_model.dart';
import '../guides/deposit_guide_config.dart';
import '../widgets/deposit_guide_steps.dart';
import '../widgets/deposit_manual_section.dart';
import '../widgets/deposit_provider_chips.dart';
import '../widgets/deposit_settlement_account_card.dart';
import '../widgets/deposit_smart_section.dart';
import '../widgets/deposit_status_card.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _smartMessageController = TextEditingController();
  final _smartAmountController = TextEditingController();
  final _guideKey = GlobalKey();
  final _guideTabIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(depositControllerProvider.notifier)
          .restorePendingVerificationAttempt();
    });
  }

  @override
  void dispose() {
    _smartMessageController.dispose();
    _smartAmountController.dispose();
    _guideTabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletEntityRealtimeState>(walletEntityRealtimeProvider, (
      previous,
      next,
    ) {
      final update = next.lastUpdate;
      if (update == null || update.kind != WalletEntityKind.deposit) return;
      ref.read(depositControllerProvider.notifier).handleRealtimeUpdate(update);
    });

    ref.listen<DepositState>(depositControllerProvider, (previous, next) {
      final wasApproved =
          previous?.confirmation?.kind == DepositConfirmationKind.approved;
      final isApproved =
          next.confirmation?.kind == DepositConfirmationKind.approved;
      if (isApproved && !wasApproved) {
        _smartMessageController.clear();
        _smartAmountController.clear();
      }
    });

    final l10n = context.l10n;
    final state = ref.watch(depositControllerProvider);
    final controller = ref.read(depositControllerProvider.notifier);
    final depositConfig = ref.watch(depositConfigProvider).asData?.value;
    final availableProviders = _availableProviders(depositConfig);
    final selectedProvider = state.provider;
    final showDetails = !state.isChoosingProvider && selectedProvider != null;
    final providerConfig = selectedProvider == null
        ? null
        : depositConfig?.providerForKey(selectedProvider.apiValue);
    final settlementAccounts = selectedProvider == null
        ? const <DepositSettlementAccountItem>[]
        : _resolveSettlementAccounts(
            selectedProvider,
            depositConfig,
            providerConfig,
          );

    final theme = Theme.of(context);

    return PopScope(
      canPop: !showDetails,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !showDetails) return;
        controller.changeProvider();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.depositScreenTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                VGap.md,
                DepositProviderChips(
                  value: selectedProvider,
                  availableProviders: availableProviders,
                  depositConfig: depositConfig,
                  comingSoonProviders: const {},
                  isChoosing:
                      state.isChoosingProvider || selectedProvider == null,
                  onChangePressed: controller.changeProvider,
                  onChanged: controller.selectProvider,
                ),
                if (showDetails) ...[
                  VGap.lg,
                  if (settlementAccounts.isNotEmpty)
                    DepositSettlementAccountCard(
                      providerName: selectedProvider.label,
                      accounts: settlementAccounts,
                    ),
                  VGap.lg,
                  if (selectedProvider.supportsSmartDepositEntry) ...[
                    _buildTabSelector(context, state, controller, l10n),
                    VGap.md,
                  ],
                  if (selectedProvider.supportsSmartDepositEntry &&
                      state.entryTab == DepositEntryTab.smart)
                    DepositSmartSection(
                      provider: selectedProvider,
                      messageController: _smartMessageController,
                      amountController: _smartAmountController,
                      parseResult: state.smartParseResult,
                      onMessageChanged: (v) => controller.parseSmartInput(v),
                      onAmountChanged: (v) => setState(() {}),
                      onSubmit: () {
                        final parsed = state.smartParseResult;
                        if (parsed == null || !parsed.isSuccess) return;
                        final amount =
                            (parsed.amount != null && parsed.amount!.isNotEmpty)
                            ? parsed.amount!
                            : _smartAmountController.text.trim();
                        controller.submitDeposit(
                          amount: amount,
                          rawTransactionInput: parsed.transactionRef!,
                        );
                      },
                      onSwitchToRegular: () =>
                          controller.switchTab(DepositEntryTab.regular),
                      isSubmitting: state.isSubmitting,
                      canSubmit: state.smartParseResult?.isSuccess == true,
                    )
                  else
                    const DepositManualSection(),
                  const DepositStatusCard(),
                  VGap.xxl,
                  const Divider(),
                  VGap.xl,
                  Text(
                    l10n.depositStepInstructions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  VGap.md,
                  KeyedSubtree(
                    key: _guideKey,
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

  Widget _buildTabSelector(
    BuildContext context,
    DepositState state,
    DepositController controller,
    dynamic l10n,
  ) {
    return SegmentedButton<DepositEntryTab>(
      segments: [
        ButtonSegment<DepositEntryTab>(
          value: DepositEntryTab.smart,
          label: Text(l10n.depositTabSmart as String),
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        ButtonSegment<DepositEntryTab>(
          value: DepositEntryTab.regular,
          label: Text(l10n.depositTabRegular as String),
          icon: const Icon(Icons.edit_note_outlined),
        ),
      ],
      selected: {state.entryTab},
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) controller.switchTab(selected.first);
      },
    );
  }

  List<PaymentProvider> _availableProviders(DepositConfigModel? config) {
    final configured = config?.providers
        .where((p) => p.enabled)
        .map((p) => _tryParseProvider(p.key))
        .whereType<PaymentProvider>()
        .toList(growable: false);
    if (configured != null && configured.isNotEmpty) return configured;
    return const [
      PaymentProvider.cbe,
      PaymentProvider.telebirr,
      PaymentProvider.awash,
      PaymentProvider.boa,
    ];
  }

  PaymentProvider? _tryParseProvider(String key) {
    try {
      return PaymentProvider.fromApi(key);
    } catch (_) {
      return null;
    }
  }

  List<DepositSettlementAccountItem> _resolveSettlementAccounts(
    PaymentProvider provider,
    DepositConfigModel? config,
    DepositProviderConfig? providerConfig,
  ) {
    if (provider == PaymentProvider.telebirr && config != null) {
      return config.telebirr
          .resolvedAccounts(
            fallbackSettlementAccount: providerConfig?.settlementAccount ?? '',
          )
          .map(
            (a) => DepositSettlementAccountItem(
              settlementAccount: a.settlementAccount,
              receiverName: a.receiverName,
            ),
          )
          .toList(growable: false);
    }
    if (providerConfig != null &&
        providerConfig.settlementAccount.trim().isNotEmpty) {
      return [
        DepositSettlementAccountItem(
          settlementAccount: providerConfig.settlementAccount,
          receiverName: providerConfig.receiverName,
        ),
      ];
    }
    return const [];
  }
}
