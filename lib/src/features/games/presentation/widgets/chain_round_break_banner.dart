import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../domain/game_category_theme.dart';
import 'winner_cartela_number_strip.dart';

/// Chain Game inter-round break. Unlike `RoundFinishedBanner` this is *not* a
/// post-game state: the session is still PLAYING, the balls and marked cells
/// stay exactly where they are, and the draw resumes on its own. It replaces the
/// "next ball in Xs" line for the length of the pause.
class ChainRoundBreakBanner extends StatelessWidget {
  const ChainRoundBreakBanner({
    required this.finishedRoundIndex,
    required this.roundCount,
    required this.secondsRemaining,
    required this.totalPauseSeconds,
    this.results = const [],
    this.nextRoundPatternName,
    this.nextRoundPrizeLabel,
    this.onOpenWinners,
    super.key,
  });

  final int finishedRoundIndex;
  final int roundCount;
  final int secondsRemaining;
  final int totalPauseSeconds;
  final List<SessionWinnerResultModel> results;
  final String? nextRoundPatternName;
  final String? nextRoundPrizeLabel;
  final VoidCallback? onOpenWinners;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = GameCategoryTheme.accentColor(
      GameCategory.chainGame,
      isDark: theme.brightness == Brightness.dark,
    );
    final nextRound = (finishedRoundIndex + 1).clamp(1, roundCount);
    final canOpenWinners = onOpenWinners != null && results.isNotEmpty;

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: canOpenWinners ? onOpenWinners : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.link_rounded, color: accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chainRoundBreakTitle(finishedRoundIndex),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.chainRoundBreakSubtitle(nextRound, secondsRemaining),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (nextRoundPatternName != null &&
                        nextRoundPatternName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.chainRoundNextPattern(nextRoundPatternName!),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (nextRoundPrizeLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        nextRoundPrizeLabel!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
                ),
              ),
              const SizedBox(width: 8),
              _ChainPauseRing(
                secondsRemaining: secondsRemaining,
                totalSeconds: totalPauseSeconds,
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChainPauseRing extends StatelessWidget {
  const _ChainPauseRing({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.accent,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalSeconds > 0
        ? (secondsRemaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: progress, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                color: accent,
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          Text(
            '$secondsRemaining',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
