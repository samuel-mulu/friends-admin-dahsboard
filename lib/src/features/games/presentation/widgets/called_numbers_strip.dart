import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/models/called_number_model.dart';
import '../../domain/live_connection_status.dart';
import 'latest_call_pulse.dart';
import 'live_status_chip.dart';

class CalledNumbersStrip extends StatefulWidget {
  const CalledNumbersStrip({
    required this.calledNumbers,
    this.checkingCartelaNumbers = const [],
    this.winnerCartelaNumbers = const [],
    this.blockedCartelaNumbers = const [],
    this.isCheckingClaim = false,
    this.isRefreshing = false,
    this.connectionState = LiveConnectionState.online,
    this.onRefreshCalledNumbers,
    this.onWinnerCartelaTapped,
    this.lockExpanded = false,
    this.headerLeading,
    super.key,
  });

  final List<CalledNumberModel> calledNumbers;
  final List<int> checkingCartelaNumbers;
  final List<int> winnerCartelaNumbers;
  final List<int> blockedCartelaNumbers;
  final bool isCheckingClaim;
  final bool isRefreshing;
  final LiveConnectionState connectionState;
  final VoidCallback? onRefreshCalledNumbers;
  final ValueChanged<int>? onWinnerCartelaTapped;
  final bool lockExpanded;
  final Widget? headerLeading;

  @override
  State<CalledNumbersStrip> createState() => _CalledNumbersStripState();
}

class _CalledNumbersStripState extends State<CalledNumbersStrip> {
  bool _showBoard = false;

  @override
  void initState() {
    super.initState();
    if (widget.lockExpanded) {
      _showBoard = true;
    }
  }

  @override
  void didUpdateWidget(covariant CalledNumbersStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lockExpanded) {
      _showBoard = true;
    }
  }

  bool get _boardExpanded => widget.lockExpanded || _showBoard;

  @override
  Widget build(BuildContext context) {
    final orderedNumbers = widget.calledNumbers.reversed.toList(
      growable: false,
    );
    final latest = orderedNumbers.isEmpty ? null : orderedNumbers.first;
    final calledNumberSet = widget.calledNumbers
        .map((item) => item.number)
        .toSet();
    final showClaimRows =
        widget.checkingCartelaNumbers.isNotEmpty ||
        widget.winnerCartelaNumbers.isNotEmpty ||
        widget.blockedCartelaNumbers.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        _boardExpanded ? AppSpacing.sm : AppSpacing.xl,
        _boardExpanded ? AppSpacing.sm : AppSpacing.xs,
        _boardExpanded ? AppSpacing.sm : AppSpacing.xl,
        _boardExpanded ? AppSpacing.sm : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppBranding.panelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isCheckingClaim
              ? AppBranding.gold.withValues(alpha: 0.65)
              : AppBranding.panelBorder(context),
          width: widget.isCheckingClaim ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_boardExpanded)
            _ExpandedBoardHeader(
              drawnCount: widget.calledNumbers.length,
              connectionStatus: widget.connectionState,
              isRefreshing: widget.isRefreshing,
              onRefreshCalledNumbers: widget.onRefreshCalledNumbers,
              headerLeading: widget.headerLeading,
              onHideBoard: widget.lockExpanded
                  ? null
                  : () => setState(() => _showBoard = false),
            )
          else
            _CollapsedCallHeader(
              latest: latest,
              recentCalls: orderedNumbers.length <= 1
                  ? const []
                  : orderedNumbers.sublist(1),
              drawnCount: widget.calledNumbers.length,
              connectionStatus: widget.connectionState,
              isCheckingClaim: widget.isCheckingClaim,
              isRefreshing: widget.isRefreshing,
              onRefreshCalledNumbers: widget.onRefreshCalledNumbers,
              headerLeading: widget.headerLeading,
              onShowBoard: () => setState(() => _showBoard = true),
            ),
          if (_boardExpanded) ...[
            VGap.md,
            _CalledNumbersBallsTray(
              child: _CalledNumbersBoard(
                calledNumberSet: calledNumberSet,
                latestNumber: latest?.number,
                latestLetter: latest?.letter,
              ),
            ),
          ],
          if (showClaimRows) ...[
            VGap.md,
            if (widget.checkingCartelaNumbers.isNotEmpty)
              _ClaimCartelaRow(
                label: context.l10n.calledNumbersCheckingCartela,
                numbers: widget.checkingCartelaNumbers,
                variant: _ClaimCartelaChipVariant.checking,
              ),
            if (widget.checkingCartelaNumbers.isNotEmpty &&
                widget.winnerCartelaNumbers.isNotEmpty)
              VGap.xs,
            if (widget.winnerCartelaNumbers.isNotEmpty)
              _ClaimCartelaRow(
                label: context.l10n.calledNumbersWinnerCartela,
                numbers: widget.winnerCartelaNumbers,
                variant: _ClaimCartelaChipVariant.winner,
                onWinnerCartelaTapped: widget.onWinnerCartelaTapped,
              ),
            if ((widget.checkingCartelaNumbers.isNotEmpty ||
                    widget.winnerCartelaNumbers.isNotEmpty) &&
                widget.blockedCartelaNumbers.isNotEmpty)
              VGap.xs,
            if (widget.blockedCartelaNumbers.isNotEmpty)
              _ClaimCartelaRow(
                label: context.l10n.calledNumbersBlockedCartela,
                numbers: widget.blockedCartelaNumbers,
                variant: _ClaimCartelaChipVariant.blocked,
              ),
          ],
        ],
      ),
    );
  }
}

