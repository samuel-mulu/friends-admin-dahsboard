import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';

enum GameTimelineStage {
  registration,
  preparing,
  playing,
  winnerWindow,
  finished,
}

/// Vertical game lifecycle timeline — highlights the current stage.
class GameTimeline extends StatelessWidget {
  const GameTimeline({
    required this.currentStage,
    this.compact = false,
    super.key,
  });

  factory GameTimeline.forGame(
    GameModel game, {
    bool waitingToPlay = false,
    bool compact = false,
  }) {
    return GameTimeline(
      currentStage: resolveGameTimelineStage(
        game,
        waitingToPlay: waitingToPlay,
      ),
      compact: compact,
    );
  }

  final GameTimelineStage currentStage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stages = [
      (GameTimelineStage.registration, l10n.gameTimelineRegistration),
      (GameTimelineStage.preparing, l10n.gameTimelinePreparing),
      (GameTimelineStage.playing, l10n.gameTimelinePlaying),
      (GameTimelineStage.winnerWindow, l10n.gameTimelineWinnerWindow),
      (GameTimelineStage.finished, l10n.gameTimelineFinished),
    ];

    return Semantics(
      label: l10n.gameTimelineSemantics(
        stages.firstWhere((item) => item.$1 == currentStage).$2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            _TimelineRow(
              label: stages[i].$2,
              active: stages[i].$1 == currentStage,
              completed: stages[i].$1.index < currentStage.index,
              isLast: i == stages.length - 1,
              compact: compact,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.active,
    required this.completed,
    required this.isLast,
    required this.compact,
    required this.theme,
  });

  final String label;
  final bool active;
  final bool completed;
  final bool isLast;
  final bool compact;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dotColor = active
        ? theme.colorScheme.primary
        : completed
        ? theme.colorScheme.primary.withValues(alpha: 0.55)
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 20 : 24,
            child: Column(
              children: [
                Container(
                  width: compact ? 10 : 12,
                  height: compact ? 10 : 12,
                  decoration: BoxDecoration(
                    color: active || completed ? dotColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: active ? 2 : 1.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed
                          ? dotColor
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : (compact ? AppSpacing.sm : AppSpacing.md),
              ),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

GameTimelineStage resolveGameTimelineStage(
  GameModel game, {
  bool waitingToPlay = false,
}) {
  if (waitingToPlay) {
    return GameTimelineStage.preparing;
  }

  return switch (game.playerStatus) {
    PlayerGameStatus.registrationOpen => GameTimelineStage.registration,
    PlayerGameStatus.playing => GameTimelineStage.playing,
    PlayerGameStatus.winnerWindow => GameTimelineStage.winnerWindow,
    PlayerGameStatus.checking => GameTimelineStage.playing,
    PlayerGameStatus.finished || PlayerGameStatus.cancelled =>
      GameTimelineStage.finished,
  };
}
