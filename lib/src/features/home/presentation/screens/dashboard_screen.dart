import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_breakdown_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(authControllerProvider).session;
    final user = session?.user;
    final walletAsync = ref.watch(myWalletProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Card(
          child: Padding(
            padding: AppSpacing.cardPaddingDense,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardHello(user?.fullName ?? 'Player'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VGap.md,
                Text(l10n.dashboardSubtitle, style: theme.textTheme.bodyLarge),
                VGap.xl,
                FilledButton(
                  onPressed: () => context.go('/games'),
                  child: Text(l10n.dashboardOpenLiveGame),
                ),
              ],
            ),
          ),
        ),
        VGap.xl,
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: l10n.dashboardRole,
                value: user?.role.label ?? 'Player',
                icon: Icons.verified_user_outlined,
              ),
            ),
            HGap.xl,
            Expanded(
              child: _SummaryCard(
                title: l10n.dashboardStatus,
                value: user?.status.label ?? 'Active',
                icon: Icons.shield_outlined,
              ),
            ),
          ],
        ),
        VGap.xl,
        Card(
          child: Padding(
            padding: AppSpacing.cardPaddingDense,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardWalletSnapshot,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VGap.md,
                walletAsync.when(
                  data: (wallet) => WalletBreakdownCard.fromWallet(
                    wallet,
                    style: WalletBreakdownStyle.inline,
                  ),
                  loading: () => Text(l10n.dashboardWalletLoading),
                  error: (_, _) => Text(l10n.dashboardWalletUnavailable),
                ),
                VGap.xl,
                FilledButton.tonal(
                  onPressed: () => context.go('/wallet'),
                  child: Text(l10n.dashboardOpenWallet),
                ),
              ],
            ),
          ),
        ),
        VGap.xl,
        Card(
          child: Padding(
            padding: AppSpacing.cardPaddingDense,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardWhatIsNext,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VGap.md,
                Text(l10n.dashboardWhatIsNextBody),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            VGap.xl,
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            VGap.xs,
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
