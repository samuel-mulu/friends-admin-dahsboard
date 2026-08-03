import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/admin_broadcast_model.dart';
import '../providers/broadcasts_provider.dart';
import 'broadcast_message_ui.dart';

Future<void> showAdminMessagesModal(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: BroadcastMessageUi.sheetBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return _AdminMessagesSheet(scrollController: scrollController);
        },
      );
    },
  );
}

class _AdminMessagesSheet extends ConsumerWidget {
  const _AdminMessagesSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final broadcasts = ref.watch(broadcastsProvider);

    return broadcasts.when(
      loading: () => _NotificationsFrame(
        title: l10n.adminMessagesTitle,
        subtitle: l10n.adminMessagesLoading,
        child: ListView.separated(
          controller: scrollController,
          padding: BroadcastMessageUi.sheetPadding,
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => const _NotificationTileSkeleton(),
        ),
      ),
      error: (error, stackTrace) => _NotificationsFrame(
        title: l10n.adminMessagesTitle,
        subtitle: null,
        child: ListView(
          controller: scrollController,
          padding: BroadcastMessageUi.sheetPadding,
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.adminMessagesLoadError,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      data: (state) {
        final items = state.inboxBroadcasts;

        return _NotificationsFrame(
          title: l10n.adminMessagesTitle,
          subtitle: items.isEmpty
              ? l10n.adminMessagesEmpty
              : l10n.adminMessagesCount(items.length),
          child: items.isEmpty
              ? ListView(
                  controller: scrollController,
                  padding: BroadcastMessageUi.sheetPadding,
                  children: [
                    const SizedBox(height: 64),
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 56,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.adminMessagesEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: BroadcastMessageUi.sheetPadding,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final broadcast = items[index];
                    return _NotificationTile(
                      broadcast: broadcast,
                      onDismiss: broadcast.canDismiss
                          ? () => ref
                                .read(broadcastsProvider.notifier)
                                .dismiss(broadcast.id)
                          : null,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _NotificationsFrame extends StatelessWidget {
  const _NotificationsFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xs,
            AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.broadcast,
    required this.onDismiss,
  });

  final AdminBroadcastModel broadcast;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = BroadcastMessageUi.accentFor(
      broadcast.category,
      theme.colorScheme,
    );
    final isDark = theme.brightness == Brightness.dark;
    final isPersistent =
        broadcast.category == AdminBroadcastCategory.persistent;

    return Material(
      color: BroadcastMessageUi.tileBackground(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.28 : 0.5,
            ),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BroadcastMessageUi.leadingIcon(
                        context: context,
                        category: broadcast.category,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    broadcast.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                if (isPersistent)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      Icons.push_pin_rounded,
                                      size: 16,
                                      color: accent,
                                    ),
                                  ),
                              ],
                            ),
                            if (broadcast.body.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                broadcast.body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              BroadcastMessageUi.relativeTime(
                                broadcast.createdAt,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onDismiss != null)
                        IconButton(
                          tooltip: l10n.adminMessagesDismiss,
                          visualDensity: VisualDensity.compact,
                          onPressed: onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTileSkeleton extends StatelessWidget {
  const _NotificationTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
