import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_model.dart';
import '../../domain/game_rule_localized_name.dart';
import 'bonus_game_info_strip.dart';
import 'big_game_info_strip.dart';
import 'game_compact_info_bar.dart';
import 'live_status_chip.dart';

enum LiveTopSectionVariant { livePlay, registration }

class MasterDetailCollapseButton extends StatelessWidget {
  const MasterDetailCollapseButton({
    required this.expanded,
    required this.onPressed,
    this.label,
    this.labelColor,
    super.key,
  });

  final bool expanded;
  final VoidCallback onPressed;
  final String? label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedLabelColor = labelColor ?? theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: expanded ? 'Hide game info' : 'Show game info',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (label != null) ...[
                  Text(
                    label!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: resolvedLabelColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 1),
                ],
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: resolvedLabelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Registration-open header: pulse banner + collapsible game info in one card.
class CollapsibleRegistrationOpenCluster extends StatelessWidget {
  const CollapsibleRegistrationOpenCluster({
    required this.game,
    required this.banner,
    required this.expanded,
    required this.onExpandedChanged,
    this.statusBanner,
    this.showRule = true,
    this.myRegisteredCartelasCount,
    super.key,
  });

  final GameModel game;
  final Widget banner;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget? statusBanner;
  final bool showRule;
  final int? myRegisteredCartelasCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? null : AppBranding.lightSurfaceRaised,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppBranding.casinoPurpleDeep,
                  AppBranding.casinoPurple,
                  AppBranding.casinoPurpleDeep,
                ],
                stops: [0, 0.55, 1],
              )
            : null,
        border: Border.all(
          color: isDark
              ? AppBranding.gold.withValues(alpha: 0.45)
              : AppBranding.lightOutline,
          width: isDark ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppBranding.brandPurple.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: banner),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 2),
                child: MasterDetailCollapseButton(
                  expanded: expanded,
                  onPressed: () => onExpandedChanged(!expanded),
                  label: 'info',
                  labelColor: isDark
                      ? AppBranding.gold.withValues(alpha: 0.88)
                      : AppBranding.brandPurple.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppBranding.panelBorder(
                                context,
                              ).withValues(alpha: 0.65),
                      ),
                      GameCompactInfoBar(
                        game: game,
                        showRule: showRule,
                        layout: GameCompactInfoBarLayout.registrationOpen,
                        embedded: true,
                        myRegisteredCartelasCount: myRegisteredCartelasCount,
                      ),
                      if (statusBanner != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: statusBanner!,
                        ),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class CollapsibleLiveTopSection extends ConsumerStatefulWidget {
  const CollapsibleLiveTopSection({
    required this.game,
    this.nextGame,
    this.nextRegisteredCartelaNumbers = const [],
    this.showRule = true,
    this.variant = LiveTopSectionVariant.registration,
    this.initiallyExpanded,
    this.expanded,
    this.onExpandedChanged,
    this.myRegisteredCartelasCount,
    super.key,
  });

  final GameModel game;
  final GameModel? nextGame;
  final List<int> nextRegisteredCartelaNumbers;
  final bool showRule;
  final LiveTopSectionVariant variant;
  final bool? initiallyExpanded;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;
  final int? myRegisteredCartelasCount;

  @override
  ConsumerState<CollapsibleLiveTopSection> createState() =>
      _CollapsibleLiveTopSectionState();
}

class _CollapsibleLiveTopSectionState
    extends ConsumerState<CollapsibleLiveTopSection> {
  late bool _internalExpanded = _initialExpandedFor(widget);
  bool _nextGameExpanded = false;

  static bool _initialExpandedFor(CollapsibleLiveTopSection widget) {
    return widget.expanded ??
        widget.initiallyExpanded ??
        widget.variant == LiveTopSectionVariant.registration;
  }

  bool get _expanded => widget.expanded ?? _internalExpanded;

  void _setExpanded(bool value) {
    if (widget.expanded != null) {
      if (widget.expanded == value) {
        return;
      }
      widget.onExpandedChanged?.call(value);
      return;
    }

    setState(() => _internalExpanded = value);
    widget.onExpandedChanged?.call(value);
  }

  @override
  void didUpdateWidget(covariant CollapsibleLiveTopSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != null && widget.expanded != oldWidget.expanded) {
      _internalExpanded = widget.expanded!;
    }
  }

  bool get _showsNextGame {
    final upcoming = widget.nextGame;
    if (upcoming == null) {
      return false;
    }
    final currentSessionId = widget.game.sessionId;
    if (currentSessionId == null) {
      return true;
    }
    return upcoming.sessionId != currentSessionId;
  }

  GameCompactInfoBarLayout get _infoBarLayout {
    return widget.variant == LiveTopSectionVariant.registration
        ? GameCompactInfoBarLayout.registrationOpen
        : GameCompactInfoBarLayout.live;
  }

  void _toggleNextGame() {
    setState(() => _nextGameExpanded = !_nextGameExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final showsLiveNextGame =
        widget.variant == LiveTopSectionVariant.livePlay && _showsNextGame;

    if (widget.variant == LiveTopSectionVariant.livePlay && !_expanded) {
      return const SizedBox.shrink();
    }

    if (showsLiveNextGame) {
      return TapRegion(
        onTapOutside: (_) {
          if (_nextGameExpanded) {
            setState(() => _nextGameExpanded = false);
          }
        },
        child: _LivePlayInfoCluster(
          game: widget.game,
          nextGame: widget.nextGame!,
          nextGameExpanded: _nextGameExpanded,
          onToggleNextGame: _toggleNextGame,
          showRule: widget.showRule,
          registeredCartelaNumbers: widget.nextRegisteredCartelaNumbers,
          detailsExpanded: _expanded,
          onToggleDetails: () => _setExpanded(!_expanded),
          myRegisteredCartelasCount: widget.myRegisteredCartelasCount,
        ),
      );
    }

    return _StandaloneInfoCluster(
      game: widget.game,
      showRule: widget.showRule,
      layout: _infoBarLayout,
      expanded: _expanded,
      onToggleDetails: () => _setExpanded(!_expanded),
      myRegisteredCartelasCount: widget.myRegisteredCartelasCount,
    );
  }
}

