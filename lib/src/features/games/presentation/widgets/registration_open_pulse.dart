import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// Animated registration call-to-action for the live registration room.
class RegistrationOpenPulse extends StatefulWidget {
  const RegistrationOpenPulse({
    this.isGuest = false,
    super.key,
  });

  final bool isGuest;

  @override
  State<RegistrationOpenPulse> createState() => _RegistrationOpenPulseState();
}

class _RegistrationOpenPulseState extends State<RegistrationOpenPulse>
    with SingleTickerProviderStateMixin {
  static const _memberMessages = ['REGISTRATION OPEN', 'REGISTER NOW'];

  late final AnimationController _controller;
  late final Animation<double> _borderGlow;
  late final Animation<double> _shine;
  late final Animation<double> _textScale;

  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _borderGlow = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _shine = Tween<double>(begin: 0.1, end: 0.28).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _textScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (!widget.isGuest) {
      _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) {
          return;
        }
        setState(
          () => _messageIndex = (_messageIndex + 1) % _memberMessages.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppBranding.casinoPurpleDeep,
                AppBranding.casinoPurple,
                AppBranding.casinoPurpleDeep.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.gold.withValues(alpha: _shine.value),
                blurRadius: 18,
                spreadRadius: 1,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(animation: _controller),
              const SizedBox(width: 8),
              Icon(
                Icons.confirmation_number_outlined,
                size: 20,
                color: AppBranding.gold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              ScaleTransition(
                scale: _textScale,
                child: widget.isGuest
                    ? Text(
                        'Sign up to play',
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
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.35),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _memberMessages[_messageIndex],
                          key: ValueKey(_memberMessages[_messageIndex]),
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
                      ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.confirmation_number_outlined,
                size: 20,
                color: AppBranding.gold.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              _PulsingDot(animation: _controller),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isGuest
                ? 'Create an account to pick your cartela'
                : 'Pick your cartela number below',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppBranding.gold.withValues(
              alpha: 0.45 + (animation.value * 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.gold.withValues(alpha: animation.value * 0.6),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
