import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../controllers/deposit_controller.dart';
import '../models/deposit_confirmation_state.dart';
import 'deposit_confirmation_banner.dart';

class DepositStatusCard extends ConsumerWidget {
  const DepositStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(depositControllerProvider);
    final confirmation = state.confirmation;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: confirmation == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: DepositConfirmationBanner(
                  key: ValueKey(confirmation.switchKey),
                  state: confirmation,
                  onDismiss: ref
                      .read(depositControllerProvider.notifier)
                      .clearConfirmation,
                  onRetry: confirmation.canRetry
                      ? ref
                          .read(depositControllerProvider.notifier)
                          .clearConfirmation
                      : null,
                  onCheckAgain: confirmation.kind ==
                          DepositConfirmationKind.verificationInProgress
                      ? () => ref
                          .read(depositControllerProvider.notifier)
                          .restorePendingVerificationAttempt()
                      : null,
                ),
              ),
            ),
    );
  }
}
