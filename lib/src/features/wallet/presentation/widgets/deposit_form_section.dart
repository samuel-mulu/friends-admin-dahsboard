import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/uppercase_text_formatter.dart';
import '../../data/models/payment_provider.dart';
import '../../domain/wallet_amount_limits.dart';

class DepositFormSection extends StatelessWidget {
  const DepositFormSection({
    required this.provider,
    required this.amountController,
    required this.transactionRefController,
    required this.receiptLabel,
    required this.amountValidator,
    required this.transactionRefValidator,
    required this.onFieldChanged,
    this.amountServerError,
    this.transactionRefServerError,
    this.previewNotice,
    this.onScanReceipt,
    this.isScanLoading = false,
    this.scanTooltip,
    super.key,
  });

  final PaymentProvider provider;
  final TextEditingController amountController;
  final TextEditingController transactionRefController;
  final String receiptLabel;
  final String? Function(String?) amountValidator;
  final String? Function(String?) transactionRefValidator;
  final VoidCallback onFieldChanged;
  final String? amountServerError;
  final String? transactionRefServerError;
  final String? previewNotice;
  final VoidCallback? onScanReceipt;
  final bool isScanLoading;
  final String? scanTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final minLabel = WalletAmountLimits.formatLimit(
      WalletAmountLimits.minDeposit,
    );
    final maxLabel = WalletAmountLimits.formatLimit(
      WalletAmountLimits.maxDeposit,
    );

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: amountController,
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
                hintText: minLabel,
                helperText: l10n.depositAmountRangeHelper(minLabel, maxLabel),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: amountValidator,
              onChanged: (_) => onFieldChanged(),
              forceErrorText: amountServerError,
            ),
            VGap.xl,
            TextFormField(
              controller: transactionRefController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UpperCaseTextFormatter()],
              decoration: InputDecoration(
                labelText: receiptLabel,
                hintText: provider == PaymentProvider.telebirr
                    ? PaymentProvider.telebirr.transactionRefHint
                    : provider.transactionRefHint,
                prefixIcon: const Icon(Icons.tag_outlined),
                suffixIcon: onScanReceipt == null
                    ? null
                    : isScanLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: scanTooltip,
                        onPressed: onScanReceipt,
                        icon: const Icon(Icons.document_scanner_outlined),
                      ),
              ),
              validator: transactionRefValidator,
              onChanged: (_) => onFieldChanged(),
              forceErrorText: transactionRefServerError,
            ),
            if (provider == PaymentProvider.telebirr && onScanReceipt != null) ...[
              VGap.md,
              _ReceiptScreenshotHelper(
                onScreenshotTap: onScanReceipt!,
                enabled: !isScanLoading,
              ),
            ],
            if (previewNotice != null) ...[
              VGap.xl,
              Text(
                previewNotice!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptScreenshotHelper extends StatelessWidget {
  const _ReceiptScreenshotHelper({
    required this.onScreenshotTap,
    required this.enabled,
  });

  final VoidCallback onScreenshotTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(text: l10n.depositReceiptScreenshotHelperPrefix),
          TextSpan(
            text: l10n.depositReceiptScreenshotHelperLink,
            style: linkStyle,
            recognizer: enabled
                ? (TapGestureRecognizer()..onTap = onScreenshotTap)
                : null,
          ),
          TextSpan(text: l10n.depositReceiptScreenshotHelperSuffix),
        ],
      ),
    );
  }
}
