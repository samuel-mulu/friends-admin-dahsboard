import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../data/models/called_number_model.dart';

class CalledNumbersStrip extends StatelessWidget {
  const CalledNumbersStrip({required this.calledNumbers, super.key});

  final List<CalledNumberModel> calledNumbers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderedNumbers = calledNumbers.reversed.toList(growable: false);
    final latest = orderedNumbers.isEmpty ? null : orderedNumbers.first;
    final history = orderedNumbers.length <= 1
        ? const <CalledNumberModel>[]
        : orderedNumbers.sublist(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppBranding.panelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          if (latest != null)
            _CalledBall(
              calledNumber: latest,
              size: 48,
              isLatest: true,
            )
          else
            const _CalledBall(calledNumber: null, size: 48, isLatest: true),
          const SizedBox(width: 10),
          Expanded(
            child: history.isEmpty
                ? Text(
                    'Waiting for numbers...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: history
                          .map(
                            (calledNumber) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _CalledBall(
                                calledNumber: calledNumber,
                                size: 32,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            'Drawn: ${calledNumbers.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalledBall extends StatelessWidget {
  const _CalledBall({
    required this.calledNumber,
    required this.size,
    this.isLatest = false,
  });

  final CalledNumberModel? calledNumber;
  final double size;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = calledNumber == null;
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppBranding.calledBallLatest(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEmpty
            ? theme.colorScheme.surfaceContainerHighest
            : (isLatest
                ? accent.withValues(alpha: isDark ? 0.28 : 0.14)
                : theme.colorScheme.surfaceContainerHigh),
        border: Border.all(
          color: isLatest && !isEmpty
              ? AppBranding.gold
              : theme.colorScheme.outlineVariant,
          width: isLatest ? 2 : 1,
        ),
        boxShadow: isLatest && !isEmpty
            ? [
                BoxShadow(
                  color: AppBranding.gold.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
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
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    calledNumber!.letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: size > 40 ? 10 : 8,
                      color: isLatest
                          ? (isDark ? AppBranding.gold : AppBranding.casinoPurple)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${calledNumber!.number}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: size > 40 ? 12 : 10,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
