import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/payment_provider.dart';
import '../../domain/wallet_amount_limits.dart';
import '../utils/smart_deposit_parse_result.dart';
import 'deposit_smart_feedback.dart';

/// Single-message Smart Deposit pane for an already-selected provider.
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
              CollapsedMessagePreview(
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
              ParseFeedback(
                provider: widget.provider,
                result: result,
                onSwitchToRegular: widget.onSwitchToRegular,
              ),
            ],
            if (result?.isSuccess == true) ...[
              VGap.md,
              ParsedConfirmation(
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
