import 'package:flutter/material.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/deposit_config_model.dart';
import '../../data/models/payment_provider.dart';

/// Step 1: choose a payment method.
/// After selection, only the chosen method is shown until the user taps Change.
class DepositProviderChips extends StatelessWidget {
  const DepositProviderChips({
    required this.value,
    required this.availableProviders,
    required this.depositConfig,
    required this.onChanged,
    required this.isChoosing,
    required this.onChangePressed,
    this.comingSoonProviders = const {},
    super.key,
  });

  final PaymentProvider? value;
  final List<PaymentProvider> availableProviders;
  final DepositConfigModel? depositConfig;
  final ValueChanged<PaymentProvider> onChanged;
  final bool isChoosing;
  final VoidCallback onChangePressed;
  final Set<PaymentProvider> comingSoonProviders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = value;

    if (!isChoosing && selected != null) {
      return _SelectedProviderBanner(
        label: _labelFor(selected),
        provider: selected,
        onChange: onChangePressed,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.depositChooseProviderFirst,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.depositChooseProviderHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...availableProviders.map((provider) {
          final comingSoon = comingSoonProviders.contains(provider);
          final isSelected = provider == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ProviderOptionCard(
              provider: provider,
              label: _labelFor(provider),
              selected: isSelected,
              comingSoon: comingSoon,
              onTap: comingSoon ? null : () => onChanged(provider),
            ),
          );
        }),
      ],
    );
  }

  String _labelFor(PaymentProvider provider) {
    return depositConfig?.providerForKey(provider.apiValue)?.name ??
        provider.label;
  }
}

class _SelectedProviderBanner extends StatelessWidget {
  const _SelectedProviderBanner({
    required this.label,
    required this.provider,
    required this.onChange,
  });

  final String label;
  final PaymentProvider provider;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

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
                _iconFor(provider),
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
                    l10n.depositSelectedMethod,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(l10n.depositChangeProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderOptionCard extends StatelessWidget {
  const _ProviderOptionCard({
    required this.provider,
    required this.label,
    required this.selected,
    required this.onTap,
    this.comingSoon = false,
  });

  final PaymentProvider provider;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;

    final card = Material(
      color: selected
          ? AppBranding.casinoPurple
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                _iconFor(provider),
                size: 24,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: selected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (comingSoon) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Coming Soon',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: selected
                              ? Colors.white70
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right_rounded,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );

    if (!enabled) {
      return Opacity(opacity: 0.45, child: card);
    }
    return card;
  }
}

IconData _iconFor(PaymentProvider provider) {
  return switch (provider) {
    PaymentProvider.telebirr => Icons.phone_android_outlined,
    PaymentProvider.cbe => Icons.account_balance_outlined,
    PaymentProvider.awash => Icons.savings_outlined,
    PaymentProvider.boa => Icons.account_balance_wallet_outlined,
  };
}
