import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';

double cartelaNumberHeaderFontSize(int number) {
  final digits = number.abs().toString().length;
  return switch (digits) {
    >= 5 => 17,
    4 => 20,
    3 => 22,
    _ => 24,
  };
}

double cartelaNumberCircleFontSize(int number, {double base = 28}) {
  final digits = number.abs().toString().length;
  return switch (digits) {
    >= 5 => base * 0.58,
    4 => base * 0.72,
    3 => base * 0.88,
    _ => base,
  };
}

double cartelaNumberHeaderMinWidth(int number) {
  final digits = number.abs().toString().length;
  return switch (digits) {
    >= 5 => 58,
    4 => 50,
    3 => 40,
    _ => 32,
  };
}

/// Gold circle badge used in registration/preview sheet headers.
class CartelaNumberCircleBadge extends StatelessWidget {
  const CartelaNumberCircleBadge({
    required this.number,
    this.size = 56,
    this.baseFontSize = 28,
    this.borderWidth = 2,
    super.key,
  });

  final int number;
  final double size;
  final double baseFontSize;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final fontSize = cartelaNumberCircleFontSize(number, base: baseFontSize);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppBranding.gold, width: borderWidth),
        color: AppBranding.casinoPurpleDeep,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '$number',
            maxLines: 1,
            style: TextStyle(
              color: AppBranding.gold,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal gold circle for live play card headers.
class CartelaNumberCompactCircleBadge extends StatelessWidget {
  const CartelaNumberCompactCircleBadge({required this.number, super.key});

  final int number;

  static const double size = 28;
  static const double baseFontSize = 13;

  @override
  Widget build(BuildContext context) {
    return CartelaNumberCircleBadge(
      number: number,
      size: size,
      baseFontSize: baseFontSize,
      borderWidth: 1,
    );
  }
}

/// Cartela number in live card headers — scales for 4–5 digit IDs.
class CartelaNumberHeaderLabel extends StatelessWidget {
  const CartelaNumberHeaderLabel({
    required this.number,
    required this.style,
    this.prefix = '',
    super.key,
  });

  final int number;
  final TextStyle style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cartelaNumberHeaderMinWidth(number),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          '$prefix$number',
          maxLines: 1,
          style: style.copyWith(
            fontSize: cartelaNumberHeaderFontSize(number),
          ),
        ),
      ),
    );
  }
}
