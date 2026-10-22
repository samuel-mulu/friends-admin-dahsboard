import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';

class GuestSpectatorSection extends StatelessWidget {
  const GuestSpectatorSection({
    required this.onSignUp,
    required this.onSignIn,
    super.key,
  });

  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1230), const Color(0xFF120D1F)]
                  : [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerLow,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppBranding.panelBorder(context)),
            boxShadow: [
              BoxShadow(
                color: AppBranding.elevationShadow(
                  context,
                ).withValues(alpha: isDark ? 0.24 : 0.1),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppBranding.brandChipBackground(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppBranding.brandChipBorder(context),
                        ),
                      ),
                      child: Text(
                        l10n.guestPromoModeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppBranding.brandHighlightText(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: onSignIn,
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(l10n.signIn),
                          ),
                          FilledButton(
                            onPressed: onSignUp,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(l10n.signUp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                VGap.md,
                Text(
                  l10n.guestPromoTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                VGap.sm,
                Text(
                  l10n.guestPromoMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                VGap.xl,
                const GuestCartelaPromoPreview(),
                VGap.sm,
                Text(
                  l10n.guestPromoFooter,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class GuestCartelaPromoPreview extends StatefulWidget {
  const GuestCartelaPromoPreview({super.key});

  @override
  State<GuestCartelaPromoPreview> createState() =>
      _GuestCartelaPromoPreviewState();
}

class _GuestCartelaPromoPreviewState extends State<GuestCartelaPromoPreview>
    with SingleTickerProviderStateMixin {
  static const double _stageSpan = 0.23;
  static const double _congratsStart = 0.69;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  static const List<String> _headers = ['B', 'I', 'N', 'G', 'O'];
  static const List<String> _cells = [
    '7', '18', '34', '48', '67',
    '11', '20', '39', '57', '71',
    '13', '29', 'FREE', '60', '73',
    '14', '25', '42', '53', '74',
    '15', '30', '45', '58', '75',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final stages = _buildStages(l10n);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final activeStageIndex = _activeStageIndex(t);
          final activeStage = stages[activeStageIndex];
          final showCongrats = t >= _congratsStart;
          final stageProgress = _stageProgressFor(t, activeStageIndex);
          final lineProgresses = List<double>.generate(
            stages.length,
            (index) => _lineProgressForStage(t, index),
          );
          final statusLabel = showCongrats
              ? l10n.guestPromoWinnerLabel
              : activeStage.label;
          final helperText = showCongrats
              ? l10n.guestPromoCongratsReceived('10,000 Birr')
              : activeStage.helperText;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppBranding.cartelaBoardBackground(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppBranding.panelBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final header in _headers)
                      Expanded(
                        child: Center(
                          child: Text(
                            header,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppBranding.bingoColumnColor(header),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                VGap.md,
                SizedBox(
                  height: 208,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 520),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.96,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: showCongrats
                        ? const _GuestPromoCongratsCard(
                            key: ValueKey('guest-promo-congrats'),
                            amountLabel: '10,000 Birr',
                          )
                        : Stack(
                            key: const ValueKey('guest-promo-board'),
                            children: [
                              Column(
                                children: List.generate(5, (row) {
                                  return Expanded(
                                    child: Row(
                                      children: List.generate(5, (column) {
                                        final index = (row * 5) + column;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: _GuestPromoCell(
                                              label: _cells[index],
                                              marked: _isMarked(
                                                index,
                                                stages: stages,
                                                progress: t,
                                                showCongrats: showCongrats,
                                              ),
                                              emphasized: _isEmphasized(
                                                index,
                                                stages: stages,
                                                stage: activeStage,
                                                progress: stageProgress,
                                                showCongrats: showCongrats,
                                              ),
                                              free: index == 12,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                }),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _GuestPromoWinningLinesPainter(
                                      stages: stages,
                                      progressByStage: lineProgresses,
                                      color: AppBranding.latestCallBorder,
                                      glowColor:
                                          AppBranding.latestCallGlowForTheme(
                                            context,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                VGap.md,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        helperText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppBranding.brandChipBackground(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppBranding.brandChipBorder(context),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppBranding.brandAccentValue(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _activeStageIndex(double progress) {
    if (progress >= _congratsStart) {
      return 2;
    }

    final index = (progress / _stageSpan).floor();
    return index.clamp(0, 2);
  }

  double _stageProgressFor(double progress, int stageIndex) {
    final stageStart = stageIndex * _stageSpan;
    final stageEnd = stageStart + _stageSpan;
    if (progress <= stageStart) {
      return 0;
    }
    if (progress >= stageEnd || progress >= _congratsStart) {
      return 1;
    }
    return ((progress - stageStart) / _stageSpan).clamp(0.0, 1.0);
  }

  double _lineProgressForStage(double progress, int stageIndex) {
    final stageProgress = _stageProgressFor(progress, stageIndex);
    return ((stageProgress - 0.28) / 0.56).clamp(0.0, 1.0);
  }

  bool _isMarked(
    int index, {
    required List<_GuestPromoStage> stages,
    required double progress,
    required bool showCongrats,
  }) {
    if (index == 12) {
      return true;
    }

    for (var stageIndex = 0; stageIndex < stages.length; stageIndex++) {
      final stage = stages[stageIndex];
      final stageProgress = _stageProgressFor(progress, stageIndex);
      final winningPosition = stage.winningIndexes.indexOf(index);
      if (winningPosition >= 0 &&
          (showCongrats ||
              stageProgress >=
                  ((winningPosition + 1) / stage.winningIndexes.length))) {
        return true;
      }

      final accentPosition = stage.accentIndexes.indexOf(index);
      if (accentPosition >= 0 &&
          stageProgress >= (0.14 + (accentPosition * 0.16))) {
        return true;
      }
    }

    return false;
  }

  bool _isEmphasized(
    int index, {
    required List<_GuestPromoStage> stages,
    required _GuestPromoStage stage,
    required double progress,
    required bool showCongrats,
  }) {
    if (!_isMarked(
      index,
      stages: stages,
      progress: progress,
      showCongrats: showCongrats,
    )) {
      return false;
    }

    final pulse = ((progress * 10) % 1.0);
    return pulse > 0.58 && stage.winningIndexes.contains(index);
  }

  List<_GuestPromoStage> _buildStages(AppLocalizations l10n) {
    return [
      _GuestPromoStage(
        label: l10n.guestPromoRowLabel,
        helperText: l10n.guestPromoRowHelper,
        winningIndexes: const [10, 11, 12, 13, 14],
        accentIndexes: const [6, 8],
        lineKind: _GuestPromoLineKind.row,
      ),
      _GuestPromoStage(
        label: l10n.guestPromoColumnLabel,
        helperText: l10n.guestPromoColumnHelper,
        winningIndexes: const [2, 7, 12, 17, 22],
        accentIndexes: const [1, 3, 21],
        lineKind: _GuestPromoLineKind.column,
      ),
      _GuestPromoStage(
        label: l10n.guestPromoDiagonalLabel,
        helperText: l10n.guestPromoDiagonalHelper,
        winningIndexes: const [0, 6, 12, 18, 24],
        accentIndexes: const [4, 20],
        lineKind: _GuestPromoLineKind.diagonal,
      ),
    ];
  }
}

class _GuestPromoCell extends StatelessWidget {
  const _GuestPromoCell({
    required this.label,
    required this.marked,
    required this.emphasized,
    required this.free,
  });

  final String label;
  final bool marked;
  final bool emphasized;
  final bool free;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = free
        ? AppBranding.brandAccentValue(context)
        : marked
        ? AppBranding.bingoFreeGreen.withValues(alpha: 0.9)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.82);
    final foreground = free
        ? AppBranding.brandPurple
        : marked
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Transform.scale(
      scale: emphasized ? 1.04 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: marked || free
                ? Colors.white.withValues(alpha: 0.16)
                : AppBranding.panelBorder(context).withValues(alpha: 0.75),
          ),
          boxShadow: emphasized
              ? [
                  BoxShadow(
                    color: AppBranding.bingoFreeGreen.withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _GuestPromoCongratsCard extends StatelessWidget {
  const _GuestPromoCongratsCard({required this.amountLabel, super.key});

  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppBranding.gold.withValues(alpha: 0.2),
                  AppBranding.latestCallBorder.withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppBranding.gold.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppBranding.gold.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth - 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.celebration_rounded,
                          size: 26,
                          color: AppBranding.brandAccentValue(context),
                        ),
                      ),
                      VGap.sm,
                      Text(
                        l10n.guestPromoCongratsTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      VGap.xs,
                      Text(
                        l10n.guestPromoCongratsAmountWon(amountLabel),
                        textAlign: TextAlign.center,
                        style: AppBranding.wordmarkBrandAccent(
                          context,
                          size: 24,
                        ),
                      ),
                      VGap.sm,
                      Text(
                        l10n.guestPromoCongratsReceived(amountLabel),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      VGap.xs,
                      Text(
                        l10n.guestPromoCongratsWithdraw,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
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

class _GuestPromoWinningLinesPainter extends CustomPainter {
  const _GuestPromoWinningLinesPainter({
    required this.stages,
    required this.progressByStage,
    required this.color,
    required this.glowColor,
  });

  final List<_GuestPromoStage> stages;
  final List<double> progressByStage;
  final Color color;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < stages.length; index++) {
      final progress = progressByStage[index];
      if (progress <= 0) {
        continue;
      }

      final stage = stages[index];
      final start = _cellCenter(size, stage.winningIndexes.first);
      final end = _cellCenter(size, stage.winningIndexes.last);
      final current = Offset.lerp(start, end, progress) ?? end;

      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.32 * progress)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.95)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, current, glowPaint);
      canvas.drawLine(start, current, linePaint);
    }
  }

  Offset _cellCenter(Size size, int index) {
    final column = index % 5;
    final row = index ~/ 5;
    final cellWidth = size.width / 5;
    final cellHeight = size.height / 5;
    return Offset(
      (column * cellWidth) + (cellWidth / 2),
      (row * cellHeight) + (cellHeight / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GuestPromoWinningLinesPainter oldDelegate) {
    return oldDelegate.stages != stages ||
        oldDelegate.progressByStage.length != progressByStage.length ||
        !_sameDoubleList(oldDelegate.progressByStage, progressByStage) ||
        oldDelegate.color != color ||
        oldDelegate.glowColor != glowColor;
  }

  bool _sameDoubleList(List<double> left, List<double> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}

enum _GuestPromoLineKind { row, column, diagonal }

class _GuestPromoStage {
  const _GuestPromoStage({
    required this.label,
    required this.helperText,
    required this.winningIndexes,
    required this.accentIndexes,
    required this.lineKind,
  });

  final String label;
  final String helperText;
  final List<int> winningIndexes;
  final List<int> accentIndexes;
  final _GuestPromoLineKind lineKind;
}
