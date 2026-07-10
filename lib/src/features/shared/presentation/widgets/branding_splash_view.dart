import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

/// First-launch branded splash for Friends Bingo House.
///
/// Thin [Scaffold] wrapper around [BrandedLoadingBackdrop] so existing callers
/// that expect a full route/page keep working. New code that needs to layer the
/// branded loader over content (overlays, `Positioned.fill`) should use
/// [BrandedLoadingBackdrop] directly — or the unified `FriendsBingoLoader`.
class BrandingSplashView extends StatelessWidget {
  const BrandingSplashView({this.message, super.key});

  /// Optional status line shown in place of the rotating tips.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandedLoadingBackdrop(message: message),
    );
  }
}

/// Full-bleed branded loading visual (gradient + floating BINGO balls + tips).
///
/// Deliberately returns **no** [Scaffold] so it can be used both as a route
/// body and layered inside a [Stack]/`Positioned.fill` without nesting
/// scaffolds. Always fills its parent via [SizedBox.expand].
class BrandedLoadingBackdrop extends StatefulWidget {
  const BrandedLoadingBackdrop({
    this.message,
    this.compact = false,
    super.key,
  });

  /// When provided, replaces the rotating tips with a fixed status line.
  final String? message;

  /// Compact layout for smaller regions (drops the ambient background pattern
  /// and large spacers, keeps the balls + a single status line).
  final bool compact;

  @override
  State<BrandedLoadingBackdrop> createState() => _BrandedLoadingBackdropState();
}

class _BrandedLoadingBackdropState extends State<BrandedLoadingBackdrop>
    with TickerProviderStateMixin {
  static const _tips = [
    'Connecting you to the live Friends Bingo House.',
    'Pick your lucky cartela numbers before the round starts.',
    'Listen as balls are called — mark every match on your card.',
    'Complete the winning pattern and call Bingo to claim prizes.',
  ];

  late final AnimationController _introController;
  late final AnimationController _floatController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;

  Timer? _tipTimer;
  int _tipIndex = 0;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _titleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the OS "reduce motion" setting: resolve to a static branded state
    // instead of looping animations / rotating tips.
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced == _reducedMotion && _introController.isCompleted) {
      return;
    }
    _reducedMotion = reduced;
    _applyMotionState();
  }

  void _applyMotionState() {
    _tipTimer?.cancel();
    if (_reducedMotion) {
      _introController.value = 1;
      _floatController.stop();
      _floatController.value = 0;
      return;
    }

    if (!_introController.isAnimating && !_introController.isCompleted) {
      _introController.forward();
    }
    if (!_floatController.isAnimating) {
      _floatController.repeat();
    }
    if (widget.message == null) {
      _tipTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      });
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _introController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final statusText = widget.message ?? _tips[_tipIndex];

    final wordmark = FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Column(
          children: [
            Text(
              'FRIENDS BINGO',
              textAlign: TextAlign.center,
              style: AppBranding.wordmarkGold(size: compact ? 30 : 42),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppBranding.gold.withValues(alpha: 0.7),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'HOUSE',
                style: AppBranding.wordmarkGold(size: compact ? 16 : 22)
                    .copyWith(letterSpacing: 6),
              ),
            ),
          ],
        ),
      ),
    );

    final balls = FadeTransition(
      opacity: _subtitleFade,
      child: _FloatingBingoBalls(animation: _floatController),
    );

    final status = FadeTransition(
      opacity: _subtitleFade,
      child: SizedBox(
        height: compact ? 48 : 72,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            statusText,
            key: ValueKey(statusText),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );

    final content = SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: compact
              ? [
                  wordmark,
                  const SizedBox(height: 20),
                  balls,
                  const SizedBox(height: 12),
                  status,
                ]
              : [
                  const Spacer(flex: 2),
                  wordmark,
                  const SizedBox(height: 28),
                  balls,
                  const Spacer(flex: 2),
                  status,
                  const SizedBox(height: 36),
                ],
        ),
      ),
    );

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0B33),
              AppBranding.casinoPurpleDeep,
              AppBranding.casinoPurple,
              Color(0xFF120822),
            ],
            stops: [0, 0.35, 0.7, 1],
          ),
        ),
        child: Stack(
          children: [
            if (!compact) const _SplashBackgroundPattern(),
            content,
          ],
        ),
      ),
    );
  }
}

class _SplashBackgroundPattern extends StatelessWidget {
  const _SplashBackgroundPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppBranding.gold.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppBranding.feltGreen.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 28.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingBingoBalls extends StatelessWidget {
  const _FloatingBingoBalls({required this.animation});

  final Animation<double> animation;

  static const _letters = ['B', 'I', 'N', 'G', 'O'];
  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          height: 108,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_letters.length, (index) {
              final phase = (animation.value + (index * 0.18)) % 1.0;
              final bob = math.sin(phase * math.pi * 2) * 10;
              final scale = 0.94 + (math.sin(phase * math.pi * 2) * 0.06);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.scale(
                    scale: scale,
                    child: _BingoBall(
                      letter: _letters[index],
                      color: _colors[index],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _BingoBall extends StatelessWidget {
  const _BingoBall({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.95),
            color,
          ],
          stops: const [0.12, 0.55, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          shadows: [
            Shadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
