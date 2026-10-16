import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/payment_provider.dart';
import '../../domain/wallet_amount_limits.dart';
import '../utils/smart_deposit_parse_result.dart';

/// Single-message Smart Deposit pane for a already-selected provider.
class DepositSmartSection extends StatefulWidget {
  const DepositSmartSection({
    required this.provider,
    required this.messageController,
    required this.amountController,
    required this.parseResult,
    required this.onMessageChanged,
    required this.onAmountChanged,
    required this.onSubmit,
    required this.onSwitchToRegular,
    required this.isSubmitting,
    required this.canSubmit,
    super.key,
  });

  final PaymentProvider provider;
  final TextEditingController messageController;
  final TextEditingController amountController;
  final SmartDepositParseResult? parseResult;
  final ValueChanged<String> onMessageChanged;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onSubmit;
  final VoidCallback onSwitchToRegular;
  final bool isSubmitting;
  final bool canSubmit;

  @override
  State<DepositSmartSection> createState() => _DepositSmartSectionState();
}

class _DepositSmartSectionState extends State<DepositSmartSection> {
  /// When parse succeeds, keep the SMS field collapsed unless the user edits.
  bool _messageExpanded = false;

  @override
  void didUpdateWidget(covariant DepositSmartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSuccess = oldWidget.parseResult?.isSuccess == true;
    final isSuccess = widget.parseResult?.isSuccess == true;
    if (isSuccess && !wasSuccess) {
      _messageExpanded = false;
    } else if (!isSuccess && wasSuccess) {
      _messageExpanded = true;
    }
  }

  void _expandMessage() {
    if (_messageExpanded) return;
    setState(() => _messageExpanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.parseResult;
    final showAmountField =
        result?.isSuccess == true &&
        (result?.amount == null || result!.amount!.isEmpty);
    final collapseMessage =
        result?.isSuccess == true &&
        !_messageExpanded &&
        widget.messageController.text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (collapseMessage)
              _CollapsedMessagePreview(
                label: l10n.depositSmartMessageLabel,
                message: widget.messageController.text.trim(),
                onEdit: _expandMessage,
              )
            else
              TextField(
                controller: widget.messageController,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: l10n.depositSmartMessageLabel,
                  hintText: l10n.depositSmartMessageHint(widget.provider.label),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.content_paste_rounded),
                  ),
                ),
                onChanged: (value) {
                  if (result?.isSuccess == true && !_messageExpanded) {
                    setState(() => _messageExpanded = true);
                  }
                  widget.onMessageChanged(value);
                },
              ),
            if (result != null) ...[
              VGap.md,
              _ParseFeedback(
                provider: widget.provider,
                result: result,
                onSwitchToRegular: widget.onSwitchToRegular,
              ),
            ],
            if (result?.isSuccess == true) ...[
              VGap.md,
              _ParsedConfirmation(
                transactionRef: result!.transactionRef!,
                amount: result.amount,
              ),
              if (showAmountField) ...[
                VGap.md,
                TextField(
                  controller: widget.amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [
                    WalletAmountInputFormatter(
                      maxAmount: WalletAmountLimits.maxDeposit,
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.depositAmount,
                    hintText: WalletAmountLimits.formatLimit(
                      WalletAmountLimits.minDeposit,
                    ),
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  onChanged: widget.onAmountChanged,
                ),
              ],
              VGap.xl,
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppBranding.goldAccent,
                  foregroundColor: AppBranding.brandPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    widget.canSubmit && !widget.isSubmitting
                        ? widget.onSubmit
                        : null,
                child: widget.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.depositSmartConfirmSubmit),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollapsedMessagePreview extends StatelessWidget {
  const _CollapsedMessagePreview({
    required this.label,
    required this.message,
    required this.onEdit,
  });

  final String label;
  final String message;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.65);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outline),
            ),
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            prefixIcon: const Icon(Icons.content_paste_rounded),
            suffixIcon: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ),
          child: Text(
            message.replaceAll(RegExp(r'\s+'), ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _ParsedConfirmation extends StatelessWidget {
  const _ParsedConfirmation({
    required this.transactionRef,
    required this.amount,
  });

  final String transactionRef;
  final String? amount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.depositSmartParsedTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          VGap.sm,
          Text(l10n.depositReference(transactionRef)),
          if (amount != null && amount!.isNotEmpty)
            Text(l10n.depositAmountLabel(amount!)),
        ],
      ),
    );
  }
}

class _ParseFeedback extends StatelessWidget {
  const _ParseFeedback({
    required this.provider,
    required this.result,
    required this.onSwitchToRegular,
  });

  final PaymentProvider provider;
  final SmartDepositParseResult result;
  final VoidCallback onSwitchToRegular;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final (String message, Color color, bool offerRegular) = switch (result
        .status) {
      SmartDepositParseStatus.success => (
        l10n.depositSmartParsedReady,
        theme.colorScheme.primary,
        false,
      ),
      SmartDepositParseStatus.wrongProvider => (
        l10n.depositSmartWrongProvider(provider.label),
        theme.colorScheme.error,
        true,
      ),
      SmartDepositParseStatus.unsupported => (
        provider == PaymentProvider.cbe
            ? l10n.depositSmartCbeUnsupported
            : l10n.depositSmartUnsupported,
        theme.colorScheme.error,
        true,
      ),
      SmartDepositParseStatus.incomplete => (
        l10n.depositSmartIncomplete,
        theme.colorScheme.onSurfaceVariant,
        true,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: color),
        ),
        if (offerRegular) ...[
          VGap.sm,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onSwitchToRegular,
              child: Text(l10n.depositSmartUseRegular),
            ),
          ),
        ],
      ],
    );
  }
}
