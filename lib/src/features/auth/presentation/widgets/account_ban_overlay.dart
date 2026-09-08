import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_support.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/account_ban_provider.dart';

/// Blocks the app when the account is banned until the player acknowledges.
class AccountBanOverlay extends ConsumerWidget {
  const AccountBanOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ban = ref.watch(accountBanProvider);

    if (ban == null) {
      return child;
    }

    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: child),
          _AccountBanScreen(reason: ban.reason),
        ],
      ),
    );
  }
}

class _AccountBanScreen extends ConsumerWidget {
  const _AccountBanScreen({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.error;

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
                  color: isDark
                      ? AppBranding.liveCardDark
                      : AppBranding.lightSurfaceRaised,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: AppBranding.brandPurple.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 48,
                      color: accent,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      l10n.accountBannedTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (reason != null && reason!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        reason!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.55,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      l10n.accountBannedPleaseContact,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (var i = 0;
                        i < AppSupport.supportPhoneDisplays.length;
                        i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            unawaited(
                              openExternalUri(
                                context,
                                Uri.parse(AppSupport.supportPhoneUris[i]),
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone_outlined),
                          label: Text(AppSupport.supportPhoneDisplays[i]),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          unawaited(
                            openExternalUri(context, AppSupport.telegramUri),
                          );
                        },
                        icon: const Icon(Icons.telegram),
                        label: Text('@${AppSupport.telegramUsername}'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          ref.read(accountBanProvider.notifier).clear();
                        },
                        child: Text(l10n.accountBannedAcknowledge),
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
