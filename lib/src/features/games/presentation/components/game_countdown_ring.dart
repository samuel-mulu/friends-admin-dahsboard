import 'package:flutter/material.dart';

class GameCountdownRing extends StatelessWidget {
  const GameCountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 72.0,
    this.label,
    this.strokeWidth = 6.0,
    this.showMinutes = false,
  });

  final Duration remaining;
  final Duration total;
  final double size;
  final String? label;
  final double strokeWidth;
  final bool showMinutes;

  Color _progressColor(double progress, ThemeData theme) {
    if (progress < 0.2) return Colors.red;
    if (progress < 0.4) return Colors.orange;
    return theme.colorScheme.primary;
  }

  String _formatTime() {
    final totalSeconds = remaining.inSeconds.clamp(0, 99999);
    if (showMinutes) {
      final mins = totalSeconds ~/ 60;
      final secs = totalSeconds % 60;
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$totalSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMs = total.inMilliseconds;
    final remainingMs = remaining.inMilliseconds.clamp(0, totalMs);
    final progress = totalMs > 0 ? (remainingMs / totalMs) : 0.0;
    final color = _progressColor(progress, theme);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: theme.dividerColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.0,
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
