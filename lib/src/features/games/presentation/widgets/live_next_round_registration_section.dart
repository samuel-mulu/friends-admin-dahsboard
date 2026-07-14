import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_rule_localized_name.dart';
import 'collapsible_live_top_section.dart';

enum LiveNextRoundSectionVariant {
  nextQueued,
  missedCurrentRound,
  joinCurrentRound,
}

/// Labeled registration area shown below the called-numbers strip when a live
/// player has no cartelas in the current round.
class LiveNextRoundRegistrationSection extends ConsumerWidget {
  const LiveNextRoundRegistrationSection({
    required this.gameName,
    required this.sectionTitle,
    required this.helperText,
    required this.registeredCartelaNumbers,
    required this.panel,
    this.nextGame,
    this.currentRoundGame,
    this.currentRoundGameName,
    this.variant = LiveNextRoundSectionVariant.nextQueued,
    @Deprecated('Use variant instead') this.missedCurrentRoundMode = false,
    @Deprecated('Use variant instead') this.nextQueuedPlayLabel,
    super.key,
  });

  final String gameName;
  final String sectionTitle;
  final String helperText;
  final List<int> registeredCartelaNumbers;
  final Widget panel;
  final GameModel? nextGame;
  final GameModel? currentRoundGame;
  final String? currentRoundGameName;
  final LiveNextRoundSectionVariant variant;
  final bool missedCurrentRoundMode;
  final String? nextQueuedPlayLabel;

