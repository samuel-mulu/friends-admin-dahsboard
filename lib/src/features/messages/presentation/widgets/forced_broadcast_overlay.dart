import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/admin_broadcast_model.dart';
import '../providers/broadcasts_provider.dart';
import 'broadcast_message_ui.dart';

/// Blocks the entire app until admin removes a forced broadcast.
class ForcedBroadcastOverlay extends ConsumerWidget {
  const ForcedBroadcastOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forcedBroadcast = ref.watch(forcedBroadcastProvider);

    if (forcedBroadcast == null) {
      return child;
    }

    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: child),
          _ForcedBroadcastScreen(broadcast: forcedBroadcast),
        ],
      ),
    );
  }
}

class _ForcedBroadcastScreen extends StatelessWidget {
  const _ForcedBroadcastScreen({required this.broadcast});

  final AdminBroadcastModel broadcast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final accent = BroadcastMessageUi.accentFor(
      AdminBroadcastCategory.forced,
      theme.colorScheme,
    );

    return Material(
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
                  color: BroadcastMessageUi.cardBackground(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: AppBranding.brandPurple.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BroadcastMessageUi.leadingIcon(
                      context: context,
                      category: AdminBroadcastCategory.forced,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      broadcast.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      broadcast.body,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.14 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.adminMessagesForcedHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
