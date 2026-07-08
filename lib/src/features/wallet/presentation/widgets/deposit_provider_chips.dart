import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/deposit_config_model.dart';
import '../../data/models/payment_provider.dart';

class DepositProviderChips extends StatelessWidget {
  const DepositProviderChips({
    required this.value,
    required this.availableProviders,
    required this.depositConfig,
    required this.onChanged,
    this.comingSoonProviders = const {},
    super.key,
  });

  final PaymentProvider value;
  final List<PaymentProvider> availableProviders;
  final DepositConfigModel? depositConfig;
  final ValueChanged<PaymentProvider> onChanged;
  final Set<PaymentProvider> comingSoonProviders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.depositSelectProvider,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableProviders
                .map(
                  (provider) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ProviderChip(
                      provider: provider,
                      label: _labelFor(provider),
                      selected: provider == value,
                      comingSoon: comingSoonProviders.contains(provider),
                      onTap: () => onChanged(provider),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  String _labelFor(PaymentProvider provider) {
    return depositConfig?.providerForKey(provider.apiValue)?.name ??
        provider.label;
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.provider,
    required this.label,
    required this.selected,
    required this.onTap,
    this.comingSoon = false,
  });

  final PaymentProvider provider;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chip = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(provider),
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (comingSoon) ...
                [
                  const SizedBox(height: 2),
                  Text(
                    'Coming Soon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );

    if (!comingSoon) {
      return Material(
        color: selected
            ? AppBranding.casinoPurple
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconFor(provider),
                  size: 18,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:
                        selected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Opacity(opacity: 0.45, child: chip);
  }

  IconData _iconFor(PaymentProvider provider) {
    return switch (provider) {
      PaymentProvider.telebirr => Icons.phone_android_outlined,
      PaymentProvider.cbe => Icons.account_balance_outlined,
      PaymentProvider.awash => Icons.savings_outlined,
      PaymentProvider.boa => Icons.account_balance_wallet_outlined,
    };
  }
}
