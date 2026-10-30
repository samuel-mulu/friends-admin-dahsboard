import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/core/theme/app_spacing.dart';
import 'package:friends_bingo_app/src/core/utils/formatters.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_mark_color_provider.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_pattern_progress_overlay.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/blocked_cartela_reason_dialog.dart';
import 'cartela_number_badge.dart';
import 'cartela_number_dialog.dart';
import 'cartela_mark_color_dropdown.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_claim_button.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_ball_badge.dart';
import 'cartela_board_widget.dart';

class LiveCartelaCard extends StatelessWidget {
  const LiveCartelaCard({
    required this.gameCartela,
    required this.canClaimBingo,
    required this.isClaiming,
    required this.pendingReview,
    required this.manualMarkedNumbers,
    this.lastManualMarkedKey,
    required this.onMarkedNumberToggled,
    required this.onClaimBingo,
    this.showFinishedOutcome = false,
    this.freezeCartelaMarks = false,
    this.isOneAwayFromWin = false,
    this.hasLocalPatternComplete = false,
    this.isLateClaim = false,
    this.oneAwayCellIndexes = const {},
    this.winningPatternOverlay = const CartelaPatternProgressOverlay(),
    this.winningHighlightCells = const {},
    this.winningBallCellIndex,
    this.prizeAmount,
    this.showMarkColorPicker = true,
    this.blockedReasonCode,
    this.blockedServerReason,
    this.bingoLockListenable,
    this.decorativeMotionAllowedListenable,
    super.key,
  });

  final GameCartelaModel gameCartela;
  final bool canClaimBingo;
  final bool isClaiming;
  final bool pendingReview;
  final bool showFinishedOutcome;
  final bool freezeCartelaMarks;
  final bool isOneAwayFromWin;
  final bool hasLocalPatternComplete;
  final bool isLateClaim;
  final Set<int> oneAwayCellIndexes;
  final CartelaPatternProgressOverlay winningPatternOverlay;
  final Set<int> winningHighlightCells;
  final int? winningBallCellIndex;
  final String? prizeAmount;
  final bool showMarkColorPicker;
  final String? blockedReasonCode;
  final String? blockedServerReason;
  /// When set, BINGO button toggles from this notifier without rebuilding the card body.
  final ValueListenable<bool>? bingoLockListenable;
  /// When false (e.g. while scrolling), claim/one-away pulses pause so scroll stays calm.
  final ValueListenable<bool>? decorativeMotionAllowedListenable;
  final Set<String> manualMarkedNumbers;
  final String? lastManualMarkedKey;
  final void Function(GameCartelaModel cartela, String header, String value)
  onMarkedNumberToggled;
  final VoidCallback onClaimBingo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBlocked = gameCartela.status == GameCartelaStatus.blocked;
    final isWinner = gameCartela.isWinner;
    final readOnlyOutcome = showFinishedOutcome;
    final readOnlyMarks = freezeCartelaMarks || readOnlyOutcome;
    final trackingOverlay = !readOnlyOutcome || isWinner
        ? winningPatternOverlay
        : const CartelaPatternProgressOverlay();
    final isDark = theme.brightness == Brightness.dark;
    final headerOnColor = isBlocked
        ? theme.colorScheme.onError
        : isWinner
        ? Colors.white
        : isDark
        ? theme.colorScheme.onPrimary
        : AppBranding.brandPurple;
    final headerActionColor = isBlocked
        ? theme.colorScheme.onError
        : isWinner
        ? Colors.white
        : AppBranding.headerActionIcon(context);

    final showClaimReadyHighlight =
        hasLocalPatternComplete &&
        !isLateClaim &&
        canClaimBingo &&
        !isClaiming &&
        !isBlocked &&
        !readOnlyOutcome;

    final showOneAwayHighlight =
        isOneAwayFromWin &&
        !hasLocalPatternComplete &&
        !isLateClaim &&
        canClaimBingo &&
        !isClaiming &&
        !isBlocked &&
        !isWinner &&
        !readOnlyOutcome &&
        !showClaimReadyHighlight;

