import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_branding.dart';
import '../utils/external_links.dart';
import '../utils/l10n.dart';
import 'android_app_version_model.dart';
import 'app_version_info.dart';
import 'version_check_controller.dart';
import 'version_check_state.dart';
import 'version_update_resume_recheck.dart';

typedef AppUpdateLaunchHandler =
    Future<bool> Function(BuildContext context, Uri uri);

typedef AppUpdateDialogPresenter =
    Future<void> Function(
      BuildContext context, {
      required AndroidAppVersionModel info,
      required bool isForce,
      AppUpdateLaunchHandler? onUpdate,
      VoidCallback? onForceUpdateLaunched,
      String? installedVersionLabel,
    });

final appUpdateDialogPresenterProvider = Provider<AppUpdateDialogPresenter>((
  ref,
) {
  return showAppUpdateDialog;
});

Future<void> showNoUpdateAvailableDialog(
  BuildContext context, {
  required String versionLabel,
  VersionCheckState? checkState,
}) {
  final l10n = context.l10n;
  final installedBuild = checkState?.installedBuild;
  final serverBuild = checkState?.remoteVersionCode;
  final serverVersion = checkState?.remoteVersionLabel;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.noUpdateAvailableTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.noUpdateAvailableBody),
            const SizedBox(height: 12),
            Text(
              l10n.drawerAppVersionCurrent(versionLabel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (installedBuild != null &&
                serverBuild != null &&
                serverVersion != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.updateStatusDetail(
                  installedBuild,
                  serverBuild,
                  serverVersion,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.noUpdateAvailableOk),
          ),
        ],
      );
    },
  );
}

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AndroidAppVersionModel info,
  required bool isForce,
  AppUpdateLaunchHandler? onUpdate,
  VoidCallback? onForceUpdateLaunched,
  String? installedVersionLabel,
}) {
  final l10n = context.l10n;

  return showDialog<void>(
    context: context,
    barrierDismissible: !isForce,
    barrierColor: AppBranding.lightScaffold.withValues(alpha: 0.92),
    useRootNavigator: true,
    useSafeArea: true,
    builder: (dialogContext) {
      if (!isForce) {
        return AlertDialog(
          title: Text(l10n.updateAvailableTitle),
          content: AppUpdateDialogContent(info: info, isForce: false),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.updateLater),
            ),
            FilledButton(
              onPressed: () => _handleUpdate(dialogContext, info, onUpdate),
              child: Text(l10n.updateAction),
            ),
          ],
        );
      }

      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ForceUpdatePanel(
            info: info,
            installedVersionLabel: installedVersionLabel,
            onUpdate: () => _handleForceUpdate(
              dialogContext,
              info: info,
              onUpdate: onUpdate,
              onForceUpdateLaunched: onForceUpdateLaunched,
            ),
          ),
        ),
      );
    },
  );
}

/// Blocks the entire app with a non-dismissible update prompt while a force
/// update is required. Lives in [MaterialApp.builder] so route changes cannot
/// remove it.
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(versionCheckControllerProvider);
    final info = state.updateInfo;
    if (state.kind != VersionCheckKind.force || info == null) {
      return child ?? const SizedBox.shrink();
    }

    final installedVersion =
        ref.watch(installedAppVersionProvider).asData?.value.version;

    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(child: child ?? const SizedBox.shrink()),
        ModalBarrier(
          dismissible: false,
          color: AppBranding.lightScaffold.withValues(alpha: 0.94),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ForceUpdatePanel(
                  info: info,
                  installedVersionLabel: installedVersion,
                  onUpdate: () => _handleForceUpdate(
                    context,
                    info: info,
                    onForceUpdateLaunched: () => ref
                        .read(
                          versionUpdateResumeRecheckControllerProvider.notifier,
                        )
                        .markForRecheck(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ForceUpdatePanel extends StatelessWidget {
  const ForceUpdatePanel({
    required this.info,
    required this.onUpdate,
    this.installedVersionLabel,
    super.key,
  });

  final AndroidAppVersionModel info;
  final VoidCallback onUpdate;
  final String? installedVersionLabel;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && info.sha256.isNotEmpty) {
      debugPrint('APK sha256: ${info.sha256}');
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final latestVersion = info.version.trim().isNotEmpty ? info.version : '—';
    final installedVersion = installedVersionLabel?.trim().isNotEmpty == true
        ? installedVersionLabel!.trim()
        : '—';

    return Material(
      color: AppBranding.lightSurface,
      elevation: 8,
      shadowColor: AppBranding.brandPurple.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppBranding.brandPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppBranding.brandPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.updateRequiredTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppBranding.lightOnSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.updateRequiredMessage(latestVersion),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppBranding.lightOnSurfaceMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            _InfoPanel(
              children: [
                _VersionInfoRow(
                  label: l10n.updateVersionInstalled,
                  value: installedVersion,
                ),
                const Divider(height: 1, color: Color(0xFFE5DDD0)),
                _VersionInfoRow(
                  label: l10n.updateVersionMinimum,
                  value: latestVersion,
                ),
                const Divider(height: 1, color: Color(0xFFE5DDD0)),
                _VersionInfoRow(
                  label: l10n.updateVersionLatest,
                  value: latestVersion,
                  emphasizeValue: true,
                ),
              ],
            ),
            if (info.downloadUrl.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoPanel(
                child: SelectableText(
                  info.downloadUrl.trim(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppBranding.lightOnSurfaceMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onUpdate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppBranding.brandPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.system_update_alt_rounded,
                  color: AppBranding.goldAccent,
                ),
                label: Text(
                  l10n.updateAction,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({this.child, this.children})
      : assert(child != null || children != null);

  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppBranding.lightSurfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppBranding.lightOutline.withValues(alpha: 0.45),
        ),
      ),
      child: child ?? Column(children: children!),
    );
  }
}

class _VersionInfoRow extends StatelessWidget {
  const _VersionInfoRow({
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppBranding.lightOnSurfaceMuted,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: emphasizeValue
                  ? AppBranding.brandPurple
                  : AppBranding.lightOnSurface,
              fontWeight: emphasizeValue ? FontWeight.w800 : FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _handleForceUpdate(
  BuildContext context, {
  required AndroidAppVersionModel info,
  AppUpdateLaunchHandler? onUpdate,
  VoidCallback? onForceUpdateLaunched,
}) async {
  await _handleUpdate(context, info, onUpdate);
  if (!context.mounted) {
    return;
  }
  onForceUpdateLaunched?.call();
}

Future<void> _handleUpdate(
  BuildContext context,
  AndroidAppVersionModel info,
  AppUpdateLaunchHandler? onUpdate,
) async {
  final uri = Uri.tryParse(info.downloadUrl);
  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.updateLinkUnavailable)),
      );
    }
    return;
  }

  final handler = onUpdate ?? _defaultUpdateHandler;
  await handler(context, uri);
}

Future<bool> _defaultUpdateHandler(BuildContext context, Uri uri) {
  return openExternalUri(context, uri);
}

class AppUpdateDialogContent extends StatelessWidget {
  const AppUpdateDialogContent({
    required this.info,
    required this.isForce,
    super.key,
  });

  final AndroidAppVersionModel info;
  final bool isForce;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && info.sha256.isNotEmpty) {
      debugPrint('APK sha256: ${info.sha256}');
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium;
    final notes = info.releaseNotes.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isForce
              ? l10n.updateRequiredMessage(info.version)
              : l10n.updateAvailableMessage(info.version),
          style: bodyStyle,
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(notes, style: bodyStyle),
        ],
        if (info.sha256.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            info.sha256,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
