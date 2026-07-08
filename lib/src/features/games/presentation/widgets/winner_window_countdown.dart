import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/time/countdown_target_tracker.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../../../core/utils/api_date_time.dart';
import '../debug/live_realtime_debug.dart';

/// Shows a live countdown for the automatic-rule winner window.
/// [endsAt] must come from backend `winnerWindowEndsAt` — never estimated locally.
class WinnerWindowCountdown extends StatefulWidget {
  const WinnerWindowCountdown({
    required this.endsAt,
    this.serverClock,
    this.countdownTracker,
    this.scopeKey,
    super.key,
  });

  final DateTime endsAt;
  final ServerClockService? serverClock;
  final CountdownTargetTracker? countdownTracker;
  final String? scopeKey;

  @override
  State<WinnerWindowCountdown> createState() => _WinnerWindowCountdownState();
}

class _WinnerWindowCountdownState extends State<WinnerWindowCountdown> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _resolveSecondsLeft();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _syncCountdown(),
    );
  }

  @override
  void didUpdateWidget(covariant WinnerWindowCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt || oldWidget.scopeKey != widget.scopeKey) {
      _syncCountdown(force: true);
    }
  }

  int _resolveSecondsLeft() {
    final rawSeconds = secondsUntilCeil(
      widget.endsAt,
      clock: widget.serverClock,
    );
    return widget.countdownTracker?.apply(
          target: widget.endsAt,
          scopeKey: widget.scopeKey,
          rawRemaining: rawSeconds,
        ) ??
        rawSeconds;
  }

  void _syncCountdown({bool force = false}) {
    if (!mounted) {
      return;
    }

    final nextSeconds = _resolveSecondsLeft();

    LiveRealtimeDebug.countdown(
      target: widget.endsAt,
      serverNow: widget.serverClock?.lastServerNowUtc,
      deviceNow: DateTime.now(),
      offsetMs: widget.serverClock?.offsetMs,
      remaining: nextSeconds,
    );

    if (!force && _secondsLeft == nextSeconds) {
      return;
    }

    setState(() => _secondsLeft = nextSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _secondsLeft > 0
                  ? 'Winner window closes in ${_secondsLeft}s'
                  : 'Finalizing...',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