    return RepaintBoundary(
      child: _GreenClaimPulseWrapper(
      active: showClaimReadyHighlight || (isWinner && !isBlocked),
      motionAllowedListenable: decorativeMotionAllowedListenable,
      child: _OneAwayPulseWrapper(
        active: showOneAwayHighlight,
        motionAllowedListenable: decorativeMotionAllowedListenable,
        child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: theme.brightness == Brightness.dark
            ? null
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isBlocked
                ? theme.colorScheme.error.withValues(alpha: 0.75)
                : (isWinner
                    ? AppBranding.gold
                    : (theme.brightness == Brightness.dark
                        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
                        : AppBranding.panelBorder(context))),
            width: isBlocked || isWinner ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: isBlocked
                  ? BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.errorContainer.withValues(alpha: 0.22)
                          : theme.colorScheme.error.withValues(alpha: 0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                    )
                  : isWinner
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppBranding.feltGreen,
                          AppBranding.bingoFreeGreen,
                        ],
                      ),
                    )
                  : AppBranding.cartelaHeaderDecoration(
                      context,
                      isBlocked: isBlocked,
                      isWinner: isWinner,
                    ),
              child: Row(
                children: [
                  CartelaNumberTapTarget(
                    number: gameCartela.cartela.number,
                    child: CartelaNumberCompactBadge(
                      number: gameCartela.cartela.number,
                      isBlocked: isBlocked,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: isBlocked
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withValues(alpha: 0.45),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.block_rounded,
                                      size: 11,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'BLOCKED',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : isWinner
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  context.l10n.cartelaOutcomeValid,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            )
                          : isClaiming
                          ? Text(
                              context.l10n.gameCheckingTitle,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : headerOnColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            )
                          : readOnlyOutcome
                          ? Text(
                              context.l10n.cartelaOutcomeRegistered,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: headerOnColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            )
                          : _buildBingoClaimButton(
                              canClaimBase: canClaimBingo,
                              showReadyPulse: showClaimReadyHighlight,
                              isClaiming: isClaiming,
                            ),
                    ),
                  ),
                  if (isBlocked)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showBlockedCartelaReasonDialog(
                          context: context,
                          gameCartela: gameCartela,
                          reasonCode: blockedReasonCode,
                          serverReason: blockedServerReason,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    )
                  else if (showMarkColorPicker &&
                      !readOnlyMarks &&
                      !isBlocked &&
                      !isWinner) ...[
                    CartelaMarkColorDropdown(iconColor: headerActionColor),
                  ] else
                    const SizedBox(width: 4),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: readOnlyMarks && !isWinner && !isBlocked
                            ? 0.45
                            : 1,
                        child: _MarkedCartelaGrid(
                          gameCartela: gameCartela,
                          columns: gameCartela.cartela.columns,
                          manualMarkedNumbers: manualMarkedNumbers,
                          lastManualMarkedKey: lastManualMarkedKey,
                          oneAwayCellIndexes: oneAwayCellIndexes,
                          pulseOneAwayCells: showOneAwayHighlight,
                          decorativeMotionAllowedListenable:
                              decorativeMotionAllowedListenable,
                          winningPatternOverlay: trackingOverlay,
                          winningHighlightCells: winningHighlightCells,
                          winningBallCellIndex:
                              isWinner ? winningBallCellIndex : null,
                          interactionDisabled: isBlocked,
                          onMarkedNumberToggled: readOnlyMarks || isBlocked
                              ? (cartela, header, value) {}
                              : onMarkedNumberToggled,
                        ),
                      ),
                    ),
                    if (pendingReview && !isClaiming) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Under review',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (isWinner) ...[
                      const SizedBox(height: 3),
                      Text(
                        prizeAmount == null
                            ? context.l10n.cartelaOutcomeValid
                            : context.l10n.winningCartelasPrize(
                                formatMoney(prizeAmount!),
                              ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppBranding.balanceAccent(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ] else if (showFinishedOutcome) ...[
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.cartelaOutcomeNoWin,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildBingoClaimButton({
    required bool canClaimBase,
    required bool showReadyPulse,
    required bool isClaiming,
  }) {
    final lockListenable = bingoLockListenable;
    if (lockListenable == null) {
      return BingoClaimButton(
        canClaim: canClaimBase,
        showReadyPulse: showReadyPulse,
        isClaiming: isClaiming,
        onPressed: onClaimBingo,
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: lockListenable,
      builder: (context, locked, _) {
        return BingoClaimButton(
          canClaim: canClaimBase && !locked,
          showReadyPulse: showReadyPulse && !locked,
          isClaiming: isClaiming,
          onPressed: onClaimBingo,
        );
      },
    );
  }
}

class _MarkedCartelaGrid extends ConsumerWidget {
  const _MarkedCartelaGrid({
    required this.gameCartela,
    required this.columns,
    required this.manualMarkedNumbers,
    this.lastManualMarkedKey,
    required this.oneAwayCellIndexes,
    this.pulseOneAwayCells = false,
    this.decorativeMotionAllowedListenable,
    required this.winningPatternOverlay,
    this.winningHighlightCells = const {},
    this.winningBallCellIndex,
    this.interactionDisabled = false,
    required this.onMarkedNumberToggled,
  });

  final GameCartelaModel gameCartela;
  final List<List<String>> columns;
  final Set<String> manualMarkedNumbers;
  final String? lastManualMarkedKey;
  final Set<int> oneAwayCellIndexes;
  final bool pulseOneAwayCells;
  final ValueListenable<bool>? decorativeMotionAllowedListenable;
  final CartelaPatternProgressOverlay winningPatternOverlay;
  final Set<int> winningHighlightCells;
  final int? winningBallCellIndex;
  final bool interactionDisabled;
  final void Function(GameCartelaModel cartela, String header, String value)
  onMarkedNumberToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markColor = ref.watch(cartelaMarkColorProvider);
    final motionListenable = decorativeMotionAllowedListenable;

    final markedNumbers = <int>{};
    for (int col = 0; col < columns.length; col++) {
      if (col >= bingoColumnHeaders.length) continue;
      final header = bingoColumnHeaders[col];
      for (int row = 0; row < columns[col].length; row++) {
        final val = columns[col][row];
        final cellIdx = (row * 5) + col;
        final isMarked = isManuallyMarkedCell(
          manualMarkedNumbers: manualMarkedNumbers,
          header: header,
          value: val,
        ) || winningHighlightCells.contains(cellIdx);
        final number = int.tryParse(val) ?? 0;
        if (isMarked && number > 0) {
          markedNumbers.add(number);
        }
      }
    }

    int? lastMarkedNum;
    if (lastManualMarkedKey != null && lastManualMarkedKey!.contains(':')) {
      final parts = lastManualMarkedKey!.split(':');
      if (parts.length == 2) {
        lastMarkedNum = int.tryParse(parts[1]);
      }
    }

    int? winningBallNum;
    if (winningBallCellIndex != null) {
      final row = winningBallCellIndex! ~/ 5;
      final col = winningBallCellIndex! % 5;
      if (col < columns.length && row < columns[col].length) {
        winningBallNum = int.tryParse(columns[col][row]);
      }
    }

    Widget buildBoard(CartelaVisualTier visualTier) {
      return CartelaBoardWidget(
        cartela: gameCartela.cartela,
        markedCells: markedNumbers,
        lastMarkedNumber: lastMarkedNum,
        winningBallNumber: winningBallNum,
        oneAwayCellIndexes: oneAwayCellIndexes,
        patternOverlay: winningPatternOverlay,
        markColor: markColor,
        interactive: !interactionDisabled,
        showHeader: false,
        expandToFill: true,
        pulseOneAwayCells: pulseOneAwayCells,
        decorativeMotionAllowedListenable: decorativeMotionAllowedListenable,
        visualTier: visualTier,
        onCellTapped: interactionDisabled
            ? null
            : (number) {
                final header = BingoBallBadge.getLetter(number);
                onMarkedNumberToggled(gameCartela, header, number.toString());
              },
      );
    }

    if (motionListenable == null) {
      return buildBoard(CartelaVisualTier.idle);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: motionListenable,
      builder: (context, scrollIdle, _) {
        final visualTier = scrollIdle
            ? CartelaVisualTier.idle
            : CartelaVisualTier.scrolling;
        return buildBoard(visualTier);
      },
    );
  }
}

class _GreenClaimPulseWrapper extends StatefulWidget {
  const _GreenClaimPulseWrapper({
    required this.active,
    required this.child,
    this.motionAllowedListenable,
  });

  final bool active;
  final Widget child;
  final ValueListenable<bool>? motionAllowedListenable;

  @override
  State<_GreenClaimPulseWrapper> createState() => _GreenClaimPulseWrapperState();
}

class _GreenClaimPulseWrapperState extends State<_GreenClaimPulseWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    widget.motionAllowedListenable?.addListener(_syncAnimation);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _GreenClaimPulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionAllowedListenable != widget.motionAllowedListenable) {
      oldWidget.motionAllowedListenable?.removeListener(_syncAnimation);
      widget.motionAllowedListenable?.addListener(_syncAnimation);
    }
    if (oldWidget.active != widget.active ||
        oldWidget.motionAllowedListenable != widget.motionAllowedListenable) {
      _syncAnimation();
    }
  }

  bool get _motionAllowed => widget.motionAllowedListenable?.value ?? true;

  void _syncAnimation() {
    if (!mounted) {
      return;
    }
    final shouldPulse = widget.active && _motionAllowed;
    if (shouldPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
      setState(() {});
      return;
    }
    _controller
      ..stop()
      ..value = 0;
    setState(() {});
  }

  @override
  void dispose() {
    widget.motionAllowedListenable?.removeListener(_syncAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || !_motionAllowed) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppBranding.feltGreen.withValues(alpha: 0.35 + (t * 0.65)),
              width: 1.2 + (t * 2.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.feltGreen.withValues(alpha: 0.12 + (t * 0.38)),
                blurRadius: 6 + (t * 10),
                spreadRadius: 0.5 + (t * 1.6),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _OneAwayPulseWrapper extends StatefulWidget {
  const _OneAwayPulseWrapper({
    required this.active,
    required this.child,
    this.motionAllowedListenable,
  });

  final bool active;
  final Widget child;
  final ValueListenable<bool>? motionAllowedListenable;

  @override
  State<_OneAwayPulseWrapper> createState() => _OneAwayPulseWrapperState();
}

class _OneAwayPulseWrapperState extends State<_OneAwayPulseWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    widget.motionAllowedListenable?.addListener(_syncAnimation);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _OneAwayPulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionAllowedListenable != widget.motionAllowedListenable) {
      oldWidget.motionAllowedListenable?.removeListener(_syncAnimation);
      widget.motionAllowedListenable?.addListener(_syncAnimation);
    }
    if (oldWidget.active != widget.active ||
        oldWidget.motionAllowedListenable != widget.motionAllowedListenable) {
      _syncAnimation();
    }
  }

  bool get _motionAllowed => widget.motionAllowedListenable?.value ?? true;

  void _syncAnimation() {
    if (!mounted) {
      return;
    }
    final shouldPulse = widget.active && _motionAllowed;
    if (shouldPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
      setState(() {});
      return;
    }
    _controller
      ..stop()
      ..value = 0;
    setState(() {});
  }

  @override
  void dispose() {
    widget.motionAllowedListenable?.removeListener(_syncAnimation);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || !_motionAllowed) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppBranding.oneAwayRedBorder(t),
              width: 1.2 + (t * 2.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.oneAwayRedShadow(t),
                blurRadius: 6 + (t * 10),
                spreadRadius: 0.5 + (t * 1.6),
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
