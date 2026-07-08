import 'package:flutter/material.dart';

/// Compact loading indicator for modals, lists, and inline states.
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
          SizedBox(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            child: CircularProgressIndicator(
              strokeWidth: compact ? 2.5 : 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: compact ? 10 : 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
