import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/broadcast_banner_provider.dart';
import 'admin_messages_modal.dart';
import 'broadcast_message_ui.dart';

/// Compact top banner for new admin messages (dismissible / persistent).
class BroadcastTopBanner extends ConsumerWidget {
  const BroadcastTopBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(authControllerProvider).session == null;
    if (isGuest) {
      return const SizedBox.shrink();
    }

    final bannerState = ref.watch(broadcastBannerProvider);
    final message = bannerState.visibleMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = BroadcastMessageUi.accentFor(
      message.category,
      theme.colorScheme,
    );

    return Material(
      color: accent.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.1),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BroadcastMessageUi.leadingIcon(
                context: context,
                category: message.category,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: () => showAdminMessagesModal(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                        const SizedBox(height: 4),
                        Text(
                          l10n.adminMessagesTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.announcementDismiss,
                onPressed: () =>
                    ref.read(broadcastBannerProvider.notifier).closeBanner(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