  LiveNextRoundSectionVariant get _resolvedVariant {
    if (missedCurrentRoundMode) {
      return LiveNextRoundSectionVariant.missedCurrentRound;
    }
    return variant;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final resolvedVariant = _resolvedVariant;
    final isMissedRound =
        resolvedVariant == LiveNextRoundSectionVariant.missedCurrentRound;
    final isJoinCurrentRound =
        resolvedVariant == LiveNextRoundSectionVariant.joinCurrentRound;
    final showRegisteredSection =
        !isMissedRound || registeredCartelaNumbers.isNotEmpty;
    final showRegisteredLabel = !isMissedRound && showRegisteredSection;
    final showRegisteredEmpty =
        !isMissedRound && registeredCartelaNumbers.isEmpty;
    final nextGameName = nextGame?.localizedRuleName(ref) ?? gameName;
    final liveGameName = currentRoundGame?.localizedRuleName(ref) ??
        currentRoundGameName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMissedRound) ...[
          _MissedRoundFlowCard(
            currentRoundGameName: liveGameName,
            nextGameName: nextGameName,
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (isJoinCurrentRound) ...[
          _JoinCurrentRoundCalloutCard(
            gameName: nextGameName,
            helperText: helperText,
          ),
          const SizedBox(height: AppSpacing.xl),
        ] else ...[
          Text(
            sectionTitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _GameRuleTitleText(label: gameName),
          const SizedBox(height: AppSpacing.xs),
          Text(
            helperText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (showRegisteredSection) ...[
          const SizedBox(height: AppSpacing.lg),
          if (showRegisteredLabel) ...[
            Text(
              l10n.liveRegisteredCartelasLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (showRegisteredEmpty)
            Text(
              l10n.liveRegisteredCartelasEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final number in registeredCartelaNumbers)
                  Chip(
                    label: Text('#$number'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
        ],
        const SizedBox(height: AppSpacing.md),
        Expanded(child: panel),
      ],
    );
  }
}

class _GameRuleTitleText extends StatelessWidget {
  const _GameRuleTitleText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppBranding.wordmarkGold(size: 20).copyWith(
        color: isDark ? AppBranding.gold : AppBranding.brandPurple,
        letterSpacing: 1.6,
        height: 1.05,
      ),
    );
  }
}

class _MissedRoundFlowCard extends StatefulWidget {
  const _MissedRoundFlowCard({
    required this.nextGameName,
    this.currentRoundGameName,
  });

  final String? currentRoundGameName;
  final String nextGameName;

  @override
  State<_MissedRoundFlowCard> createState() => _MissedRoundFlowCardState();
}

class _MissedRoundFlowCardState extends State<_MissedRoundFlowCard> {
  bool? _overviewExpanded;
  bool? _currentRoundExpanded;
  bool? _nextRoundExpanded;

  bool get _isOverviewExpanded => _overviewExpanded ?? false;
  bool get _isCurrentRoundExpanded => _currentRoundExpanded ?? false;
  bool get _isNextRoundExpanded => _nextRoundExpanded ?? false;

  @override
  void initState() {
    super.initState();
    _overviewExpanded = false;
    _currentRoundExpanded = false;
    _nextRoundExpanded = false;
  }

  void _toggleOverview() {
    setState(() => _overviewExpanded = !_isOverviewExpanded);
  }

  void _toggleCurrentRound() {
    setState(() => _currentRoundExpanded = !_isCurrentRoundExpanded);
  }

  void _toggleNextRound() {
    setState(() => _nextRoundExpanded = !_isNextRoundExpanded);
  }

  BoxDecoration _sectionDecoration({
    required bool isDark,
    required Color borderAccent,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark
            ? borderAccent.withValues(alpha: 0.28)
            : AppBranding.lightOutline.withValues(alpha: 0.55),
      ),
      color: isDark ? AppBranding.liveCardDark : AppBranding.lightSurfaceRaised,
    );
  }

  Widget _collapsibleSectionHeader({
    required ThemeData theme,
    required IconData icon,
    required Color accent,
    required String title,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent.withValues(alpha: 0.95)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    // Light mode needs stronger accents — pale gold vanishes on cream surfaces.
    final liveAccent =
        isDark ? const Color(0xFFF59E0B) : AppBranding.goldDark;
    final nextAccent = isDark ? AppBranding.gold : AppBranding.brandPurple;
    final headerAccent = isDark ? AppBranding.gold : AppBranding.brandPurple;
    final collapsedMissedColor =
        isDark ? liveAccent.withValues(alpha: 0.95) : const Color(0xFF8A5A00);
    final collapsedNextColor =
        isDark ? nextAccent.withValues(alpha: 0.95) : AppBranding.brandPurple;

    return Container(
      decoration: _sectionDecoration(
        isDark: isDark,
        borderAccent: nextAccent,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleOverview,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.view_agenda_outlined,
                      size: 18,
                      color: headerAccent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.liveMissedRoundOverviewTitle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: headerAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!_isOverviewExpanded) ...[
                            const SizedBox(height: AppSpacing.xs),
                            if (widget.currentRoundGameName != null) ...[
                              Text(
                                l10n.liveMissedRoundCollapsedMissed(
                                  widget.currentRoundGameName!,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: collapsedMissedColor,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              l10n.liveMissedRoundCollapsedNextReady(
                                widget.nextGameName,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: collapsedNextColor,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    MasterDetailCollapseButton(
                      expanded: _isOverviewExpanded,
                      onPressed: _toggleOverview,
                      labelColor: headerAccent.withValues(alpha: 0.88),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isOverviewExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.currentRoundGameName != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: _sectionDecoration(
                            isDark: isDark,
                            borderAccent: liveAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _collapsibleSectionHeader(
                                theme: theme,
                                icon: Icons.sensors_rounded,
                                accent: liveAccent,
                                title: l10n.liveMissedCurrentRoundTitle,
                                expanded: _isCurrentRoundExpanded,
                                onTap: _toggleCurrentRound,
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                child: _isCurrentRoundExpanded
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(
                                            height: AppSpacing.xs,
                                          ),
                                          _GameRuleTitleText(
                                            label: widget.currentRoundGameName!,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.liveMissedRoundYouMissedGame,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: nextAccent.withValues(alpha: 0.85),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.liveMissedRoundRegisterBridge,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        decoration: _sectionDecoration(
                          isDark: isDark,
                          borderAccent: nextAccent,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _collapsibleSectionHeader(
                              theme: theme,
                              icon: Icons.event_available_rounded,
                              accent: nextAccent,
                              title: l10n.liveNextQueuedPlayLabel,
                              expanded: _isNextRoundExpanded,
                              onTap: _toggleNextRound,
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: _isNextRoundExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.xs,
                                      ),
                                      child: _GameRuleTitleText(
                                        label: widget.nextGameName,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}


class _JoinCurrentRoundCalloutCard extends StatelessWidget {
  const _JoinCurrentRoundCalloutCard({
    required this.gameName,
    required this.helperText,
  });

  final String gameName;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    const accent = AppBranding.gold;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.4 : 0.35),
        ),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppBranding.casinoPurpleDeep.withValues(alpha: 0.85),
                  AppBranding.casinoPurple.withValues(alpha: 0.7),
                ],
              )
            : null,
        color: isDark ? null : accent.withValues(alpha: 0.08),
      ),
      padding: AppSpacing.cardPaddingDense,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.liveJoinCurrentRoundGameLive(gameName),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _GameRuleTitleText(label: gameName),
          const SizedBox(height: AppSpacing.xs),
          Text(
            helperText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
