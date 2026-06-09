import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

class WinnerWindowCountdownChip extends StatelessWidget {
  const WinnerWindowCountdownChip({required this.endsAt, super.key});

  final DateTime? endsAt;

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = endsAt == null
        ? 0
        : endsAt!.difference(DateTime.now()).inSeconds.clamp(0, 15);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppBranding.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppBranding.gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${remainingSeconds}s to claim bingo',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppBranding.goldDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
