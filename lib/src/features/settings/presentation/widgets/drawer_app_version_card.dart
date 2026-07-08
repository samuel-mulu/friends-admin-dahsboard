import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/version/app_update_dialog.dart';
import '../../../../core/version/app_version_info.dart';
import '../../../../core/version/version_check_controller.dart';
import '../../../../core/version/version_check_state.dart';

class DrawerAppVersionCard extends ConsumerStatefulWidget {
  const DrawerAppVersionCard({super.key});

  @override
  ConsumerState<DrawerAppVersionCard> createState() =>
      _DrawerAppVersionCardState();
}

class _DrawerAppVersionCardState extends ConsumerState<DrawerAppVersionCard> {
  bool _isChecking = false;

  bool get _supportsUpdateCheck =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final installedAsync = ref.watch(installedAppVersionProvider);
    final checkState = ref.watch(versionCheckControllerProvider);

    final statusLabel = _statusLabel(l10n, checkState);
    final statusColor = _statusColor(theme, checkState);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        onTap: _isChecking ? null : () => unawaited(_handleTap()),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: _isChecking
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: statusColor,
                        ),
                      )
                    : Icon(
                        Icons.system_update_alt_rounded,
                        color: statusColor,
                        size: 22,
                      ),
              ),
              HGap.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.drawerAppVersion,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    VGap.xxs,
                    installedAsync.when(
                      data: (installed) => Text(
                        '${installed.label} · $statusLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      loading: () => Text(
                        l10n.drawerAppVersionChecking,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      error: (_, _) => Text(
                        statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (checkState.kind == VersionCheckKind.optional ||
                  checkState.kind == VersionCheckKind.force)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    checkState.kind == VersionCheckKind.force ? '!' : '1',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, VersionCheckState state) {
    if (_isChecking) {
      return l10n.drawerAppVersionChecking;
    }

    return switch (state.kind) {
      VersionCheckKind.optional => l10n.drawerAppVersionUpdateAvailable,
      VersionCheckKind.force => l10n.drawerAppVersionUpdateRequired,
      VersionCheckKind.error => l10n.updateCheckFailedTitle,
      VersionCheckKind.none => l10n.drawerAppVersionUpToDate,
    };
  }

  Color _statusColor(ThemeData theme, VersionCheckState state) {
    return switch (state.kind) {
      VersionCheckKind.optional => AppBranding.bingoFreeGreen,
      VersionCheckKind.force => theme.colorScheme.error,
      VersionCheckKind.error => theme.colorScheme.error,
      VersionCheckKind.none => theme.colorScheme.primary,
    };
  }

  Future<void> _handleTap() async {
    if (!mounted) {
      return;
    }

    final l10n = context.l10n;
    final installed = await ref.read(installedAppVersionProvider.future);
    if (!mounted) {
      return;
    }

    if (!_supportsUpdateCheck) {
      await showNoUpdateAvailableDialog(context, versionLabel: installed.label);
      return;
    }

    setState(() => _isChecking = true);
    await ref.read(versionCheckControllerProvider.notifier).check();
    if (!mounted) {
      return;
    }
    setState(() => _isChecking = false);

    final state = ref.read(versionCheckControllerProvider);
    final updateInfo = state.updateInfo;

    switch (state.kind) {
      case VersionCheckKind.none:
        await showNoUpdateAvailableDialog(
          context,
          versionLabel: installed.label,
          checkState: state,
        );
      case VersionCheckKind.error:
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.updateCheckFailedTitle),
            content: Text(l10n.updateCheckFailedBody),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.noUpdateAvailableOk),
              ),
            ],
          ),
        );
      case VersionCheckKind.optional:
        if (updateInfo != null) {
          await ref.read(appUpdateDialogPresenterProvider)(
            context,
            info: updateInfo,
            isForce: false,
          );
        }
      case VersionCheckKind.force:
        break;
    }
  }
}