class _StandaloneInfoCluster extends StatelessWidget {
  const _StandaloneInfoCluster({
    required this.game,
    required this.showRule,
    required this.layout,
    required this.expanded,
    required this.onToggleDetails,
    this.myRegisteredCartelasCount,
  });

  final GameModel game;
  final bool showRule;
  final GameCompactInfoBarLayout layout;
  final bool expanded;
  final VoidCallback onToggleDetails;
  final int? myRegisteredCartelasCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBranding.panelBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: MasterDetailCollapseButton(
              expanded: expanded,
              onPressed: onToggleDetails,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? GameCompactInfoBar(
                    game: game,
                    showRule: showRule,
                    layout: layout,
                    embedded: true,
                    myRegisteredCartelasCount: myRegisteredCartelasCount,
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class _LivePlayInfoCluster extends StatelessWidget {
  const _LivePlayInfoCluster({
    required this.game,
    required this.nextGame,
    required this.nextGameExpanded,
    required this.onToggleNextGame,
    required this.showRule,
    required this.registeredCartelaNumbers,
    required this.detailsExpanded,
    required this.onToggleDetails,
    this.myRegisteredCartelasCount,
  });

  final GameModel game;
  final GameModel nextGame;
  final bool nextGameExpanded;
  final VoidCallback onToggleNextGame;
  final bool showRule;
  final List<int> registeredCartelaNumbers;
  final bool detailsExpanded;
  final VoidCallback onToggleDetails;
  final int? myRegisteredCartelasCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppBranding.statPillBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppBranding.panelBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NextGameQueueBanner(
                  game: nextGame,
                  expanded: nextGameExpanded,
                  onTap: onToggleNextGame,
                  embedded: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 2),
                child: MasterDetailCollapseButton(
                  expanded: detailsExpanded,
                  onPressed: onToggleDetails,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: nextGameExpanded
                ? _NextGameDetailPanel(
                    game: nextGame,
                    registeredCartelaNumbers: registeredCartelaNumbers,
                    embedded: true,
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppBranding.panelBorder(context).withValues(alpha: 0.65),
          ),
          GameCompactInfoBar(
            game: game,
            showRule: showRule,
            layout: GameCompactInfoBarLayout.live,
            embedded: true,
            myRegisteredCartelasCount: myRegisteredCartelasCount,
          ),
        ],
      ),
    );
  }
}

class _NextGameDetailPanel extends ConsumerWidget {
  const _NextGameDetailPanel({
    required this.game,
    required this.registeredCartelaNumbers,
    this.embedded = false,
  });

  final GameModel game;
  final List<int> registeredCartelaNumbers;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final localizedRuleName = game.localizedRuleName(ref);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game.isBonusLike) ...[
          BonusGameInfoStrip(game: game),
          VGap.xs,
        ] else if (game.isBigGame) ...[
          BigGameInfoStrip(game: game),
          VGap.xs,
        ],
        Text(
          localizedRuleName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        VGap.xs,
        Text(
          game.hasFreeEntry
              ? '${l10n.gameInfoEntry}: Free'
              : '${l10n.gameInfoEntry}: ${formatMoney(game.entryFee)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (registeredCartelaNumbers.isNotEmpty) ...[
          VGap.sm,
          Text(
            'Your next cartelas',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          VGap.xs,
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: registeredCartelaNumbers
                .map(
                  (number) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$number',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: content,
    );
  }
}
