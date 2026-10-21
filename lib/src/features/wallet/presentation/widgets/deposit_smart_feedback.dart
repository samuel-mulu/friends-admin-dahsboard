import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/payment_provider.dart';
import '../utils/smart_deposit_parse_result.dart';

class CollapsedMessagePreview extends StatelessWidget {
  const CollapsedMessagePreview({
    required this.label,
    required this.message,
    required this.onEdit,
    super.key,
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

class ParsedConfirmation extends StatelessWidget {
  const ParsedConfirmation({
    required this.transactionRef,
    required this.amount,
    super.key,
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
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
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

class ParseFeedback extends StatelessWidget {
  const ParseFeedback({
    required this.provider,
    required this.result,
    required this.onSwitchToRegular,
    super.key,
  });

  final PaymentProvider provider;
  final SmartDepositParseResult result;
  final VoidCallback onSwitchToRegular;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final (String message, Color color, bool offerRegular) =
        switch (result.status) {
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
