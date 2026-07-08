import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';

enum BulkChipRegistrationStatus { idle, pending, active, done }

/// Review-style cartela chip with separate preview tap and remove action.
class RemovableCartelaNumberChip extends StatelessWidget {
  const RemovableCartelaNumberChip({
    required this.number,
    required this.onTap,
    required this.onRemove,
    this.enabled = true,
    this.registrationStatus = BulkChipRegistrationStatus.idle,
    super.key,
  });

  final int number;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool enabled;
  final BulkChipRegistrationStatus registrationStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDone = registrationStatus == BulkChipRegistrationStatus.done;
    final isActive = registrationStatus == BulkChipRegistrationStatus.active;
    final isPending = registrationStatus == BulkChipRegistrationStatus.pending;

    final foreground = isDone
        ? AppBranding.bingoFreeGreen
        : AppBranding.cartelaChipAvailableForeground(context);

    return Opacity(
      opacity: isPending ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDone
              ? AppBranding.cartelaChipMineBackground(context)
              : AppBranding.cartelaChipSelectedBackground(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone
                ? AppBranding.cartelaChipMineBorder(context)
                : isActive
                    ? AppBranding.gold
                    : AppBranding.cartelaChipAvailableBorder(context),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(7),
                ),
                onTap: enabled ? onTap : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) ...[
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppBranding.gold,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (isDone) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppBranding.bingoFreeGreen,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '#$number',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.only(right: 2),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: l10n.bulkRemoveCartela(number),
              onPressed: enabled ? onRemove : null,
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: enabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
