import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_support.dart';
import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/sound/sound_preferences.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_avatar_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../../games/domain/big_game_phase.dart';
import '../../../games/presentation/providers/current_big_game_provider.dart';
import '../../../games/presentation/utils/big_game_countdown.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_breakdown_card.dart';
import 'terms_conditions_dialog.dart';
import 'drawer_app_version_card.dart';
import 'drawer_preferences_card.dart';

class AppSettingsDrawer extends ConsumerWidget {
  const AppSettingsDrawer({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final session = ref.watch(authControllerProvider).session;
    final isGuest = session == null;
    final user = session?.user;
    final walletAsync = isGuest ? null : ref.watch(myWalletProvider);
    final notificationPreferencesAsync = ref.watch(
      notificationPreferencesControllerProvider,
    );
    final notificationPreferences = notificationPreferencesAsync.value;
    final notificationNotifier = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );

    void refreshDrawerData() {
      if (!isGuest) {
        ref.invalidate(myWalletProvider);
      }
    }

    return Drawer(
      width: 320,
      backgroundColor: theme.brightness == Brightness.dark
          ? AppBranding.liveSurfaceDark
          : AppBranding.lightScaffold,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  const DrawerPreferencesCard(),
                  VGap.md,
                  _DrawerPromoCarousel(isGuest: isGuest, l10n: l10n),
                  if (isGuest) ...[
                    VGap.md,
                    _DrawerSectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.drawerSignInToPlay,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          VGap.xs,
                          Text(
                            l10n.drawerCreateAccount,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!isGuest && user != null) ...[
                    VGap.md,
                    _DrawerSectionCard(
                      child: _DrawerProfileSummary(
                        user: user,
                        onTap: () => _openProtectedRoute(
                          context,
                          ref,
                          '/profile',
                        ),
                      ),
                    ),
                    VGap.md,
                    walletAsync!.when(
                      data: (wallet) => _DrawerSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DrawerSectionHeader(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppBranding.bingoFreeGreen,
                              title: l10n.drawerBalance,
                              trailing: IconButton(
                                tooltip: 'Refresh',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: refreshDrawerData,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            VGap.sm,
                            WalletBreakdownCard.fromWallet(
                              wallet,
                              style: WalletBreakdownStyle.inline,
                            ),
                            VGap.sm,
                            _DrawerDivider(theme: theme),
                              _DrawerMenuRow(
                                icon: Icons.add_circle_outline,
                                label: l10n.walletDeposit,
                                showChevron: true,
                                onTap: () => _openProtectedRoute(
                                  context,
                                  ref,
                                  '/wallet/deposit',
                                ),
                              ),
                              _DrawerDivider(theme: theme),
                              _DrawerMenuRow(
                                icon: Icons.remove_circle_outline,
                                label: l10n.walletWithdraw,
                                showChevron: true,
                                onTap: () => _openProtectedRoute(
                                  context,
                                  ref,
                                  '/wallet/withdraw',
                                ),
                              ),
                            ],
                          ),
                        ),
                      loading: () => _DrawerSectionCard(
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                  VGap.md,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: _DrawerSectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: _NotificationQuickCard(
                        preferences: notificationPreferences,
                        onTogglePush: (value) {
                          unawaited(
                            notificationNotifier.setPushEnabled(value),
                          );
                        },
                        onOpenSettings: () =>
                            _openNotificationSettings(context),
                      ),
                    ),
                  ),
                  VGap.md,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: _DrawerSectionCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: _SoundQuickCard(
                        onOpenSettings: () => _openSoundSettings(context),
                      ),
                    ),
                  ),
                  VGap.md,
                  _DrawerSectionCard(
                    child: Column(
                      children: [
                        _DrawerSectionHeader(
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppBranding.gold,
                          title: l10n.drawerBigGame,
                        ),
                        if (!isGuest) ...[
                          VGap.sm,
                          _DrawerBigGameStatus(l10n: l10n, theme: theme),
                        ],
                        _DrawerMenuRow(
                          icon: Icons.workspace_premium_outlined,
                          label: l10n.drawerBigGame,
                          showChevron: true,
                          onTap: () => _openProtectedRoute(
                            context,
                            ref,
                            '/games/big-game',
                          ),
                        ),
                      ],
                    ),
                  ),
                  VGap.md,
                  _DrawerSectionCard(
                    child: Column(
                      children: [
                        _DrawerSectionHeader(
                          icon: Icons.history_rounded,
                          iconColor: theme.colorScheme.primary,
                          title: l10n.drawerHistory,
                        ),
                        _DrawerMenuRow(
                          icon: Icons.receipt_long_outlined,
                          label: l10n.drawerTransactionHistory,
                          showChevron: true,
                          onTap: () => _openProtectedRoute(
                            context,
                            ref,
                            '/wallet/transactions',
                          ),
                        ),
                        _DrawerDivider(theme: theme),
                        _DrawerMenuRow(
                          icon: Icons.sports_esports_outlined,
                          label: l10n.drawerGameHistory,
                          showChevron: true,
                          onTap: () => _openProtectedRoute(
                            context,
                            ref,
                            '/games/history',
                          ),
                        ),
                      ],
                    ),
                  ),
                  VGap.md,
                  _DrawerSectionCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: const DrawerAppVersionCard(),
                  ),
                  VGap.md,
                  _DrawerSectionCard(
                    child: Column(
                      children: [
                        _DrawerSectionHeader(
                          icon: Icons.support_agent_outlined,
                          iconColor: theme.colorScheme.primary,
                          title: AppSupport.contactTitle,
                        ),
                        for (var i = 0; i < AppSupport.supportPhoneDisplays.length; i++) ...[
                          if (i > 0) _DrawerDivider(theme: theme),
                          _DrawerMenuRow(
                            icon: Icons.phone_outlined,
                            label: AppSupport.supportPhoneDisplays[i],
                            showChevron: true,
                            onTap: () {
                              unawaited(
                                openExternalUri(
                                  context,
                                  Uri.parse(AppSupport.supportPhoneUris[i]),
                                ),
                              );
                            },
                          ),
                        ],
                        _DrawerDivider(theme: theme),
                        _DrawerMenuRow(
                          icon: Icons.send_outlined,
                          label: '@${AppSupport.telegramUsername}',
                          showChevron: true,
                          onTap: () {
                            unawaited(
                              openExternalUri(
                                context,
                                AppSupport.telegramUri,
                              ),
                            );
                          },
                        ),
                        _DrawerDivider(theme: theme),
                        _DrawerMenuRow(
                          icon: Icons.description_outlined,
                          label: AppSupport.termsTitle,
                          showChevron: true,
                          onTap: () =>
                              unawaited(showTermsConditionsDialog(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: isGuest
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go(loginPathWithRedirect('/games'));
                          },
                          child: Text(l10n.signIn),
                        ),
                        VGap.md,
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/register');
                          },
                          child: Text(l10n.signUp),
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                      ),
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        router.go('/games');
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(l10n.drawerLogout),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: _DrawerDeveloperFooter(theme: theme),
            ),
          ],
        ),
      ),
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

  void _openNotificationSettings(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NotificationSettingsSheet(),
    );
  }

  void _openSoundSettings(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SoundSettingsSheet(),
    );
  }
}

