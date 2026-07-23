import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../controllers/auth_controller.dart';

class AuthStatusMessageListener extends ConsumerWidget {
  const AuthStatusMessageListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authControllerProvider.notifier);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final nextAward = next.pendingWelcomeBonusCartelasAwarded;
      if (nextAward > 0 &&
          nextAward != previous?.pendingWelcomeBonusCartelasAwarded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.welcomeBonusBody(nextAward))),
          );
          authNotifier.clearPendingWelcomeBonusCartelasAwarded();
        });
        return;
      }

      final nextDeniedReason = next.pendingWelcomeBonusDeniedReason;
      if (nextDeniedReason == null ||
          nextDeniedReason == previous?.pendingWelcomeBonusDeniedReason) {
        return;
      }

      final message = switch (nextDeniedReason) {
        'USER_ALREADY_CLAIMED' =>
          context.l10n.welcomeBonusDeniedUserAlreadyClaimed,
        _ => context.l10n.welcomeBonusDeniedDeviceAlreadyClaimed,
      };

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        authNotifier.clearPendingWelcomeBonusDeniedReason();
      });
    });

    return child;
  }
}
