import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Compact Friends Bingo brand card with animated B-I-N-G-O balls.
class AuthBrandHeader extends StatefulWidget {
  const AuthBrandHeader({super.key});

  @override
  State<AuthBrandHeader> createState() => _AuthBrandHeaderState();
}

class _AuthBrandHeaderState extends State<AuthBrandHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppBranding.brandPurple,
            AppBranding.casinoPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppBranding.goldAccent.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Text(
            AppBranding.brandName,
            style: AppBranding.wordmarkGold(size: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          _MiniBingoBalls(animation: _controller),
        ],
      ),
    );
  }
}

class _MiniBingoBalls extends StatelessWidget {
  const _MiniBingoBalls({required this.animation});

  final Animation<double> animation;

  static const _letters = ['B', 'I', 'N', 'G', 'O'];
  static const _colors = [
    Color(0xFFD32F2F),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_letters.length, (index) {
            final phase = (animation.value + (index * 0.16)) % 1.0;
            final bob = math.sin(phase * math.pi * 2) * 3;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, bob),
                child: _MiniBall(
                  letter: _letters[index],
                  color: _colors[index],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MiniBall extends StatelessWidget {
  const _MiniBall({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
          height: 1,
          shadows: [
            Shadow(
              color: Color(0xCC000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
