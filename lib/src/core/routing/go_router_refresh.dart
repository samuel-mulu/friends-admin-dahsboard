import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/security/app_lock_controller.dart';
import '../version/version_check_controller.dart';

/// Notifies [GoRouter] when auth changes without recreating the router.
class GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final goRouterRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier();
  ref.listen(authControllerProvider, (_, _) {
    // Defer so auth state can settle before route teardown (avoids unmounted ref crashes).
    Future.microtask(notifier.notify);
  });
  ref.listen(appLockControllerProvider, (_, _) {
    Future.microtask(notifier.notify);
  });
  ref.listen(versionCheckReadyProvider, (_, _) {
    Future.microtask(notifier.notify);
  });
  ref.listen(versionCheckControllerProvider, (_, _) {
    Future.microtask(notifier.notify);
  });
  return notifier;
});