class _CollapsedCallHeader extends StatelessWidget {
  const _CollapsedCallHeader({
    required this.latest,
    required this.recentCalls,
    required this.drawnCount,
    required this.connectionStatus,
    required this.isCheckingClaim,
    required this.isRefreshing,
    required this.onShowBoard,
    this.onRefreshCalledNumbers,
    this.headerLeading,
  });

  final CalledNumberModel? latest;
  final List<CalledNumberModel> recentCalls;
  final int drawnCount;
  final LiveConnectionState connectionStatus;
  final bool isCheckingClaim;
  final bool isRefreshing;
  final VoidCallback? onRefreshCalledNumbers;
  final VoidCallback onShowBoard;
  final Widget? headerLeading;

  static const _latestBallSize = 64.0;
  static const _recentBallSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.calledNumbersDrawnCount(drawnCount),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            if (headerLeading != null) ...[
              headerLeading!,
              const SizedBox(width: 6),
            ],
            ConnectionStatusDot(status: connectionStatus, theme: theme),
            const SizedBox(width: 4),
            _CalledNumbersRefreshButton(
              isRefreshing: isRefreshing,
              onPressed: onRefreshCalledNumbers,
            ),
            IconButton(
              tooltip: 'Show called numbers board',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              onPressed: onShowBoard,
              icon: const Icon(Icons.grid_view_rounded, size: 18),
            ),
          ],
        ),
        const VGap(AppSpacing.xxs),
        _CalledNumbersBallsTray(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (latest != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final offsetAnimation =
                        Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: _CalledBall(
                    key: ValueKey<String>(
                      '${latest!.letter}-${latest!.number}-${latest!.order}',
                    ),
                    calledNumber: latest,
                    size: _latestBallSize,
                    isLatest: true,
                  ),
                )
              else
                const _CalledBall(
                  calledNumber: null,
                  size: _latestBallSize,
                  isLatest: true,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: isCheckingClaim && recentCalls.isEmpty
                    ? Text(
                        l10n.calledNumbersCheckingBingo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppBranding.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : recentCalls.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: _recentBallSize,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: recentCalls.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return _CalledBall(
                              calledNumber: recentCalls[index],
                              size: _recentBallSize,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandedBoardHeader extends StatelessWidget {
  const _ExpandedBoardHeader({
    required this.drawnCount,
    required this.connectionStatus,
    required this.isRefreshing,
    this.onRefreshCalledNumbers,
    this.onHideBoard,
    this.headerLeading,
  });

  final int drawnCount;
  final LiveConnectionState connectionStatus;
  final bool isRefreshing;
  final VoidCallback? onHideBoard;
  final VoidCallback? onRefreshCalledNumbers;
  final Widget? headerLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.calledNumbersDrawnCount(drawnCount),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
        if (headerLeading != null) ...[
          headerLeading!,
          const SizedBox(width: 6),
        ],
        ConnectionStatusDot(status: connectionStatus, theme: theme),
        const SizedBox(width: 4),
        _CalledNumbersRefreshButton(
          isRefreshing: isRefreshing,
          onPressed: onRefreshCalledNumbers,
        ),
        if (onHideBoard != null)
          IconButton(
            tooltip: 'Hide called numbers board',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: onHideBoard,
            icon: const Icon(Icons.unfold_less_rounded, size: 18),
          ),
      ],
    );
  }
}

class _CalledNumbersRefreshButton extends StatelessWidget {
  const _CalledNumbersRefreshButton({
    required this.isRefreshing,
    this.onPressed,
  });

  final bool isRefreshing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isRefreshing;

    return IconButton(
      tooltip: 'Sync latest game state',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      onPressed: enabled ? onPressed : null,
      icon: isRefreshing
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(
              Icons.refresh_rounded,
              size: 20,
              color: enabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _CalledNumbersBoard extends StatelessWidget {
  const _CalledNumbersBoard({
    required this.calledNumberSet,
    this.latestNumber,
    this.latestLetter,
  });

  final Set<int> calledNumberSet;
  final int? latestNumber;
  final String? latestLetter;

  static const _rows = [
    _BoardRow(letter: 'B', start: 1, color: AppBranding.bingoB),
    _BoardRow(letter: 'I', start: 16, color: AppBranding.bingoI),
    _BoardRow(letter: 'N', start: 31, color: AppBranding.bingoN),
    _BoardRow(letter: 'G', start: 46, color: AppBranding.bingoG),
    _BoardRow(letter: 'O', start: 61, color: AppBranding.bingoO),
  ];

  static const double cellGap = 1.5;
  static const double letterColumnWidth = 18;
  static const double rowHeight = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final idleCellColor = isDark
        ? const Color(0xFF2A2A2A)
        : AppBranding.lightSurfaceRaised;
    final normalizedLatestLetter = latestLetter?.trim().toUpperCase();

    return Column(
      children: _rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _BoardLetterLabel(
                    row: row,
                    rowHeight: rowHeight,
                    width: letterColumnWidth,
                    isLatest:
                        normalizedLatestLetter == row.letter &&
                        latestNumber != null,
                    latestNumber: latestNumber,
                  ),
                  SizedBox(width: cellGap),
                  Expanded(
                    child: Row(
                      children: List.generate(15, (index) {
                        final number = row.start + index;
                        final isCalled = calledNumberSet.contains(number);
                        final isLatest = latestNumber == number;

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : cellGap / 2,
                              right: index == 14 ? 0 : cellGap / 2,
                            ),
                            child: SizedBox(
                              height: rowHeight,
                              child: _BoardCell(
                                number: number,
                                idleColor: idleCellColor,
                                calledColor: row.color,
                                isCalled: isCalled,
                                isLatest: isLatest,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _BoardLetterLabel extends StatelessWidget {
  const _BoardLetterLabel({
    required this.row,
    required this.rowHeight,
    required this.width,
    required this.isLatest,
    required this.latestNumber,
  });

  final _BoardRow row;
  final double rowHeight;
  final double width;
  final bool isLatest;
  final int? latestNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      row.letter,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        color: isLatest ? Colors.white : row.color,
        fontWeight: FontWeight.w900,
        fontSize: 13,
        height: 1,
        shadows: isLatest
            ? const [
                Shadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
    );

    final label = isLatest
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: row.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              child: text,
            ),
          )
        : text;

    final letter = SizedBox(
      width: width,
      height: rowHeight,
      child: Center(child: label),
    );

    if (!isLatest || latestNumber == null) {
      return letter;
    }

    return SizedBox(
      width: width,
      height: rowHeight,
      child: LatestCallPulse(
        key: ValueKey<String>('${row.letter}-$latestNumber-letter'),
        borderRadius: 4,
        highlightColor: row.color,
        flashOverlay: false,
        pulseScale: 0.08,
        child: letter,
      ),
    );
  }
}

class _BoardRow {
  const _BoardRow({
    required this.letter,
    required this.start,
    required this.color,
  });

  final String letter;
  final int start;
  final Color color;
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.number,
    required this.idleColor,
    required this.calledColor,
    required this.isCalled,
    required this.isLatest,
  });

  final int number;
  final Color idleColor;
  final Color calledColor;
  final bool isCalled;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLatestCalled = isLatest && isCalled;
    final backgroundColor = isLatestCalled
        ? AppBranding.gold
        : (isCalled ? calledColor : idleColor);
    final textColor = isLatestCalled
        ? AppBranding.casinoPurpleDeep
        : (isCalled
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.82));

    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: isLatest
            ? null
            : Border.all(
                color: isCalled
                    ? calledColor.withValues(alpha: 0.9)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
                width: 1,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$number',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1,
                letterSpacing: -0.2,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );

    if (isLatestCalled) {
      return LatestCallPulse(
        key: ValueKey<int>(number),
        borderRadius: 4,
        highlightColor: AppBranding.gold,
        child: cell,
      );
    }

    return cell;
  }
}

enum _ClaimCartelaChipVariant { checking, winner, blocked }

double _claimCartelaChipWidth(int number) {
  final digits = number.abs().toString().length;
  return switch (digits) {
    >= 5 => 34,
    4 => 30,
    3 => 26,
    _ => 22,
  };
}

class _ClaimCartelaRow extends StatelessWidget {
  const _ClaimCartelaRow({
    required this.label,
    required this.numbers,
    required this.variant,
    this.onWinnerCartelaTapped,
  });

  final String label;
  final List<int> numbers;
  final _ClaimCartelaChipVariant variant;
  final ValueChanged<int>? onWinnerCartelaTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChecking = variant == _ClaimCartelaChipVariant.checking;
    final isWinner = variant == _ClaimCartelaChipVariant.winner;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label=',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isChecking
                ? AppBranding.gold
                : isWinner
                ? AppBranding.bingoFreeGreen
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 9,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: numbers
                .map(
                  (number) => _ClaimCartelaChip(
                    number: number,
                    variant: variant,
                    onTap: variant == _ClaimCartelaChipVariant.winner
                        ? onWinnerCartelaTapped
                        : null,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ClaimCartelaChip extends StatefulWidget {
  const _ClaimCartelaChip({
    required this.number,
    required this.variant,
    this.onTap,
  });

  final int number;
  final _ClaimCartelaChipVariant variant;
  final ValueChanged<int>? onTap;

  @override
  State<_ClaimCartelaChip> createState() => _ClaimCartelaChipState();
}

class _ClaimCartelaChipState extends State<_ClaimCartelaChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.variant == _ClaimCartelaChipVariant.checking) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ClaimCartelaChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.variant == _ClaimCartelaChipVariant.checking) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChecking = widget.variant == _ClaimCartelaChipVariant.checking;
    final isWinner = widget.variant == _ClaimCartelaChipVariant.winner;

    final backgroundColor = isChecking
        ? AppBranding.gold.withValues(alpha: 0.22)
        : isWinner
        ? Colors.green.withValues(alpha: 0.22)
        : theme.colorScheme.error.withValues(alpha: 0.18);

    final borderColor = isChecking
        ? AppBranding.gold
        : isWinner
        ? Colors.green.shade600
        : theme.colorScheme.error.withValues(alpha: 0.7);

    final textColor = isChecking
        ? AppBranding.goldDark
        : isWinner
        ? Colors.green.shade700
        : theme.colorScheme.error;

    Widget chip = Container(
      width: _claimCartelaChipWidth(widget.number),
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '${widget.number}',
            maxLines: 1,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );

    if (isChecking) {
      chip = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Opacity(opacity: _pulse.value, child: child);
        },
        child: chip,
      );
    }

    final onTap = widget.onTap;
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(widget.number),
          borderRadius: BorderRadius.circular(5),
          child: chip,
        ),
      );
    }

    return chip;
  }
}

