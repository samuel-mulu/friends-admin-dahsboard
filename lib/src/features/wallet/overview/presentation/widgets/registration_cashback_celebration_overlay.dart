import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_branding.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/l10n.dart';
import '../../application/providers/registration_cashback_celebration_provider.dart';

class RegistrationCashbackCelebrationHost extends ConsumerWidget {
  const RegistrationCashbackCelebrationHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final celebration = ref.watch(registrationCashbackCelebrationProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (celebration.isVisible)
          _RegistrationCashbackCelebrationBanner(
            key: ValueKey(celebration.eventId),
            amount: celebration.amount!,
            cartelaCount: celebration.sessionQualifyingCount!,
            onDismiss: () {
              ref
                  .read(registrationCashbackCelebrationProvider.notifier)
                  .dismiss();
            },
          ),
      ],
    );
  }
}

class _RegistrationCashbackCelebrationBanner extends StatefulWidget {
  const _RegistrationCashbackCelebrationBanner({
    required this.amount,
    required this.cartelaCount,
    required this.onDismiss,
    super.key,
  });

  final String amount;
  final int cartelaCount;
  final VoidCallback onDismiss;

  @override
  State<_RegistrationCashbackCelebrationBanner> createState() =>
      _RegistrationCashbackCelebrationBannerState();
}

class _RegistrationCashbackCelebrationBannerState
    extends State<_RegistrationCashbackCelebrationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final amountLabel = formatMoney(widget.amount);

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  margin: const EdgeInsets.all(AppSpacing.xl),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration_outlined,
                          size: 48,
                          color: AppBranding.gold,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.registrationCashbackCelebrationTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.registrationCashbackCelebrationBody(
                            amountLabel,
                            widget.cartelaCount,
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: widget.onDismiss,
                          child: Text(l10n.registrationCashbackCelebrationClose),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
