import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/session_winner_result_model.dart';
import 'winner_cartela_number_strip.dart';

/// Compact banner shown after the winner window closes; keeps the live layout
/// visible while players review the winning cartela before the next round.
class RoundFinishedBanner extends StatelessWidget {
  const RoundFinishedBanner({
    required this.isLoading,
    required this.isLoaded,
    required this.results,
    required this.winnerCartelaNumbers,
    required this.secondsRemaining,
    this.isNoWinner = false,
    this.isAdvancing = false,
    this.onNext,
    this.onOpenWinners,
    super.key,
  });

  final bool isLoading;
  final bool isLoaded;
  final List<SessionWinnerResultModel> results;
  final List<int> winnerCartelaNumbers;
  final int secondsRemaining;
  final bool isNoWinner;
  final bool isAdvancing;
  final VoidCallback? onNext;
  final VoidCallback? onOpenWinners;

  String _winnerLabel(dynamic l10n) {
    if (results.isNotEmpty) {
      final primary = results.first.cartelaNumber;
      if (results.length == 1) {
        return l10n.reviewModeWinnerCartela(primary);
      }
      return '${l10n.reviewModeWinnerCartela(primary)} · '
          '${l10n.reviewModeAdditionalWinners(results.length - 1)}';
    }

    if (winnerCartelaNumbers.isNotEmpty) {
      final primary = winnerCartelaNumbers.first;
      if (winnerCartelaNumbers.length == 1) {
        return l10n.reviewModeWinnerCartela(primary);
      }
      return '${l10n.reviewModeWinnerCartela(primary)} · '
          '+${winnerCartelaNumbers.length - 1}';
    }

    return l10n.gameResultsLoading;
  }

  void _openWinnerDialog(BuildContext context) {
    onOpenWinners?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canOpenDialog =
        !isAdvancing && !isNoWinner && onOpenWinners != null && results.isNotEmpty;

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: canOpenDialog ? () => _openWinnerDialog(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppBranding.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppBranding.gold,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNoWinner
                          ? l10n.sessionResultsNoWinners
                          : l10n.gameFinished,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isNoWinner) ...[
                      Text(
                        l10n.gameAllNumbersCalled,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.gameNoWinnerNextRoundShortly,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]                     else if (isLoading && results.isEmpty)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.gameResultsLoading,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (!isAdvancing) ...[
                      Text(
                        _winnerLabel(l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (results.length > 1) ...[
                        const SizedBox(height: 8),
                        IgnorePointer(
                          child: WinnerCartelaNumberStrip(
                            numbers: results
                                .map((result) => result.cartelaNumber)
                                .toList(growable: false),
                            selectedIndex: 0,
                            onSelected: (_) {},
                            compact: true,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 6),
                    if (isAdvancing)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppBranding.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.postGameSummaryOpeningNextRound,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppBranding.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        l10n.postGameSummaryNextRoundIn(secondsRemaining),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppBranding.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (canOpenDialog)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (results.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.swipe_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Icon(
                          Icons.open_in_full_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  if (onNext != null) ...[
                    if (canOpenDialog) const SizedBox(height: 8),
                    FilledButton(
                      onPressed: isAdvancing ? null : onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppBranding.goldAccent,
                        foregroundColor: AppBranding.brandPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: isAdvancing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppBranding.brandPurple,
                              ),
                            )
                          : Text(
                              l10n.postGameSummaryNextGame,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