class _CalledBall extends StatelessWidget {
  const _CalledBall({
    required this.calledNumber,
    required this.size,
    this.isLatest = false,
    super.key,
  });

  final CalledNumberModel? calledNumber;
  final double size;
  final bool isLatest;

  static Color _baseColorForLetter(String letter) {
    return AppBranding.bingoColumnColor(letter);
  }

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
          width: 1.2,
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
        width: isLatest ? 1 : 1.2,
      ),
      boxShadow: isLatest
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.38),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 4,
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
        ? AppBranding.gold
        : _baseColorForLetter(calledNumber!.letter);

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
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Text(
                  '${calledNumber!.letter}-${calledNumber!.number}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isLatest
                        ? (size >= 60 ? 20 : 16)
                        : (size >= 42 ? 15 : 12),
                    height: 1,
                    letterSpacing: isLatest ? -0.3 : 0,
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
    );

    if (isLatest && !isEmpty) {
      return LatestCallPulse(
        key: ValueKey<String>(
          '${calledNumber!.letter}-${calledNumber!.number}-${calledNumber!.order}',
        ),
        shape: BoxShape.circle,
        highlightColor: AppBranding.gold,
        child: ball,
      );
    }

    return ball;
  }
}

/// Light-mode tray behind drawn balls — matches cartela board contrast.
class _CalledNumbersBallsTray extends StatelessWidget {
  const _CalledNumbersBallsTray({required this.child});

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
