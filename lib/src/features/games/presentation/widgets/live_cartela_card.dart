import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/game_cartela_model.dart';
import '../../domain/cartela_mark_color.dart';
import '../providers/cartela_mark_color_provider.dart';
import '../utils/cartela_board_layout.dart';
import '../utils/cartela_mark_helpers.dart';
import '../utils/cartela_pattern_progress_overlay.dart';
import 'blocked_cartela_reason_dialog.dart';
import 'cartela_pattern_progress_painter.dart';
import 'cartela_number_badge.dart';

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
    this.onClearMarks,
    this.showFinishedOutcome = false,
    this.freezeCartelaMarks = false,
    this.isOneAwayFromWin = false,
    this.hasLocalPatternComplete = false,
    this.oneAwayCellIndexes = const {},
    this.winningPatternOverlay = const CartelaPatternProgressOverlay(),
    this.winningHighlightCells = const {},
    this.winningBallCellIndex,
    this.prizeAmount,
    this.showMarkColorPicker = true,
    this.blockedReasonCode,
    this.blockedServerReason,
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
  final Set<int> oneAwayCellIndexes;
  final CartelaPatternProgressOverlay winningPatternOverlay;
  final Set<int> winningHighlightCells;
  final int? winningBallCellIndex;
  final String? prizeAmount;
  final bool showMarkColorPicker;
  final String? blockedReasonCode;
  final String? blockedServerReason;
  final Set<String> manualMarkedNumbers;
  final String? lastManualMarkedKey;
  final void Function(GameCartelaModel cartela, String header, String value)
  onMarkedNumberToggled;
  final VoidCallback onClaimBingo;
  final VoidCallback? onClearMarks;

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
    final canClearMarks =
        onClearMarks != null &&
        !readOnlyMarks &&
        !isBlocked &&
        !isWinner &&
        !isClaiming &&
        manualMarkedNumbers.isNotEmpty;
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
        canClaimBingo &&
        !isClaiming &&
        !isBlocked &&
        !readOnlyOutcome;

    return _GreenClaimPulseWrapper(
      active: showClaimReadyHighlight || (isWinner && !isBlocked),
      child: _OneAwayPulseWrapper(
        active:
            isOneAwayFromWin &&
            !canClaimBingo &&
            !isBlocked &&
            !isWinner &&
            !readOnlyOutcome,
        child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: theme.brightness == Brightness.dark
            ? null
            : AppBranding.panelBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
                : AppBranding.panelBorder(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: isBlocked
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.error.withValues(alpha: 0.92),
                          theme.colorScheme.error,
                        ],
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
                  if (isBlocked || isWinner)
                    CartelaNumberHeaderLabel(
                      number: gameCartela.cartela.number,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: headerOnColor,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  else
                    CartelaNumberCompactCircleBadge(
                      number: gameCartela.cartela.number,
                    ),
                  Expanded(
                    child: Center(
                      child: isBlocked
                          ? Text(
                              'BLOCKED',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: headerOnColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            )
                          : isWinner
                          ? Text(
                              context.l10n.cartelaOutcomeValid,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: headerOnColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
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
                          : _BingoButton(
                              canClaim: canClaimBingo,
                              showReadyPulse: showClaimReadyHighlight,
                              isClaiming: isClaiming,
                              onPressed: onClaimBingo,
                            ),
                    ),
                  ),
                  if (isBlocked)
                    IconButton(
                      onPressed: () => showBlockedCartelaReasonDialog(
                        context: context,
                        gameCartela: gameCartela,
                        reasonCode: blockedReasonCode,
                        serverReason: blockedServerReason,
                      ),
                      tooltip: context.l10n.cartelaBlockedInfoTooltip,
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: headerOnColor,
                      ),
                    )
                  else if (showMarkColorPicker &&
                      !readOnlyMarks &&
                      !isBlocked &&
                      !isWinner) ...[
                    if (canClearMarks)
                      _ClearMarksButton(
                        iconColor: headerActionColor,
                        onPressed: onClearMarks!,
                      ),
                    _CartelaMarkColorDropdown(iconColor: headerActionColor),
                  ] else
                    const SizedBox(width: 4),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 3),
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
    );
  }
}

class _BingoButton extends StatefulWidget {
  const _BingoButton({
    required this.canClaim,
    required this.showReadyPulse,
    required this.isClaiming,
    required this.onPressed,
  });

  final bool canClaim;
  final bool showReadyPulse;
  final bool isClaiming;
  final VoidCallback onPressed;

  @override
  State<_BingoButton> createState() => _BingoButtonState();
}

