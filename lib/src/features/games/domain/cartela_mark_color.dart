import 'package:flutter/material.dart';

import '../../../core/theme/app_branding.dart';

enum CartelaMarkColor {
  green,
  red,
  yellow,
  blue;

  static CartelaMarkColor? tryParse(String? raw) {
    return switch (raw) {
      'green' => CartelaMarkColor.green,
      'red' => CartelaMarkColor.red,
      'yellow' => CartelaMarkColor.yellow,
      'blue' => CartelaMarkColor.blue,
      _ => null,
    };
  }

  String get storageKey => name;
}

class CartelaMarkColorPalette {
  const CartelaMarkColorPalette({
    required this.swatch,
    required this.fill,
    required this.border,
    required this.shadow,
    required this.text,
  });

  final Color swatch;
  final Color fill;
  final Color border;
  final Color shadow;
  final Color text;

  static CartelaMarkColorPalette forColor(CartelaMarkColor color) {
    return switch (color) {
      CartelaMarkColor.green => const CartelaMarkColorPalette(
        swatch: AppBranding.bingoFreeGreen,
        fill: AppBranding.bingoFreeGreen,
        border: AppBranding.feltGreen,
        shadow: AppBranding.bingoFreeGreen,
        text: Colors.white,
      ),
      CartelaMarkColor.red => CartelaMarkColorPalette(
        swatch: Colors.red.shade600,
        fill: Colors.red.shade600,
        border: Colors.red.shade800,
        shadow: Colors.red.shade600,
        text: Colors.white,
      ),
      CartelaMarkColor.yellow => CartelaMarkColorPalette(
        swatch: Colors.amber.shade600,
        fill: Colors.amber.shade500,
        border: Colors.amber.shade800,
        shadow: Colors.amber.shade600,
        text: const Color(0xFF422006),
      ),
      CartelaMarkColor.blue => CartelaMarkColorPalette(
        swatch: Colors.blue.shade600,
        fill: Colors.blue.shade600,
        border: Colors.blue.shade800,
        shadow: Colors.blue.shade600,
        text: Colors.white,
      ),
    };
  }
}
