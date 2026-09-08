import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../../data/models/game_model.dart';
import '../utils/big_game_countdown.dart';

/// Non-live Big Game phase chrome (schedule / waiting / empty / shared cards).
/// Live PLAYING embeds via [BigGameLiveHost], not these views.

class BigGameLoadingView extends StatelessWidget {
  const BigGameLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: BigGamePremiumCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 48,
                      color: AppBranding.gold,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SizedBox(
                      height: 32,
                      child: FriendsBingoLoader.inline(compact: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BigGameEmptyView extends StatelessWidget {
  const BigGameEmptyView({required this.onRefresh, super.key});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: BigGamePremiumCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 52,
                          color: AppBranding.gold,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.bigGameNoScheduledTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.bigGameNoScheduledBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BigGameErrorView extends StatelessWidget {
  const BigGameErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => unawaited(onRetry()),
                    child: Text(context.l10n.gameHistoryRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BigGameScheduledView extends StatelessWidget {
  const BigGameScheduledView({
    required this.game,
    required this.clock,
    required this.countdownTarget,
    required this.title,
    required this.countdownLabel,
    this.onCountdownExpired,
    super.key,
  });

  final GameModel game;
  final ServerClockService clock;
  final DateTime? countdownTarget;
  final String title;
  final String countdownLabel;
  final Future<void> Function()? onCountdownExpired;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: BigGameCollapsibleBanner(
              game: game,
              title: title,
              countdownLabel: countdownLabel,
              countdownTarget: countdownTarget,
              clock: clock,
              onCountdownExpired: onCountdownExpired,
              compact: false,
            ),
          ),
        ),
      ],
    );
  }
}

class BigGameWaitingView extends StatelessWidget {
  const BigGameWaitingView({
    required this.game,
    required this.onRefresh,
    super.key,
  });

  final GameModel game;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final held = game.heldWaitingForLiveSlot;
    final blockerCode = game.blockingLiveGame?.staticCode.trim();
    final waitingBody = held
        ? (blockerCode != null && blockerCode.isNotEmpty
              ? l10n.bigGameWaitingBodyWithBlocker(blockerCode)
              : l10n.bigGameWaitingBody)
        : l10n.bigGameStartingSoonBody;
    final myCartelas =
        game.registeredCartelasSummary
            ?.where((item) => item.isMine)
            .map((item) => item.cartelaNumber)
            .toList(growable: false) ??
        const <int>[];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: BigGamePremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BigGameHeader(title: l10n.bigGameReadyTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    waitingBody,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BigGameCollapsibleDetails(
                    game: game,
                    compact: true,
                    initiallyExpanded: false,
                  ),
                  if (myCartelas.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.bigGameYourCartelas,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final number in myCartelas)
                          Chip(
                            label: Text('#$number'),
                            backgroundColor: AppBranding.gold.withValues(
                              alpha: 0.15,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BigGamePremiumCard extends StatelessWidget {
  const BigGamePremiumCard({required this.child, this.compact = false, super.key});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppBranding.casinoPurpleDeep, AppBranding.liveCardDark]
              : const [Color(0xFFF3E8FF), Color(0xFFFFF9E8)],
        ),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: isDark ? 0.45 : 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppBranding.brandPurple.withValues(alpha: 0.12),
            blurRadius: compact ? 8 : 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class BigGameCollapsibleBanner extends StatefulWidget {
  const BigGameCollapsibleBanner({
    required this.game,
    required this.title,
    required this.clock,
    this.countdownLabel,
    this.countdownTarget,
    this.onCountdownExpired,
    this.compact = true,
    super.key,
  });

  final GameModel game;
  final String title;
  final ServerClockService clock;
  final String? countdownLabel;
  final DateTime? countdownTarget;
  final Future<void> Function()? onCountdownExpired;
  final bool compact;

  @override
  State<BigGameCollapsibleBanner> createState() =>
      _BigGameCollapsibleBannerState();
}

class _BigGameCollapsibleBannerState extends State<BigGameCollapsibleBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final showCountdown =
        widget.countdownTarget != null && widget.countdownLabel != null;

    return BigGamePremiumCard(
      compact: !_expanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigGameHeader(
            title: widget.title,
            compact: widget.compact || !_expanded,
            trailing: _DetailsToggle(
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (widget.game.hasMultipleRounds) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.bigGameRoundOf(
                widget.game.displayRoundIndex,
                widget.game.displayRoundCount,
              ),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppBranding.brandPurple,
              ),
            ),
          ],
          if (showCountdown) ...[
            SizedBox(height: _expanded ? AppSpacing.sm : AppSpacing.xs),
            _IsolatedBigGameCountdown(
              label: widget.countdownLabel!,
              target: widget.countdownTarget,
              clock: widget.clock,
              onExpired: widget.onCountdownExpired,
              compact: !_expanded,
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.md),
            BigGameMetadataSection(game: widget.game, compact: widget.compact),
          ],
        ],
      ),
    );
  }
}

