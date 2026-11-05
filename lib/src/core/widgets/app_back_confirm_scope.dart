import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/providers/has_active_registered_cartelas_provider.dart';
import '../../features/wallet/shared/presentation/wallet_flow_back.dart';

enum ConfirmBackChoice { stay, leave }

Future<ConfirmBackChoice?> showConfirmBackDialog(BuildContext context) {
  final l10n = context.l10n;

  return showDialog<ConfirmBackChoice>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.confirmBackTitle),
        content: Text(l10n.confirmBackMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ConfirmBackChoice.stay),
            child: Text(l10n.confirmBackStay),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ConfirmBackChoice.leave),
            child: Text(l10n.confirmBackLeave),
          ),
        ],
      );
    },
  );
}

Future<ConfirmBackChoice?> showLeaveLiveGameDialog(BuildContext context) {
  final l10n = context.l10n;

  return showDialog<ConfirmBackChoice>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.leaveLiveGameTitle),
        content: Text(l10n.leaveLiveGameMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ConfirmBackChoice.stay),
            child: Text(l10n.leaveLiveGameStay),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ConfirmBackChoice.leave),
            child: Text(l10n.leaveLiveGameLeave),
          ),
        ],
      );
    },
  );
}

Future<ConfirmBackChoice?> showExitAppDialog(BuildContext context) {
  final l10n = context.l10n;

  return showDialog<ConfirmBackChoice>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.exitAppTitle),
        content: Text(l10n.exitAppMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ConfirmBackChoice.stay),
            child: Text(l10n.exitAppStay),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ConfirmBackChoice.leave),
            child: Text(l10n.exitAppExit),
          ),
        ],
      );
    },
  );
}

Future<void> handleAppBackPop({
  required BuildContext context,
  required bool didPop,
}) async {
  if (didPop) {
    return;
  }

  final router = GoRouter.maybeOf(context);
  final location = router?.state.matchedLocation ?? '';

  // Priority 1: Deposit/withdraw provider step (same screen, not a route).
  // Must run before Navigator.pop — on these routes canPop is already true.
  if (router != null &&
      tryConsumeWalletProviderStepBack(
        container: ProviderScope.containerOf(context),
        location: location,
      )) {
    return;
  }

  // Priority 2: Close any open modal/sheet / pop nested route
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
    return;
  }

  // Priority 3: Pop nested go_router route
  if (router != null && router.canPop()) {
    router.pop();
    return;
  }

  // Priority 4: Root tab navigation
  if (router == null) {
    await SystemNavigator.pop();
    return;
  }

  if (location == '/games/big-game') {
    router.go('/games');
    return;
  }

  // Live game root (/games) — exit or leave-active-session confirmation.
  if (location == '/games') {
    final container = ProviderScope.containerOf(context);
    final backGuard = container.read(hasActiveRegisteredCartelasProvider);

    final choice = backGuard.shouldConfirmLiveGameBack
        ? await showLeaveLiveGameDialog(context)
        : await showExitAppDialog(context);

    if (!context.mounted || choice != ConfirmBackChoice.leave) {
      return;
    }

    // Exit the app
    await SystemNavigator.pop();
    return;
  }

  // If on other root tab (/wallet, /home, /profile), go to Live (/games)
  final rootTabs = ['/wallet', '/home', '/profile'];
  final isRootTab = rootTabs.any((tab) => location == tab || location.startsWith('$tab/'));

  if (isRootTab) {
    router.go('/games');
    return;
  }

  // Fallback: exit app
  await SystemNavigator.pop();
}

class AppBackConfirmScope extends StatelessWidget {
  const AppBackConfirmScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        unawaited(
          handleAppBackPop(context: context, didPop: didPop),
        );
      },
      child: child,
    );
  }
}

Widget appRouteWithBackConfirm(Widget child) {
  return AppBackConfirmScope(child: child);
}
