import 'package:flutter/material.dart';

class BingoBallBadge extends StatelessWidget {
  const BingoBallBadge({
    super.key,
    required this.number,
    this.size = 44.0,
    this.isLatest = false,
    this.animated = true,
  });

  final int number;
  final double size;
  final bool isLatest;
  final bool animated;

  static String getLetter(int number) {
    if (number <= 15) return 'B';
    if (number <= 30) return 'I';
    if (number <= 45) return 'N';
    if (number <= 60) return 'G';
    return 'O';
  }

  static Color getColor(int number) {
    if (number <= 15) return const Color(0xFFE53935); // B - Red
    if (number <= 30) return const Color(0xFFFB8C00); // I - Orange
    if (number <= 45) return const Color(0xFF1E88E5); // N - Blue
    if (number <= 60) return const Color(0xFF43A047); // G - Green
    return const Color(0xFF8E24AA);                   // O - Purple
  }

  @override
  Widget build(BuildContext context) {
    final letter = getLetter(number);
    final baseColor = getColor(number);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            baseColor.withValues(alpha: 0.85),
            baseColor,
          ],
        ),
        boxShadow: [
          if (isLatest)
            BoxShadow(
              color: baseColor.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(
          color: isLatest ? Colors.white : Colors.white.withValues(alpha: 0.3),
          width: isLatest ? 2.0 : 1.0,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              letter,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
                fontSize: size * 0.24,
                height: 1.0,
              ),
            ),
            Text(
              number.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.36,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