class BigGameCollapsibleDetails extends StatefulWidget {
  const BigGameCollapsibleDetails({
    required this.game,
    this.compact = false,
    this.initiallyExpanded = false,
    super.key,
  });

  final GameModel game;
  final bool compact;
  final bool initiallyExpanded;

  @override
  State<BigGameCollapsibleDetails> createState() =>
      _BigGameCollapsibleDetailsState();
}

class _BigGameCollapsibleDetailsState extends State<BigGameCollapsibleDetails> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _DetailsToggle(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          BigGameMetadataSection(game: widget.game, compact: widget.compact),
        ],
      ],
    );
  }
}

class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final label = expanded ? l10n.bigGameHideDetails : l10n.bigGameShowDetails;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppBranding.casinoPurpleDeep,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppBranding.casinoPurpleDeep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BigGameHeader extends StatelessWidget {
  const BigGameHeader({
    required this.title,
    this.compact = false,
    this.trailing,
    super.key,
  });

  final String title;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.emoji_events_rounded,
          color: AppBranding.gold,
          size: compact ? 20 : 28,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style:
                (compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _IsolatedBigGameCountdown extends StatefulWidget {
  const _IsolatedBigGameCountdown({
    required this.label,
    required this.target,
    required this.clock,
    this.onExpired,
    this.compact = false,
  });

  final String label;
  final DateTime? target;
  final ServerClockService clock;
  final Future<void> Function()? onExpired;
  final bool compact;

  @override
  State<_IsolatedBigGameCountdown> createState() =>
      _IsolatedBigGameCountdownState();
}

class _IsolatedBigGameCountdownState extends State<_IsolatedBigGameCountdown> {
  Timer? _timer;
  bool _expiredNotified = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _IsolatedBigGameCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _expiredNotified = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final target = widget.target;
    if (target == null || _expiredNotified || widget.onExpired == null) {
      return;
    }
    final value = formatBigGameCountdown(target, clock: widget.clock);
    if (value == '0 sec') {
      _expiredNotified = true;
      unawaited(widget.onExpired!.call());
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = formatBigGameCountdown(widget.target, clock: widget.clock);
    return _BigGameCountdownRow(
      label: widget.label,
      value: value,
      compact: widget.compact,
    );
  }
}

class _BigGameCountdownRow extends StatelessWidget {
  const _BigGameCountdownRow({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle =
        (compact ? theme.textTheme.labelLarge : theme.textTheme.titleSmall)
            ?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppBranding.casinoPurpleDeep,
              height: 1.2,
            );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppBranding.gold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppBranding.gold.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.sm : AppSpacing.md,
              vertical: compact ? 4 : AppSpacing.sm,
            ),
            child: Text(value, style: valueStyle, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

class BigGameMetadataSection extends StatelessWidget {
  const BigGameMetadataSection({
    required this.game,
    this.compact = false,
    super.key,
  });

  final GameModel game;
  final bool compact;

  Map<int, BigGameFinishedRoundSummary> get _finishedByRound {
    final map = <int, BigGameFinishedRoundSummary>{};
    for (final round in game.finishedRounds ?? const []) {
      map[round.roundIndex] = round;
    }
    final previous = game.previousRound;
    if (previous != null &&
        previous.winners.isNotEmpty &&
        !map.containsKey(previous.roundIndex)) {
      map[previous.roundIndex] = BigGameFinishedRoundSummary(
        sessionId: previous.sessionId,
        roundIndex: previous.roundIndex,
        status: previous.status,
        playCode: previous.playCode,
        finishedAt: previous.finishedAt,
        winners: previous.winners,
      );
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roundPrize = game.effectiveRoundPrizeAmount;
    final prizes = game.roundPrizes;
    final activeRound = game.displayRoundIndex;
    final finishedByRound = _finishedByRound;
    final rows = <Widget>[
      if (game.hasMultipleRounds)
        _MetadataRow(
          label: l10n.bigGameRoundOf(
            game.displayRoundIndex,
            game.displayRoundCount,
          ),
          value: '',
          labelOnly: true,
        ),
      if (game.fixedPrizeAmount != null)
        _MetadataRow(
          label: l10n.bigGameTotalPrize,
          value: formatMoney(game.fixedPrizeAmount!),
        ),
      if (prizes != null && prizes.length > 1)
        for (var i = 0; i < prizes.length; i++)
          _MetadataRow(
            label: l10n.bigGameRoundPrize(i + 1),
            value: formatMoney(prizes[i]),
            emphasize: i + 1 == activeRound,
            finished: i + 1 < activeRound,
            subtitle: _winnerSubtitle(
              l10n,
              finishedByRound[i + 1],
              isFinished: i + 1 < activeRound,
            ),
          )
      else if (roundPrize != null)
        _MetadataRow(
          label: l10n.bigGameThisRoundPrize,
          value: formatMoney(roundPrize),
          emphasize: true,
        )
      else if (game.fixedPrizeAmount != null && !game.hasMultipleRounds)
        _MetadataRow(
          label: l10n.bigGameFixedPrize,
          value: formatMoney(game.fixedPrizeAmount!),
        ),
      _MetadataRow(
        label: l10n.bigGameEntryFee,
        value: formatMoney(game.entryFee),
      ),
      if (game.scheduledStartAt != null)
        _MetadataRow(
          label: l10n.bigGamePlayStartTime,
          value: _formatLocalDateTime(game.scheduledStartAt!),
        ),
      if (!compact && game.maxCartelasPerPlayer != null)
        _MetadataRow(
          label: l10n.bigGameMaxCartelas,
          value: game.maxCartelasPerPlayer.toString(),
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          rows[i],
        ],
      ],
    );
  }

  String? _winnerSubtitle(
    dynamic l10n,
    BigGameFinishedRoundSummary? round, {
    required bool isFinished,
  }) {
    if (!isFinished || round == null) {
      return null;
    }
    if (round.status == GameStatus.noWinner || round.winners.isEmpty) {
      return l10n.sessionResultsNoWinners as String;
    }
    final names = round.winners
        .map((winner) => winner.fullName.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    if (names.isEmpty) {
      return l10n.sessionResultsNoWinners as String;
    }
    return 'Won by ${names.join(', ')}';
  }

  String _formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '$hour:$minute $ampm';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    this.labelOnly = false,
    this.emphasize = false,
    this.finished = false,
    this.subtitle,
  });

  final String label;
  final String value;
  final bool labelOnly;
  final bool emphasize;
  final bool finished;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (labelOnly) {
      return Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      );
    }

    final accent = isDark ? AppBranding.gold : AppBranding.brandPurple;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: emphasize
          ? accent
          : finished
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
              : theme.colorScheme.onSurfaceVariant,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: emphasize
          ? accent
          : finished
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.78)
              : null,
    );

    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(value, style: valueStyle),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: finished
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85)
                  : accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );

    if (!emphasize) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.75 : 0.55),
          width: 1.5,
        ),
      ),
      child: row,
    );
  }
}
