import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/external_links.dart';
import '../utils/l10n.dart';
import 'android_app_version_model.dart';
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
}) {
  final l10n = context.l10n;

  return showDialog<void>(
    context: context,
    barrierDismissible: !isForce,
    barrierColor: Colors.black54,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (dialogContext) {
      final content = AppUpdateDialogContent(info: info, isForce: isForce);

      if (!isForce) {
        return AlertDialog(
          title: Text(l10n.updateAvailableTitle),
          content: content,
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
        child: AlertDialog(
          title: Text(l10n.updateRequiredTitle),
          content: content,
          actions: [
            FilledButton(
              onPressed: () => _handleForceUpdate(
                dialogContext,
                info: info,
                onUpdate: onUpdate,
                onForceUpdateLaunched: onForceUpdateLaunched,
              ),
              child: Text(l10n.updateAction),
            ),
          ],
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

    final l10n = context.l10n;

    return Stack(
      fit: StackFit.expand,
      children: [
        AbsorbPointer(child: child ?? const SizedBox.shrink()),
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AlertDialog(
                title: Text(l10n.updateRequiredTitle),
                content: AppUpdateDialogContent(info: info, isForce: true),
                actions: [
                  FilledButton(
                    onPressed: () => _handleForceUpdate(
                      context,
                      info: info,
                      onForceUpdateLaunched: () => ref
                          .read(
                            versionUpdateResumeRecheckControllerProvider
                                .notifier,
                          )
                          .markForRecheck(),
                    ),
                    child: Text(l10n.updateAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
