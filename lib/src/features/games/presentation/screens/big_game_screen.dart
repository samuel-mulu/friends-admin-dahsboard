import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../domain/game_category_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import '../../../../core/time/countdown_target_tracker.dart';
import '../../../../core/time/server_clock_provider.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';
import '../providers/current_big_game_provider.dart';
import '../utils/big_game_countdown.dart';
import 'live_game_screen.dart';

class BigGameScreen extends ConsumerStatefulWidget {
  const BigGameScreen({super.key});

  @override
  ConsumerState<BigGameScreen> createState() => _BigGameScreenState();
}

class _BigGameScreenState extends ConsumerState<BigGameScreen>
    with WidgetsBindingObserver {
  Timer? _countdownTimer;
  final _countdownTracker = CountdownTargetTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    unawaited(_syncServerClock());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(currentBigGameProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        _countdownTimer?.cancel();
        _countdownTimer = null;
        break;
      case AppLifecycleState.resumed:
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() {});
          }
        });
        unawaited(_syncServerClock(snap: true));
        unawaited(ref.read(currentBigGameProvider.notifier).refresh());
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _syncServerClock({bool snap = false}) async {
    try {
      final timing = await ref.read(gamesRepositoryProvider).getTimeConfig();
      final serverNow = timing.serverNow;
      if (serverNow != null) {
        ref.read(serverClockProvider).sync(serverNow, snap: snap);
      }
    } catch (_) {
      // Big Game countdown falls back to device time when sync fails.
    }
  }

  Future<void> _handleRefresh() async {
    await _syncServerClock(snap: true);
    await ref.read(currentBigGameProvider.notifier).refresh();
  }

  DateTime _now(ServerClockService clock) {
    return clock.isSynced ? clock.nowLocal() : DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final bigGameAsync = ref.watch(currentBigGameProvider);
    final clock = ref.watch(serverClockProvider);

    return Theme(
      data: GameCategoryTheme.bigGameTheme(context),
      child: bigGameAsync.when(
        loading: () => const _BigGameLoadingView(),
        error: (error, _) => _BigGameErrorView(
          message: error.toString(),
          onRetry: _handleRefresh,
        ),
        data: (game) {
          if (game == null) {
            return _BigGameEmptyView(onRefresh: _handleRefresh);
          }

          final phase = resolveBigGamePhase(game, now: _now(clock));
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: switch (phase) {
              BigGamePhase.beforeRegistrationOpens => _BigGameScheduledView(
                game: game,
                clock: clock,
                countdownTracker: _countdownTracker,
                countdownTarget: game.registrationOpensAt,
                title: context.l10n.bigGameScheduledTitle,
                countdownLabel: context.l10n.bigGameRegistrationOpensIn,
              ),
              BigGamePhase.registrationOpen => _BigGameLiveEmbed(
                game: game,
                clock: clock,
                countdownTracker: _countdownTracker,
                headerTitle: context.l10n.bigGameRegistrationOpenTitle,
                countdownLabel: context.l10n.bigGamePlayStartsIn,
                countdownTarget: game.scheduledStartAt,
                showBanner: true,
              ),
              BigGamePhase.waitingToPlay => _BigGameWaitingView(
                game: game,
                onRefresh: _handleRefresh,
              ),
              BigGamePhase.live ||
              BigGamePhase.finishedReview ||
              BigGamePhase.cancelled => _BigGameLiveEmbed(
                game: game,
                clock: clock,
                countdownTracker: _countdownTracker,
                headerTitle: context.l10n.drawerBigGame,
                showCountdown: false,
              ),
              BigGamePhase.none => _BigGameEmptyView(onRefresh: _handleRefresh),
            },
          );
        },
      ),
    );
  }
}

class _BigGameLoadingView extends StatelessWidget {
  const _BigGameLoadingView();

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
              child: _BigGamePremiumCard(
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

class _BigGameEmptyView extends StatelessWidget {
  const _BigGameEmptyView({required this.onRefresh});

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
                  child: _BigGamePremiumCard(
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

class _BigGameErrorView extends StatelessWidget {
  const _BigGameErrorView({required this.message, required this.onRetry});

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

class _BigGameScheduledView extends StatelessWidget {
  const _BigGameScheduledView({
    required this.game,
    required this.clock,
    required this.countdownTracker,
    required this.countdownTarget,
    required this.title,
    required this.countdownLabel,
  });

  final GameModel game;
  final ServerClockService clock;
  final CountdownTargetTracker countdownTracker;
  final DateTime? countdownTarget;
  final String title;
  final String countdownLabel;

  @override
  Widget build(BuildContext context) {
    final countdown = formatBigGameCountdown(countdownTarget, clock: clock);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _BigGamePremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BigGameHeader(title: title),
                  const SizedBox(height: AppSpacing.md),
                  _BigGameCountdownRow(label: countdownLabel, value: countdown),
                  const SizedBox(height: AppSpacing.lg),
                  _BigGameMetadataSection(game: game),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BigGameWaitingView extends StatelessWidget {
  const _BigGameWaitingView({required this.game, required this.onRefresh});

  final GameModel game;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            child: _BigGamePremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BigGameHeader(title: l10n.bigGameReadyTitle),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.bigGameWaitingBody,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _BigGameMetadataSection(game: game, compact: true),
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

class _BigGameLiveEmbed extends StatelessWidget {
  const _BigGameLiveEmbed({
    required this.game,
    required this.clock,
    required this.countdownTracker,
    this.headerTitle,
    this.countdownLabel,
    this.countdownTarget,
    this.showCountdown = true,
    this.showBanner = true,
  }) : metadataCompact = true;

  final GameModel game;
  final ServerClockService clock;
  final CountdownTargetTracker countdownTracker;
  final String? headerTitle;
  final String? countdownLabel;
  final DateTime? countdownTarget;
  final bool showCountdown;
  final bool metadataCompact;
  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    final sessionId = game.sessionId;
    if (sessionId == null) {
      return _BigGameEmptyView(onRefresh: () async {});
    }

    final countdown = showCountdown && countdownTarget != null
        ? formatBigGameCountdown(countdownTarget, clock: clock)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBanner && headerTitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: _BigGamePremiumCard(
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BigGameHeader(title: headerTitle!, compact: true),
                  if (countdown != null && countdownLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _BigGameCountdownRow(
                      label: countdownLabel!,
                      value: countdown,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _BigGameMetadataSection(game: game, compact: metadataCompact),
                ],
              ),
            ),
          ),
        Expanded(
          child: LiveGameScreen(
            key: ValueKey('big-game-live-$sessionId'),
            gameId: sessionId,
            showAppBar: false,
            initialGame: game,
            embedded: true,
          ),
        ),
      ],
    );
  }
}

class _BigGamePremiumCard extends StatelessWidget {
  const _BigGamePremiumCard({required this.child, this.compact = false});

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

class _BigGameHeader extends StatelessWidget {
  const _BigGameHeader({required this.title, this.compact = false});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.emoji_events_rounded,
          color: AppBranding.gold,
          size: compact ? 22 : 28,
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
      ],
    );
  }
}

class _BigGameCountdownRow extends StatelessWidget {
  const _BigGameCountdownRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppBranding.casinoPurpleDeep,
      height: 1.25,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppBranding.gold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: AppBranding.gold.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                value,
                style: valueStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BigGameMetadataSection extends StatelessWidget {
  const _BigGameMetadataSection({required this.game, this.compact = false});

  final GameModel game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <_MetadataRow>[
      if (game.fixedPrizeAmount != null)
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
          if (i > 0) const Divider(height: 20),
          rows[i],
        ],
      ],
    );
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
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
