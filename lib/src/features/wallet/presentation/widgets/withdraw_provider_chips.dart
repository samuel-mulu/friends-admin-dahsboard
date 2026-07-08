import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/payment_provider.dart';

class WithdrawProviderChips extends StatelessWidget {
  const WithdrawProviderChips({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PaymentProvider value;
  final ValueChanged<PaymentProvider> onChanged;

  static const availableProviders = [
    PaymentProvider.telebirr,
    PaymentProvider.cbe,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.withdrawSelectProvider,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: availableProviders
              .map(
                (provider) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: provider == PaymentProvider.telebirr ? 8 : 0,
                    ),
                    child: _ProviderChip(
                      provider: provider,
                      label: provider.label,
                      selected: provider == value,
                      onTap: () => onChanged(provider),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.provider,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PaymentProvider provider;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? AppBranding.casinoPurple
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider == PaymentProvider.telebirr
                    ? Icons.phone_android_outlined
                    : Icons.account_balance_outlined,
                size: 18,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
