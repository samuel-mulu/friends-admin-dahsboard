import 'package:flutter/material.dart';
import '../../data/models/called_number_model.dart';
import 'bingo_ball_badge.dart';

class CalledNumbersStrip extends StatelessWidget {
  const CalledNumbersStrip({
    super.key,
    required this.calledNumbers,
    this.onBallTap,
    this.height = 64.0,
  });

  final List<CalledNumberModel> calledNumbers;
  final void Function(CalledNumberModel ball)? onBallTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (calledNumbers.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Waiting for first call...',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    final reversed = calledNumbers.reversed.toList();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: reversed.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ball = reversed[index];
          final isLatest = index == 0;

          return GestureDetector(
            onTap: onBallTap != null ? () => onBallTap!(ball) : null,
            child: BingoBallBadge(
              number: ball.number,
              size: isLatest ? 48 : 40,
              isLatest: isLatest,
            ),
          );
        },
      ),
    );
  }
}
