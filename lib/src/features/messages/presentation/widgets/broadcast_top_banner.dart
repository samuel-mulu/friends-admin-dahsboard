import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/broadcast_banner_provider.dart';
import 'admin_messages_modal.dart';
import 'broadcast_message_ui.dart';

/// Compact in-app notification toast under the app bar.
class BroadcastTopBanner extends ConsumerWidget {
  const BroadcastTopBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authControllerProvider).session == null;
    if (isGuest) {
      return const SizedBox.shrink();
    }

    final message = ref.watch(broadcastBannerProvider).visibleMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = BroadcastMessageUi.accentFor(
      message.category,
      theme.colorScheme,
    );
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Material(
        color: BroadcastMessageUi.bannerBackground(context),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => showAdminMessagesModal(context, ref),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BroadcastMessageUi.leadingIcon(
                  context: context,
                  category: message.category,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (message.body.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          message.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.announcementDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(broadcastBannerProvider.notifier).closeBanner(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
