import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/app_back_confirm_scope.dart';
import '../../../../core/widgets/friends_bingo_wordmark.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/domain/live_connection_status.dart';
import '../../../games/presentation/providers/has_active_registered_cartelas_provider.dart';
import '../../../games/presentation/providers/realtime_connection_provider.dart';
import '../../../games/presentation/widgets/live_status_chip.dart';
import '../../../support/presentation/widgets/support_feedback_modals.dart';
import '../../../messages/presentation/providers/broadcasts_provider.dart';
import '../../../messages/presentation/widgets/admin_messages_modal.dart';

class AppShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppShellAppBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(authControllerProvider).session;
    final theme = Theme.of(context);
    final isGuest = session == null;
    final firstName = session == null
        ? null
        : firstNameFromFullName(session.user.fullName);

    final router = GoRouter.of(context);
    final location = router.state.uri.path;
    final canPop = router.canPop();

    // Live games root always shows the drawer menu — stable across locale rebuilds.
    final isGamesBranch = navigationShell.currentIndex == 0;
    final isGamesRoot = location == '/games';
    final isBigGameRoute = location == '/games/big-game';
    final showMenuButton = isGamesBranch && isGamesRoot;
    final isNonLiveRootTab = location == '/wallet' ||
        location == '/home' ||
        location == '/profile' ||
        location.startsWith('/wallet/') ||
        location.startsWith('/home/') ||
        location.startsWith('/profile/');

    final showBackButton =
        !showMenuButton &&
        (canPop || isNonLiveRootTab || isBigGameRoute);

    final headerForeground = AppBranding.appShellHeaderForeground(context);
    final headerForegroundMuted =
        AppBranding.appShellHeaderForegroundMuted(context);

    return AppBar(
      centerTitle: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      foregroundColor: headerForeground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: Container(
        decoration: AppBranding.appShellHeaderDecoration(context),
      ),
      leading: showMenuButton
          ? _DrawerMenuButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            )
          : showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () async {
                    await _handleShellBack(
                      context: context,
                      ref: ref,
                      router: router,
                      location: location,
                    );
                  },
                )
              : null,
      title: isGuest || firstName == null
          ? const FriendsBingoWordmark(compact: true)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l10n.appBarHi,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: headerForegroundMuted,
                    ),
                  ),
                  TextSpan(
                    text: firstName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: headerForeground,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ConnectionStatusDot(
            status: switch (ref.watch(realtimeConnectionProvider)) {
              LiveConnectionStatus.live => LiveConnectionState.online,
              LiveConnectionStatus.reconnecting =>
                LiveConnectionState.reconnecting,
              LiveConnectionStatus.offline => LiveConnectionState.offline,
            },
            theme: theme,
          ),
        ),
        if (!isGuest && !ref.watch(hasActiveForcedBroadcastProvider))
          _BroadcastMessageButton(headerForeground: headerForeground),
        IconButton(
          tooltip: l10n.drawerSendFeedback,
          onPressed: () => showFeedbackHubModal(context, ref),
          icon: Icon(Icons.comment_outlined, color: headerForeground),
        ),
        if (isGuest) ...[
          TextButton(
            onPressed: () => context.go(loginPathWithRedirect('/games')),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              foregroundColor: headerForeground,
            ),
            child: Text(l10n.signIn),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: () => context.go('/register'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.brightness == Brightness.dark
                    ? AppBranding.gold.withValues(alpha: 0.18)
                    : AppBranding.goldAccent.withValues(alpha: 0.28),
                foregroundColor: headerForeground,
              ),
              child: Text(l10n.signUp),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> _handleShellBack({
  required BuildContext context,
  required WidgetRef ref,
  required GoRouter router,
  required String location,
}) async {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
    return;
  }

  if (router.canPop()) {
    router.pop();
    return;
  }

  if (location == '/games/big-game') {
    router.go('/games');
    return;
  }

  if (location == '/games') {
    final backGuard = ref.read(hasActiveRegisteredCartelasProvider);

    final choice = backGuard.shouldConfirmLiveGameBack
        ? await showLeaveLiveGameDialog(context)
        : await showExitAppDialog(context);

    if (!context.mounted || choice != ConfirmBackChoice.leave) {
      return;
    }

    await SystemNavigator.pop();
    return;
  }

  final rootTabs = ['/wallet', '/home', '/profile'];
  final isRootTab = rootTabs.any(
    (tab) => location == tab || location.startsWith('$tab/'),
  );

  if (isRootTab) {
    router.go('/games');
  }
}

/// Drawer button for the live tab root — always shows the menu icon.
class _DrawerMenuButton extends StatelessWidget {
  const _DrawerMenuButton({required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.menu_rounded),
      onPressed: () {
        final scaffold = Scaffold.of(context);
        if (scaffold.isDrawerOpen) {
          scaffold.closeDrawer();
        } else {
          scaffold.openDrawer();
        }
      },
    );
  }
}

class _BroadcastMessageButton extends ConsumerStatefulWidget {
  const _BroadcastMessageButton({required this.headerForeground});

  final Color headerForeground;

  @override
  ConsumerState<_BroadcastMessageButton> createState() =>
      _BroadcastMessageButtonState();
}

class _BroadcastMessageButtonState extends ConsumerState<_BroadcastMessageButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = ref.watch(broadcastBellBadgeProvider);

    if (badge.shouldBlink && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!badge.shouldBlink && _blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.value = 1;
    }

    final icon = Icon(
      Icons.notifications_rounded,
      color: widget.headerForeground,
    );

    return IconButton(
      tooltip: context.l10n.adminMessagesTitle,
      onPressed: () => showAdminMessagesModal(context, ref),
      icon: badge.shouldBlink
          ? FadeTransition(
              opacity: Tween<double>(begin: 0.55, end: 1).animate(
                CurvedAnimation(
                  parent: _blinkController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: _BroadcastBellBadge(
                badge: badge,
                child: icon,
              ),
            )
          : _BroadcastBellBadge(
              badge: badge,
              child: icon,
            ),
    );
  }
}

class _BroadcastBellBadge extends StatelessWidget {
  const _BroadcastBellBadge({
    required this.badge,
    required this.child,
  });

  final BroadcastBellBadgeState badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!badge.showBadge) {
      return child;
    }

    final label = badge.displayCount > 99 ? '99+' : '${badge.displayCount}';
    final background = badge.isPinnedOnly
        ? AppBranding.gold
        : const Color(0xFFE53935);
    final foreground = badge.isPinnedOnly
        ? AppBranding.brandPurple
        : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
