import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/called_number_model.dart';
import '../../data/models/game_model.dart';
import '../utils/missed_live_preview_resolver.dart';
import 'latest_call_pulse.dart';

/// Compact read-only mini preview of an unowned live round (Player 2 on Game B).
///
/// Layout: localized rule name + status side-by-side, then a small-height
/// called-number ball strip (active + recent). Immutable inputs only.
class MissedLiveGamePreview extends StatelessWidget {
  const MissedLiveGamePreview({
    required this.session,
    required this.phase,
    required this.calledNumbers,
    required this.activeNumber,
    required this.remainingCount,
    this.title,
    this.countdownLabel,
    super.key,
  });

  final GameModel session;
  final MissedPreviewPhase phase;
  final List<CalledNumberModel> calledNumbers;
  final int? activeNumber;
  final int remainingCount;

  /// Localized rule / game name (e.g. "Big T + 2 Squares" / Amharic equivalent).
  final String? title;
  final String? countdownLabel;

  static const double _activeBallSize = 40;
  static const double _recentBallSize = 28;

  @override
  Widget build(BuildContext context) {
    if (phase == MissedPreviewPhase.none) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppBranding.gold : AppBranding.brandPurple;
    final remainingColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : AppBranding.casinoPurpleDeep.withValues(alpha: 0.85);
    final baseTitle = (title != null && title!.trim().isNotEmpty)
        ? title!.trim()
        : (session.name.isNotEmpty
              ? session.name
              : (session.staticCode.isNotEmpty ? session.staticCode : 'Game'));
    final displayTitle = l10n.missedPreviewGameTitle(baseTitle);

    final active = calledNumbers.isNotEmpty
        ? calledNumbers.last
        : null;
    final recent = calledNumbers.length <= 1
        ? const <CalledNumberModel>[]
        : calledNumbers
              .sublist(0, calledNumbers.length - 1)
              .reversed
              .toList(growable: false);

    return Semantics(
      label: 'Missed live game preview',
      child: Container(
        key: const ValueKey('missed-live-game-preview'),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: AppBranding.panelBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppBranding.panelBorder(context).withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(l10n),
                  key: ValueKey('missed-preview-status-$phase'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppBranding.balanceAccent(context),
                    height: 1.1,
                  ),
                ),
              ],
            ),
            if (phase != MissedPreviewPhase.none) ...[
              const SizedBox(height: 6),
              _MissedPreviewBallsTray(
                child: SizedBox(
                  height: _activeBallSize + 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          if (active != null)
                            _MissedPreviewBall(
                              key: const ValueKey('missed-preview-active'),
                              calledNumber: active,
                              size: _activeBallSize,
                              isLatest: true,
                            )
                          else
                            const _MissedPreviewBall(
                              key: ValueKey('missed-preview-waiting'),
                              calledNumber: null,
                              size: _activeBallSize,
                              isLatest: true,
                            ),
                          if (recent.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: ListView.separated(
                                key: const ValueKey('missed-preview-recent'),
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: recent.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 5),
                                itemBuilder: (context, index) {
                                  return _MissedPreviewBall(
                                    calledNumber: recent[index],
                                    size: _recentBallSize,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (phase == MissedPreviewPhase.winnerWindow)
                        Positioned.fill(
                          child: _MissedPreviewWinnerWindowOverlay(
                            label: l10n.gameWinnerWindowOpen,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (phase == MissedPreviewPhase.livePlaying) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.missedPreviewRemaining(remainingCount),
                  key: const ValueKey('missed-preview-remaining'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: remainingColor,
                    height: 1.1,
                  ),
                ),
                if (countdownLabel != null && countdownLabel!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    countdownLabel!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    return switch (phase) {
      MissedPreviewPhase.livePlaying => l10n.calledNumbersSyncLive,
      MissedPreviewPhase.checking => l10n.calledNumbersCheckingBingo,
      // Prefer gameWinnerWindowOpen — translated in am/ti/om (gameStatusWinnerWindow is EN-only).
      MissedPreviewPhase.winnerWindow => l10n.gameWinnerWindowOpen,
      MissedPreviewPhase.none => '',
    };
  }
}

class _MissedPreviewWinnerWindowOverlay extends StatelessWidget {
  const _MissedPreviewWinnerWindowOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ExcludeSemantics(
      child: DecoratedBox(
        key: const ValueKey('missed-preview-winner-window-overlay'),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : AppBranding.casinoPurpleDeep)
              .withValues(alpha: isDark ? 0.72 : 0.78),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              key: const ValueKey('missed-preview-winner-window-label'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissedPreviewBallsTray extends StatelessWidget {
  const _MissedPreviewBallsTray({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return child;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppBranding.cartelaBoardBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppBranding.lightOutline.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }
}

class _MissedPreviewBall extends StatelessWidget {
  const _MissedPreviewBall({
    required this.calledNumber,
    required this.size,
    this.isLatest = false,
    super.key,
  });

  final CalledNumberModel? calledNumber;
  final double size;
  final bool isLatest;

  static BoxDecoration _ballDecoration({
    required Color baseColor,
    required bool isLatest,
    required bool isEmpty,
    required bool isDark,
  }) {
    if (isEmpty) {
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 1.05,
          colors: [
            isDark ? const Color(0xFF3A3A3A) : AppBranding.lightSurface,
            isDark ? const Color(0xFF2A2A2A) : AppBranding.lightSurfaceMuted,
            isDark ? const Color(0xFF1F1F1F) : AppBranding.lightOutline,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.45),
          width: 1,
        ),
      );
    }

    final highlight = Color.lerp(baseColor, Colors.white, 0.42)!;
    final shadowTone = Color.lerp(baseColor, Colors.black, 0.28)!;

    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 1.05,
        colors: [highlight, baseColor, shadowTone],
        stops: const [0.0, 0.58, 1.0],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: isLatest ? 0.18 : 0.28),
        width: 1,
      ),
      boxShadow: isLatest
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ]
          : [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.35),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = calledNumber == null;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isEmpty
        ? theme.colorScheme.surfaceContainerHighest
        : isLatest
        ? (isDark ? AppBranding.gold : AppBranding.goldDark)
        : AppBranding.bingoColumnColor(calledNumber!.letter);

    final ball = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: _ballDecoration(
          baseColor: baseColor,
          isLatest: isLatest,
          isEmpty: isEmpty,
          isDark: isDark,
        ),
        child: Center(
          child: isEmpty
              ? Text(
                  '--',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${calledNumber!.letter}-${calledNumber!.number}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isLatest ? 13 : 10,
                      height: 1,
                      color: isLatest
                          ? AppBranding.casinoPurpleDeep
                          : Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );

    if (isLatest && !isEmpty) {
      return LatestCallPulse(
        key: ValueKey<String>(
          '${calledNumber!.letter}-${calledNumber!.number}-preview',
        ),
        shape: BoxShape.circle,
        highlightColor: isDark ? AppBranding.gold : AppBranding.goldDark,
        pulseScale: 0.08,
        child: ball,
      );
    }

    return ball;
  }
}
