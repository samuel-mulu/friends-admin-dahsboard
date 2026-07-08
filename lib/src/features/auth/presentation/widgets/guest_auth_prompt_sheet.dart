import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/utils/l10n.dart';

Future<void> showGuestAuthPromptSheet(
  BuildContext context, {
  String? title,
  String? message,
  String redirectPath = '/games',
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final l10n = sheetContext.l10n;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title ?? l10n.guestPromptTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message ?? l10n.guestPromptMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  sheetContext.go('/register');
                },
                child: Text(l10n.signUp),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  sheetContext.go(loginPathWithRedirect(redirectPath));
                },
                child: Text(l10n.signIn),
              ),
            ],
          ),
        ),
      );
    },
  );
}
