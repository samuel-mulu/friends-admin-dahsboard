import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';

const kAuthLocations = {
  '/login',
  '/register',
  '/forgot-password',
};

const kGuestLocations = {
  '/games',
  '/games/history',
};

const kProtectedLocations = {
  '/home',
  '/wallet',
  '/wallet/deposit',
  '/wallet/deposits',
  '/wallet/withdraw',
  '/wallet/withdrawals',
  '/wallet/transactions',
  '/profile',
  '/games/big-game',
  '/support/contact',
  '/support/my-feedback',
};

bool isAuthenticated(Ref ref) {
  return ref.read(authControllerProvider).session != null;
}

bool isProtectedLocation(String location) {
  return kProtectedLocations.contains(location);
}

bool isGuestAllowedLocation(String location) {
  return kGuestLocations.contains(location) || kAuthLocations.contains(location);
}

String loginPathWithRedirect(String redirectPath) {
  return '/login?redirect=${Uri.encodeComponent(redirectPath)}';
}

void requireAuthNavigate(
  WidgetRef ref,
  GoRouter router, {
  required String redirectPath,
  VoidCallback? onAuthenticated,
}) {
  if (ref.read(authControllerProvider).session != null) {
    onAuthenticated?.call();
    return;
  }

  Future.microtask(() {
    router.go(loginPathWithRedirect(redirectPath));
  });
}

String? firstNameFromFullName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed.split(RegExp(r'\s+')).first;
}
