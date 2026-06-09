import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/friends_bingo_wordmark.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/theme_mode_provider.dart';

class AppSettingsDrawer extends ConsumerWidget {
  const AppSettingsDrawer({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final isGuest = session == null;
    final user = session?.user;
    final walletAsync = isGuest ? null : ref.watch(myWalletProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppBranding.casinoPurpleDeep,
                          AppBranding.liveCardDark,
                        ]
                      : [
                          AppBranding.casinoPurple.withValues(alpha: 0.12),
                          theme.colorScheme.surface,
                        ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FriendsBingoWordmark(compact: true),
                  if (isGuest) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to play and register cartelas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ] else if (user != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      user.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.phoneNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: isGuest
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppBranding.panelBackground(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppBranding.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join the game',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create an account to register cartelas and manage your wallet.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    )
                  : walletAsync!.when(
                      data: (wallet) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppBranding.panelBackground(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppBranding.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(wallet.balance),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppBranding.balanceAccent(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(minHeight: 2),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _DrawerNavTile(
                    icon: Icons.casino_outlined,
                    label: 'Live Game',
                    selected: navigationShell.currentIndex == 0,
                    onTap: () => _navigate(context, 0),
                  ),
                  _DrawerNavTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    selected: navigationShell.currentIndex == 2,
                    onTap: () => _openProtected(
                      context,
                      ref,
                      branchIndex: 2,
                      redirectPath: '/wallet',
                    ),
                  ),
                  _DrawerNavTile(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    selected: navigationShell.currentIndex == 3,
                    onTap: () => _openProtected(
                      context,
                      ref,
                      branchIndex: 3,
                      redirectPath: '/profile',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'History',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _DrawerNavTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transaction history',
                    onTap: () => _openProtectedRoute(
                      context,
                      ref,
                      '/wallet/transactions',
                    ),
                  ),
                  _DrawerNavTile(
                    icon: Icons.history_rounded,
                    label: 'Game history',
                    onTap: () => _openRoute(context, '/games/history'),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppBranding.panelBackground(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.dark_mode_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Theme',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text('Dark'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text('Auto'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (selection) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(selection.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isGuest
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go(loginPathWithRedirect('/games'));
                          },
                          child: const Text('Sign in'),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/register');
                          },
                          child: const Text('Sign up'),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        await ref.read(authControllerProvider.notifier).logout();
                        router.go('/games');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int branchIndex) {
    Navigator.of(context).pop();
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  void _openProtected(
    BuildContext context,
    WidgetRef ref, {
    required int branchIndex,
    required String redirectPath,
  }) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    requireAuthNavigate(
      ref,
      router,
      redirectPath: redirectPath,
      onAuthenticated: () {
        navigationShell.goBranch(
          branchIndex,
          initialLocation: branchIndex == navigationShell.currentIndex,
        );
      },
    );
  }

  void _openProtectedRoute(
    BuildContext context,
    WidgetRef ref,
    String location,
  ) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    requireAuthNavigate(
      ref,
      router,
      redirectPath: location,
      onAuthenticated: () {
        router.go(location);
      },
    );
  }

  void _openRoute(BuildContext context, String location) {
    Navigator.of(context).pop();
    context.push(location);
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppBranding.gold : theme.colorScheme.primary,
      ),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: label.contains('history')
          ? Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      selected: selected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}
