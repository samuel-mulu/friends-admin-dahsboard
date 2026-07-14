import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_branding.dart';
import '../theme/app_spacing.dart';
import '../utils/l10n.dart';
import 'android_device_security.dart';
import 'device_security_controller.dart';

/// Blocks release Android builds when Developer options are enabled.
class DeviceSecurityGate extends ConsumerWidget {
  const DeviceSecurityGate({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deviceSecurityControllerProvider);

    if (!shouldRunAndroidDeviceSecurityCheck || !state.isBlocked) {
      return child ?? const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(child: child ?? const SizedBox.shrink()),
          const ModalBarrier(dismissible: false, color: Colors.black54),
          Material(
            color: isDark ? AppBranding.liveSurfaceDark : AppBranding.lightScaffold,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.jumbo),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.jumbo,
                        AppSpacing.xxxl,
                        AppSpacing.jumbo,
                        AppSpacing.jumbo,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppBranding.liveCardDark
                            : AppBranding.lightSurfaceRaised,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppBranding.brandPurple.withValues(
                            alpha: isDark ? 0.45 : 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          VGap.lg,
                          Text(
                            l10n.developerModeBlockedTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          VGap.md,
                          Text(
                            l10n.developerModeBlockedMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                          VGap.xl,
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                unawaited(
                                  ref
                                      .read(androidDeviceSecurityProvider)
                                      .openDeveloperSettings(),
                                );
                              },
                              child: Text(l10n.developerModeOpenSettings),
                            ),
                          ),
                          VGap.sm,
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                unawaited(SystemNavigator.pop());
                              },
                              child: Text(l10n.developerModeCloseApp),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
