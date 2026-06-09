import 'package:flutter/material.dart';

import '../theme/app_branding.dart';

/// Shared loading experience for splash, live game, and modals.
class FriendsBingoLoading extends StatelessWidget {
  const FriendsBingoLoading({
    this.message,
    this.compact = false,
    super.key,
  });

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppBranding.brandName,
            style: AppBranding.wordmarkGold(size: compact ? 22 : 28),
          ),
          SizedBox(height: compact ? 12 : 20),
          SizedBox(
            width: compact ? 28 : 36,
            height: compact ? 28 : 36,
            child: CircularProgressIndicator(
              strokeWidth: compact ? 2.5 : 3,
              color: AppBranding.gold,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen branded loading (splash, initial game load).
class FriendsBingoLoadingScreen extends StatelessWidget {
  const FriendsBingoLoadingScreen({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FriendsBingoLoading(message: message ?? 'Getting ready...'),
    );
  }
}
