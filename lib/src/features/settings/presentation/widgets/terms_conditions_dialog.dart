import 'package:flutter/material.dart';

import '../../../../core/config/app_support.dart';
import '../../../../core/theme/app_spacing.dart';

Future<void> showTermsConditionsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.jumbo,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.cardPaddingDense,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppSupport.termsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(dialogContext)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.cardPaddingDense,
                  child: Text(
                    AppSupport.termsBody.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.cardPaddingDense,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
