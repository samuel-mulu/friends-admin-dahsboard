import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import 'registration_tap_hint.dart';

class RegistrationActionDock extends StatelessWidget {
  const RegistrationActionDock({
    required this.isGuest,
    required this.selectModeEnabled,
    required this.selectionSecondsRemaining,
    required this.selectedCount,
    this.maxAffordableSelections,
    this.remainingBalance,
    required this.onReview,
    required this.onCancelSelection,
    required this.onExitSelectMode,
    super.key,
  });

  final bool isGuest;
  final bool selectModeEnabled;
  final int? selectionSecondsRemaining;
  final int selectedCount;
  final int? maxAffordableSelections;
  final String? remainingBalance;
  final VoidCallback onReview;
  final VoidCallback onCancelSelection;
  final VoidCallback onExitSelectMode;

  @override
  Widget build(BuildContext context) {
    if (!selectModeEnabled || isGuest) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: const RegistrationTapHint(
                      isGuest: false,
                      selectModeEnabled: true,
                    ),
                  ),
                  IconButton(
                    onPressed: onExitSelectMode,
                    tooltip: l10n.bulkCancel,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    icon: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              VGap.md,
              Row(
                children: [
                  if (selectionSecondsRemaining != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectionSecondsRemaining! <= 10
                            ? theme.colorScheme.error.withValues(alpha: 0.14)
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                        border: selectionSecondsRemaining! <= 10
                            ? Border.all(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.45,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        l10n.gameSecondsLeft(selectionSecondsRemaining!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: selectionSecondsRemaining! <= 10
                              ? theme.colorScheme.error
                              : theme.colorScheme.onPrimaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  if (maxAffordableSelections != null &&
                      remainingBalance != null) ...[
                    const SizedBox(width: 8),
                    const SizedBox.shrink(),
                  ] else if (maxAffordableSelections != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      l10n.gameUpTo(maxAffordableSelections!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: selectedCount > 0 ? onCancelSelection : null,
                    child: Text(l10n.gameClear),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: selectedCount > 0 ? onReview : null,
                    child: Text(l10n.gameReview(selectedCount)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
