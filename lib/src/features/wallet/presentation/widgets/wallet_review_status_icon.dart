import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Shared visual states for deposit / withdrawal review cards.
enum WalletReviewVisualStatus {
  loading,
  approved,
  rejected,
  waiting,
}

/// Reusable status glyph shown inside pending-review cards.
///
/// [loading] shows an in-card spinner while waiting for admin action.
class WalletReviewStatusIcon extends StatelessWidget {
  const WalletReviewStatusIcon({
    required this.status,
    this.size = 44,
    super.key,
  });

  final WalletReviewVisualStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == WalletReviewVisualStatus.loading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppBranding.goldAccent,
        ),
      );
    }

    final Color color;
    final IconData icon;
    switch (status) {
      case WalletReviewVisualStatus.approved:
        color = AppBranding.feltGreen;
        icon = Icons.check_rounded;
      case WalletReviewVisualStatus.rejected:
        color = theme.colorScheme.error;
        icon = Icons.close_rounded;
      case WalletReviewVisualStatus.waiting:
        color = AppBranding.goldAccent;
        icon = Icons.schedule_rounded;
      case WalletReviewVisualStatus.loading:
        color = AppBranding.goldAccent;
        icon = Icons.schedule_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: Colors.white, size: size * 0.64),
    );
  }
}