class _DrawerProfileSummary extends ConsumerWidget {
  const _DrawerProfileSummary({
    required this.user,
    required this.onTap,
  });

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarId = ref.watch(profileAvatarProvider(user.id)).asData?.value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              UserProfileAvatar(
                fullName: user.fullName,
                avatarId: avatarId,
                radius: 28,
                showBorder: true,
              ),
              HGap.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    VGap.xxs,
                    Text(
                      user.phoneNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open profile',
                visualDensity: VisualDensity.compact,
                onPressed: onTap,
                icon: Icon(
                  Icons.settings_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerPromoCarousel extends StatefulWidget {
  const _DrawerPromoCarousel({
    required this.isGuest,
    required this.l10n,
  });

  final bool isGuest;
  final AppLocalizations l10n;

  @override
  State<_DrawerPromoCarousel> createState() => _DrawerPromoCarouselState();
}

class _DrawerPromoCarouselState extends State<_DrawerPromoCarousel> {
  static const _height = 88.0;
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_DrawerPromoSlide> _slides(BuildContext context) {
    final l10n = widget.l10n;

    return [
      _DrawerPromoSlide(
        colors: const [AppBranding.casinoPurpleDeep, AppBranding.casinoPurple],
        title: AppBranding.brandName,
        subtitle: l10n.drawerLiveGame,
        icon: Icons.casino_rounded,
      ),
      _DrawerPromoSlide(
        colors: const [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
        title: l10n.dashboardOpenLiveGame,
        subtitle: l10n.dashboardSubtitle,
        icon: Icons.local_play_rounded,
      ),
      _DrawerPromoSlide(
        colors: const [AppBranding.feltGreen, AppBranding.bingoFreeGreen],
        title: l10n.drawerBalance,
        subtitle: widget.isGuest
            ? l10n.drawerCreateAccount
            : l10n.dashboardWalletSnapshot,
        icon: Icons.emoji_events_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slides = _slides(context);

    return Column(
      children: [
        SizedBox(
          height: _height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => slides[index],
          ),
        ),
        VGap.sm,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final active = index == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.35,
                      ),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DrawerPromoSlide extends StatelessWidget {
  const _DrawerPromoSlide({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final List<Color> colors;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppBranding.wordmarkGold(size: 18),
                ),
                VGap.xxs,
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          HGap.sm,
          Icon(
            icon,
            size: 34,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionCard extends StatelessWidget {
  const _DrawerSectionCard({
    required this.child,
    this.padding = AppSpacing.cardPaddingDense,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppBranding.panelBackground(context),
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: AppBranding.panelBorder(context)),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: AppBranding.brandPurple.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({
    required this.icon,
    required this.title,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingWidgets = trailing == null
        ? const <Widget>[]
        : <Widget>[trailing!];

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor ?? theme.colorScheme.primary,
        ),
        HGap.sm,
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...trailingWidgets,
      ],
    );
  }
}

class _DrawerInfoRow extends StatelessWidget {
  const _DrawerInfoRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        HGap.sm,
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }
}

class _DrawerBigGameStatus extends ConsumerWidget {
  const _DrawerBigGameStatus({
    required this.l10n,
    required this.theme,
  });

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bigGameAsync = ref.watch(currentBigGameProvider);
    final clock = ref.watch(serverClockProvider);

    return bigGameAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (game) {
        if (game == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.bigGameNoScheduledBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final now = clock.isSynced ? clock.nowLocal() : DateTime.now();
        final phase = resolveBigGamePhase(game, now: now);
        final prize = game.fixedPrizeAmount ?? game.prizeAmount;

        final statusLabel = switch (phase) {
          BigGamePhase.beforeRegistrationOpens => l10n.bigGameScheduledTitle,
          BigGamePhase.registrationOpen => l10n.bigGameRegistrationOpenTitle,
          BigGamePhase.waitingToPlay => l10n.bigGameReadyTitle,
          BigGamePhase.live => l10n.announcementBigGameLive,
          _ => l10n.drawerBigGame,
        };

        final countdownTarget = switch (phase) {
          BigGamePhase.beforeRegistrationOpens => game.registrationOpensAt,
          BigGamePhase.registrationOpen => game.scheduledStartAt,
          _ => null,
        };
        final countdownLabel = switch (phase) {
          BigGamePhase.beforeRegistrationOpens =>
            l10n.bigGameRegistrationOpensIn,
          BigGamePhase.registrationOpen => l10n.bigGamePlayStartsIn,
          _ => null,
        };
        final countdown = countdownTarget != null
            ? formatBigGameCountdown(countdownTarget, clock: clock)
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppBranding.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppBranding.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppBranding.goldDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.announcementBigGamePrize(formatMoney(prize)),
                  style: theme.textTheme.bodySmall,
                ),
                if (countdown != null && countdownLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$countdownLabel $countdown',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerMenuRow extends StatelessWidget {
  const _DrawerMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              HGap.md,
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationQuickCard extends StatelessWidget {
  const _NotificationQuickCard({
    required this.preferences,
    required this.onTogglePush,
    required this.onOpenSettings,
  });

  final NotificationPreferencesState? preferences;
  final ValueChanged<bool> onTogglePush;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = preferences ?? const NotificationPreferencesState();
    final isEnabled = prefs.pushEnabled;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(
            isEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          HGap.sm,
          Expanded(
            child: Text(
              'Notifications',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: isEnabled,
              onChanged: onTogglePush,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            tooltip: 'Manage categories',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onOpenSettings,
            icon: Icon(
              Icons.tune_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSheet extends ConsumerWidget {
  const _NotificationSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preferencesAsync = ref.watch(
      notificationPreferencesControllerProvider,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.jumbo,
        ),
        child: preferencesAsync.when(
          data: (preferences) {
            final notifier = ref.read(
              notificationPreferencesControllerProvider.notifier,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'These settings are saved on this device only for now.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                VGap.xl,
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Push notifications'),
                  value: preferences.pushEnabled,
                  onChanged: (value) {
                    unawaited(notifier.setPushEnabled(value));
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GAME_STARTED'),
                  value: preferences.gameStartedEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(notifier.setGameStartedEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GAME_FINISHED'),
                  value: preferences.gameFinishedEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(notifier.setGameFinishedEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('WINNER_ANNOUNCEMENT'),
                  value: preferences.winnerAnnouncementsEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(
                            notifier.setWinnerAnnouncementsEnabled(value),
                          );
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DEPOSIT_APPROVED'),
                  value: preferences.depositApprovedEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(notifier.setDepositApprovedEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('WITHDRAWAL_APPROVED'),
                  value: preferences.withdrawalApprovedEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(
                            notifier.setWithdrawalApprovedEnabled(value),
                          );
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('WITHDRAWAL_REJECTED'),
                  value: preferences.withdrawalRejectedEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(
                            notifier.setWithdrawalRejectedEnabled(value),
                          );
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('SYSTEM'),
                  value: preferences.systemEnabled,
                  onChanged: preferences.pushEnabled
                      ? (value) {
                          unawaited(notifier.setSystemEnabled(value));
                        }
                      : null,
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Could not load notification settings.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoundQuickCard extends ConsumerWidget {
  const _SoundQuickCard({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final preferences =
        ref.watch(soundPreferencesControllerProvider).value ??
        const SoundPreferencesState();
    final notifier = ref.read(soundPreferencesControllerProvider.notifier);
    final isEnabled = preferences.soundsEnabled;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(
            isEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          HGap.sm,
          Expanded(
            child: Text(
              l10n.drawerSounds,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: isEnabled,
              onChanged: (value) {
                unawaited(notifier.setSoundsEnabled(value));
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            tooltip: 'Manage sounds',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onOpenSettings,
            icon: Icon(
              Icons.tune_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundSettingsSheet extends ConsumerWidget {
  const _SoundSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final preferencesAsync = ref.watch(soundPreferencesControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.jumbo,
        ),
        child: preferencesAsync.when(
          data: (preferences) {
            final notifier = ref.read(
              soundPreferencesControllerProvider.notifier,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.drawerSounds,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  l10n.soundSettingsDeviceOnly,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                VGap.xl,
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.soundMaster),
                  value: preferences.soundsEnabled,
                  onChanged: (value) {
                    unawaited(notifier.setSoundsEnabled(value));
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.soundCalledNumber),
                  value: preferences.calledNumberEnabled,
                  onChanged: preferences.soundsEnabled
                      ? (value) {
                          unawaited(notifier.setCalledNumberEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.soundGameStart),
                  value: preferences.gameStartEnabled,
                  onChanged: preferences.soundsEnabled
                      ? (value) {
                          unawaited(notifier.setGameStartEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.soundWinnerWindow),
                  value: preferences.winnerWindowEnabled,
                  onChanged: preferences.soundsEnabled
                      ? (value) {
                          unawaited(notifier.setWinnerWindowEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.soundValidBingo),
                  value: preferences.validBingoEnabled,
                  onChanged: preferences.soundsEnabled
                      ? (value) {
                          unawaited(notifier.setValidBingoEnabled(value));
                        }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.soundVibrate),
                  value: preferences.vibrateEnabled,
                  onChanged: preferences.soundsEnabled
                      ? (value) {
                          unawaited(notifier.setVibrateEnabled(value));
                        }
                      : null,
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Could not load sound settings.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerDeveloperFooter extends StatelessWidget {
  const _DrawerDeveloperFooter({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        onTap: () {
          unawaited(
            openExternalUri(context, AppSupport.developerTelegramUri),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.sm,
          ),
          child: Text(
            '© ${AppSupport.developerName}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
