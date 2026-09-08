import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/payment_provider.dart';

/// Step 1: choose payout method. After selection, only the chosen method stays visible.
class WithdrawProviderChips extends StatelessWidget {
  const WithdrawProviderChips({
    required this.value,
    required this.onChanged,
    required this.isChoosing,
    required this.onChangePressed,
    super.key,
  });

  final PaymentProvider? value;
  final ValueChanged<PaymentProvider> onChanged;
  final bool isChoosing;
  final VoidCallback onChangePressed;

  static const availableProviders = [
    PaymentProvider.telebirr,
    PaymentProvider.cbe,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = value;

    if (!isChoosing && selected != null) {
      return Material(
        color: AppBranding.casinoPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppBranding.casinoPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected == PaymentProvider.telebirr
                      ? Icons.phone_android_outlined
                      : Icons.account_balance_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.withdrawSelectedMethod,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChangePressed,
                child: Text(l10n.withdrawChangeProvider),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.withdrawChooseProviderFirst,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.withdrawChooseProviderHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...availableProviders.map((provider) {
          final isSelected = provider == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: isSelected
                  ? AppBranding.casinoPurple
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onChanged(provider),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider == PaymentProvider.telebirr
                            ? Icons.phone_android_outlined
                            : Icons.account_balance_outlined,
                        size: 24,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          provider.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.chevron_right_rounded,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
