import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_avatar_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../data/models/support_message_model.dart';

class SupportMessageTile extends ConsumerWidget {
  const SupportMessageTile({
    required this.message,
    super.key,
  });

  final SupportMessageModel message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).session?.user;
    final playerName = user?.fullName ?? l10n.supportYouLabel;
    final playerShortName =
        firstNameFromFullName(playerName) ?? l10n.supportYouLabel;
    final avatarId = user == null
        ? null
        : ref.watch(profileAvatarProvider(user.id)).asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ThreadMetaLine(
          categoryLabel: _categoryLabel(l10n, message.category),
          statusLabel: _statusLabel(l10n, message.status),
          timestamp: message.createdAt,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SupportChatBubble(
          isOutgoing: true,
          senderName: playerShortName,
          message: message.message,
          sentAt: message.createdAt,
          avatar: UserProfileAvatar(
            fullName: playerName,
            avatarId: avatarId,
            radius: 16,
          ),
          bubbleColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimary,
          nameColor: theme.colorScheme.onSurfaceVariant,
        ),
        if (message.hasAdminReply)
          _SupportChatBubble(
            isOutgoing: false,
            senderName: l10n.supportAdminName,
            message: message.adminReply!,
            sentAt: message.repliedAt ?? message.updatedAt,
            avatar: _AdminAvatar(initials: _brandInitials()),
            bubbleColor: theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh
                : const Color(0xFFF1F2F6),
            textColor: theme.colorScheme.onSurface,
            nameColor: theme.colorScheme.onSurfaceVariant,
          ),
        const SizedBox(height: AppSpacing.xs),
        Divider(
          height: 24,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ],
    );
  }

  String _brandInitials() => 'FB';

  String _categoryLabel(dynamic l10n, SupportCategory category) {
    return switch (category) {
      SupportCategory.feedback => l10n.supportCategoryFeedback,
      SupportCategory.complaint => l10n.supportCategoryComplaint,
      SupportCategory.advice => l10n.supportCategoryAdvice,
      SupportCategory.other => l10n.supportCategoryOther,
    };
  }

  String _statusLabel(dynamic l10n, SupportStatus status) {
    return switch (status) {
      SupportStatus.open => l10n.supportStatusOpen,
      SupportStatus.replied => l10n.supportStatusReplied,
      SupportStatus.closed => l10n.supportStatusClosed,
    };
  }
}

class _ThreadMetaLine extends StatelessWidget {
  const _ThreadMetaLine({
    required this.categoryLabel,
    required this.statusLabel,
    required this.timestamp,
  });

  final String categoryLabel;
  final String statusLabel;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      '$categoryLabel · ${formatDateTime(timestamp)} · $statusLabel',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppBranding.brandPurple,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupportChatBubble extends StatelessWidget {
  const _SupportChatBubble({
    required this.isOutgoing,
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.avatar,
    required this.bubbleColor,
    required this.textColor,
    required this.nameColor,
  });

  final bool isOutgoing;
  final String senderName;
  final String message;
  final DateTime sentAt;
  final Widget avatar;
  final Color bubbleColor;
  final Color textColor;
  final Color nameColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
      bottomRight: Radius.circular(isOutgoing ? 4 : 16),
    );

    final bubble = Flexible(
      child: Column(
        crossAxisAlignment:
            isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: isOutgoing ? 40 : 4,
              right: isOutgoing ? 4 : 40,
              bottom: 2,
            ),
            child: Text(
              senderName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: nameColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: bubbleRadius,
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isOutgoing ? 40 : 4,
              right: isOutgoing ? 4 : 40,
              top: 2,
            ),
            child: Text(
              _formatTime(sentAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: nameColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isOutgoing
            ? [bubble, const SizedBox(width: AppSpacing.xs), avatar]
            : [avatar, const SizedBox(width: AppSpacing.xs), bubble],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