class _BingoButtonState extends State<_BingoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _BingoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canClaim != widget.canClaim ||
        oldWidget.showReadyPulse != widget.showReadyPulse ||
        oldWidget.isClaiming != widget.isClaiming) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.showReadyPulse && !widget.isClaiming) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = SizedBox(
      height: 22,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppBranding.goldAccent,
          foregroundColor: AppBranding.brandPurple,
          disabledBackgroundColor: isDark
              ? Colors.white24
              : AppBranding.lightOnDisabled.withValues(alpha: 0.25),
          disabledForegroundColor: isDark
              ? Colors.white54
              : AppBranding.lightOnDisabled,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: widget.canClaim && !widget.isClaiming ? widget.onPressed : null,
        child: widget.isClaiming
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'BINGO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );

    if (!widget.showReadyPulse || widget.isClaiming) {
      return button;
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Transform.scale(
          scale: 1 + (t * 0.05),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppBranding.feltGreen.withValues(alpha: 0.2 + (t * 0.5)),
                  blurRadius: 4 + (t * 8),
                  spreadRadius: t * 0.8,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: button,
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
  final CartelaPatternProgressOverlay winningPatternOverlay;
  final Set<int> winningHighlightCells;
  final int? winningBallCellIndex;
  final bool interactionDisabled;
  final void Function(GameCartelaModel cartela, String header, String value)
  onMarkedNumberToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final markColor = ref.watch(cartelaMarkColorProvider);

    return Column(
      children: [
        Row(
          children: List.generate(bingoColumnHeaders.length, (index) {
            final header = bingoColumnHeaders[index];
            return Expanded(
              child: Text(
                header,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: CartelaBoardLayout.liveHeaderFontSize,
                  fontWeight: FontWeight.w900,
                  color: AppBranding.bingoColumnColor(header),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: CartelaBoardLayout.headerToGridGap),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppBranding.cartelaBoardBackground(context),
              borderRadius:
                  BorderRadius.circular(CartelaBoardLayout.boardBorderRadius),
              border: isDark
                  ? null
                  : Border.all(
                      color: AppBranding.lightOutline.withValues(alpha: 0.72),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CartelaBoardLayout.boardPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: List.generate(5, (rowIndex) {
                          return Expanded(
                            child: Row(
                              children: List.generate(
                                bingoColumnHeaders.length,
                                (columnIndex) {
                                  final value =
                                      columns[columnIndex].length > rowIndex
                                      ? columns[columnIndex][rowIndex]
                                      : '';
                                  final header =
                                      bingoColumnHeaders[columnIndex];
                                  final cellIndex =
                                      (rowIndex * 5) + columnIndex;
                                  final isMarked = isManuallyMarkedCell(
                                        manualMarkedNumbers: manualMarkedNumbers,
                                        header: header,
                                        value: value,
                                      ) ||
                                      winningHighlightCells.contains(cellIndex);
                                  final isLastMarked = isLastManuallyMarkedCell(
                                    lastManualMarkedKey: lastManualMarkedKey,
                                    header: header,
                                    value: value,
                                  );
                                  final isFree = value == 'FREE';
                                  final isWinningBall =
                                      winningBallCellIndex == cellIndex;

                                  return Expanded(
                                    child: _CartelaGridCell(
                                      value: value,
                                      isMarked: isMarked,
                                      isLastMarked: isLastMarked,
                                      isFree: isFree,
                                      isWinningBall: isWinningBall,
                                      isOneAwayTarget: oneAwayCellIndexes
                                          .contains(cellIndex),
                                      markColor: markColor,
                                      interactionDisabled: interactionDisabled,
                                      onTap: isFree || interactionDisabled
                                          ? null
                                          : () => onMarkedNumberToggled(
                                              gameCartela,
                                              header,
                                              value,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      if (!winningPatternOverlay.isEmpty)
                        IgnorePointer(
                          child: CustomPaint(
                            painter: CartelaPatternProgressPainter(
                              overlay: winningPatternOverlay,
                              cellInset: CartelaBoardLayout.cellPadding,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClearMarksButton extends StatelessWidget {
  const _ClearMarksButton({
    required this.iconColor,
    required this.onPressed,
  });

  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: context.l10n.cartelaClearMarks,
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.backspace_outlined,
        size: 18,
        color: iconColor,
      ),
    );
  }
}

class _CartelaMarkColorDropdown extends ConsumerWidget {
  const _CartelaMarkColorDropdown({required this.iconColor});

  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(cartelaMarkColorProvider);
    final selectedPalette = CartelaMarkColorPalette.forColor(selected);

    return PopupMenuButton<CartelaMarkColor>(
      tooltip: l10n.cartelaMarkColorMenu,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (color) =>
          ref.read(cartelaMarkColorProvider.notifier).setColor(color),
      itemBuilder: (context) {
        return CartelaMarkColor.values
            .map((color) {
              final palette = CartelaMarkColorPalette.forColor(color);
              final label = switch (color) {
                CartelaMarkColor.green => l10n.cartelaMarkColorGreen,
                CartelaMarkColor.red => l10n.cartelaMarkColorRed,
                CartelaMarkColor.yellow => l10n.cartelaMarkColorYellow,
                CartelaMarkColor.blue => l10n.cartelaMarkColorBlue,
              };

              return PopupMenuItem<CartelaMarkColor>(
                value: color,
                height: 36,
                child: Row(
                  children: [
                    _CartelaMarkColorSwatch(
                      color: palette.swatch,
                      selected: color == selected,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: color == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (color == selected)
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CartelaMarkColorSwatch(
              color: selectedPalette.swatch,
              selected: true,
              size: 16,
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartelaMarkColorSwatch extends StatelessWidget {
  const _CartelaMarkColorSwatch({
    required this.color,
    required this.selected,
    required this.size,
  });

  final Color color;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
            width: selected ? 1.8 : 1,
          ),
        ),
      ),
    );
  }
}

class _CartelaGridCell extends StatelessWidget {
  const _CartelaGridCell({
    required this.value,
    required this.isMarked,
    required this.isLastMarked,
    required this.isFree,
    this.isWinningBall = false,
    required this.isOneAwayTarget,
    required this.markColor,
    this.interactionDisabled = false,
    required this.onTap,
  });

  final String value;
  final bool isMarked;
  final bool isLastMarked;
  final bool isFree;
  final bool isWinningBall;
  final bool isOneAwayTarget;
  final CartelaMarkColor markColor;
  final bool interactionDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayValue = isFree ? 'F' : value;

    final Color fillColor;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color textColor;

    if (isFree) {
      fillColor = AppBranding.bingoFreeGreen;
      borderColor = Colors.white.withValues(alpha: 0.22);
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: AppBranding.bingoFreeGreen.withValues(alpha: 0.55),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isWinningBall) {
      fillColor = AppBranding.gold;
      borderColor = AppBranding.goldDark;
      textColor = AppBranding.casinoPurpleDeep;
      shadows = [
        BoxShadow(
          color: AppBranding.gold.withValues(alpha: 0.72),
          blurRadius: 12,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isOneAwayTarget) {
      fillColor = theme.colorScheme.error;
      borderColor = Colors.white.withValues(alpha: 0.82);
      textColor = theme.colorScheme.onError;
      shadows = [
        BoxShadow(
          color: theme.colorScheme.error.withValues(alpha: 0.68),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ];
    } else if (isLastMarked) {
      fillColor = AppBranding.gold;
      borderColor = AppBranding.goldDark;
      textColor = AppBranding.casinoPurpleDeep;
      shadows = [
        BoxShadow(
          color: AppBranding.gold.withValues(alpha: 0.72),
          blurRadius: 12,
          spreadRadius: 0.5,
        ),
      ];
    } else if (isMarked) {
      final palette = CartelaMarkColorPalette.forColor(markColor);
      fillColor = palette.fill;
      borderColor = palette.border;
      textColor = palette.text;
      shadows = [
        BoxShadow(
          color: palette.shadow.withValues(alpha: 0.55),
          blurRadius: 10,
          spreadRadius: 0.5,
        ),
      ];
    } else if (interactionDisabled) {
      fillColor = isDark
          ? const Color(0xFF2A2A2A)
          : AppBranding.lightOnDisabled.withValues(alpha: 0.18);
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppBranding.lightOutline.withValues(alpha: 0.7);
      textColor = isDark
          ? Colors.white.withValues(alpha: 0.38)
          : AppBranding.lightOnDisabled;
      shadows = const [];
    } else {
      fillColor = AppBranding.cellBackground(context, marked: false);
      borderColor = AppBranding.cellBorder(context, marked: false);
      textColor = AppBranding.cellForeground(context, marked: false);
      shadows = isDark
          ? const []
          : [
              BoxShadow(
                color: AppBranding.brandPurple.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ];
    }

    final cellOpacity = interactionDisabled && !isFree
        ? (isMarked || isLastMarked ? 0.52 : 0.38)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.all(CartelaBoardLayout.cellPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          return Opacity(
            opacity: cellOpacity,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: _OneAwayCellPulseWrapper(
                    active: isOneAwayTarget && !interactionDisabled,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fillColor,
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: interactionDisabled ? const [] : shadows,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              displayValue,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: isFree
                                    ? CartelaBoardLayout.liveFreeFontSize
                                    : CartelaBoardLayout.liveCellNumberFontSize,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OneAwayCellPulseWrapper extends StatefulWidget {
  const _OneAwayCellPulseWrapper({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_OneAwayCellPulseWrapper> createState() =>
      _OneAwayCellPulseWrapperState();
}

class _OneAwayCellPulseWrapperState extends State<_OneAwayCellPulseWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _OneAwayCellPulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.16, end: 1).animate(_pulse),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1.08).animate(_pulse),
        child: widget.child,
      ),
    );
  }
}

class _GreenClaimPulseWrapper extends StatefulWidget {
  const _GreenClaimPulseWrapper({required this.active, required this.child});

  final bool active;
  final Widget child;

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
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _GreenClaimPulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
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
  const _OneAwayPulseWrapper({required this.active, required this.child});

  final bool active;
  final Widget child;

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
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _OneAwayPulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
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
              color: Colors.redAccent.withValues(alpha: 0.35 + (t * 0.65)),
              width: 1.2 + (t * 2.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.12 + (t * 0.38)),
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
