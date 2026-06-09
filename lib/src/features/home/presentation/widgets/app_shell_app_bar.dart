import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/widgets/friends_bingo_wordmark.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../settings/presentation/widgets/language_placeholder_sheet.dart';

class AppShellAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppShellAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final theme = Theme.of(context);
    final isGuest = session == null;
    final firstName = session == null
        ? null
        : firstNameFromFullName(session.user.fullName);

    return AppBar(
      centerTitle: false,
      title: isGuest || firstName == null
          ? const FriendsBingoWordmark(compact: true)
          : Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hi, ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: firstName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        IconButton(
          tooltip: 'Language',
          onPressed: () => showLanguagePlaceholderSheet(context),
          icon: const Icon(Icons.language_rounded),
        ),
        if (isGuest)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: () => context.go('/register'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Sign up'),
            ),
          ),
      ],
    );
  }
}
