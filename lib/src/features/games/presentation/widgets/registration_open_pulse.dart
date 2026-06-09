import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Blinking "Registration Open" call-to-action for the live registration room.
class RegistrationOpenPulse extends StatefulWidget {
  const RegistrationOpenPulse({super.key});

  @override
  State<RegistrationOpenPulse> createState() => _RegistrationOpenPulseState();
}

class _RegistrationOpenPulseState extends State<RegistrationOpenPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _borderGlow;
  late final Animation<double> _shine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _borderGlow = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shine = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                AppBranding.casinoPurpleDeep,
                AppBranding.casinoPurple,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.gold.withValues(alpha: _shine.value),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: AppBranding.gold.withValues(alpha: _borderGlow.value),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: Text(
        'REGISTRATION OPEN',
        textAlign: TextAlign.center,
        style: AppBranding.wordmarkGold(size: 28).copyWith(
          color: AppBranding.gold,
          shadows: const [
            Shadow(
              color: Color(0x99000000),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}
