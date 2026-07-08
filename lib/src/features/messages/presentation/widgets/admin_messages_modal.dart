import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/admin_broadcast_model.dart';
import '../providers/broadcasts_provider.dart';
import 'broadcast_message_ui.dart';

Future<void> showAdminMessagesModal(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: BroadcastMessageUi.sheetBackground(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _AdminMessagesSheet(
            scrollController: scrollController,
            sheetTheme: theme,
          );
        },
      );
    },
  );
}

class _AdminMessagesSheet extends ConsumerWidget {
  const _AdminMessagesSheet({
    required this.scrollController,
    required this.sheetTheme,
  });

  final ScrollController scrollController;
  final ThemeData sheetTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final broadcasts = ref.watch(broadcastsProvider);

    return broadcasts.when(
      loading: () => _MessagesSheetFrame(
        scrollController: scrollController,
        title: l10n.adminMessagesTitle,
        subtitle: l10n.adminMessagesLoading,
        child: ListView.separated(
          controller: scrollController,
          padding: BroadcastMessageUi.sheetPadding,
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => const _BroadcastCardSkeleton(),
        ),
      ),
      error: (error, stackTrace) => _MessagesSheetFrame(
        scrollController: scrollController,
        title: l10n.adminMessagesTitle,
        subtitle: null,
        child: ListView(
          controller: scrollController,
          padding: BroadcastMessageUi.sheetPadding,
          children: [
            const SizedBox(height: 48),
            Text(
              l10n.adminMessagesLoadError,
              textAlign: TextAlign.center,
              style: sheetTheme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      data: (state) {
        final items = state.inboxBroadcasts;

        return _MessagesSheetFrame(
          scrollController: scrollController,
          title: l10n.adminMessagesTitle,
          subtitle: items.isEmpty
              ? l10n.adminMessagesEmpty
              : l10n.adminMessagesCount(items.length),
          child: items.isEmpty
              ? ListView(
                  controller: scrollController,
                  padding: BroadcastMessageUi.sheetPadding,
                  children: [
                    const SizedBox(height: 56),
                    Icon(
                      Icons.inbox_rounded,
                      size: 56,
                      color: sheetTheme.colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      l10n.adminMessagesEmpty,
                      textAlign: TextAlign.center,
                      style: sheetTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: BroadcastMessageUi.sheetPadding,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final broadcast = items[index];
                    return _BroadcastMessageCard(
                      broadcast: broadcast,
                      onDismiss: broadcast.category ==
                              AdminBroadcastCategory.dismissible
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

class _MessagesSheetFrame extends StatelessWidget {
  const _MessagesSheetFrame({
    required this.scrollController,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final ScrollController scrollController;
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
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.lg,
          ),
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
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _BroadcastMessageCard extends StatelessWidget {
  const _BroadcastMessageCard({
    required this.broadcast,
    required this.onDismiss,
  });

  final AdminBroadcastModel broadcast;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDismissible =
        broadcast.category == AdminBroadcastCategory.dismissible;
    final isPersistent =
        broadcast.category == AdminBroadcastCategory.persistent;
    final accent = BroadcastMessageUi.accentFor(broadcast.category, theme.colorScheme);

    final card = Container(
      decoration: BroadcastMessageUi.cardDecoration(
        context: context,
        category: broadcast.category,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BroadcastMessageUi.leadingIcon(
                  context: context,
                  category: broadcast.category,
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              broadcast.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isPersistent)
                            _CategoryChip(
                              label: l10n.adminMessagesPersistentBadge,
                              color: accent.withValues(alpha: 0.14),
                              foreground: accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(broadcast.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Text(
                broadcast.body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            if (isDismissible && onDismiss != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text(l10n.adminMessagesDismiss),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isDismissible || onDismiss == null) {
      return card;
    }

    return Dismissible(
      key: ValueKey(broadcast.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.close_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: card,
    );
  }

  String _formatTimestamp(DateTime createdAt) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BroadcastCardSkeleton extends StatelessWidget {
  const _BroadcastCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
