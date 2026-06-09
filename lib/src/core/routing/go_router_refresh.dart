import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';

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
  return notifier;
});
