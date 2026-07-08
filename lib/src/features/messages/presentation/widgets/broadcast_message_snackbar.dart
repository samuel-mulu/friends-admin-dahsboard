import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../data/models/admin_broadcast_model.dart';
import 'admin_messages_modal.dart';

void showBroadcastMessageSnackBar(
  BuildContext context,
  WidgetRef ref,
  AdminBroadcastModel message,
) {
  if (message.isForced) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }

  final l10n = context.l10n;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (message.body.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l10n.adminMessagesTitle,
          onPressed: () => showAdminMessagesModal(context, ref),
        ),
      ),
    );
}
