import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/api_date_time.dart';

/// Shared long/short countdown display backed by [ServerClockService].
class GameCountdown extends StatefulWidget {
  const GameCountdown({
    required this.target,
    this.serverClock,
    this.compact = false,
    this.large = false,
    this.semanticsLabel,
    super.key,
  });

  final DateTime? target;
  final ServerClockService? serverClock;
  final bool compact;
  final bool large;
  final String? semanticsLabel;

  @override
  State<GameCountdown> createState() => _GameCountdownState();
}

class _GameCountdownState extends State<GameCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = formatGameCountdown(widget.target, clock: widget.serverClock);
    final theme = Theme.of(context);

    final textStyle = widget.large
        ? theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppBranding.casinoPurpleDeep,
            letterSpacing: 0.5,
          )
        : theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppBranding.casinoPurpleDeep,
          );

    return Semantics(
      label: widget.semanticsLabel ?? label,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppBranding.gold.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppBranding.gold.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
            vertical: widget.compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }
}

/// Formats countdown durations (`30d 04h`, `03h 22m`, `14m 10s`, `45s`).
String formatGameCountdown(
  DateTime? target, {
  ServerClockService? clock,
}) {
  if (target == null) {
    return '--';
  }

  final totalSeconds = secondsUntilCeil(target, clock: clock);
  if (totalSeconds <= 0) {
    return '0s';
  }

  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (days > 0) {
    return '${days}d ${hours.toString().padLeft(2, '0')}h';
  }
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

/// Row with label + countdown pill.
class GameCountdownRow extends StatelessWidget {
  const GameCountdownRow({
    required this.label,
    required this.target,
    this.serverClock,
    this.large = false,
    super.key,
  });

  final String label;
  final DateTime? target;
  final ServerClockService? serverClock;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GameCountdown(
          target: target,
          serverClock: serverClock,
          large: large,
          semanticsLabel: '$label ${formatGameCountdown(target, clock: serverClock)}',
        ),
      ],
    );
  }
}
