import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_branding.dart';

/// Calculates luminance-based relative contrast ratio per WCAG 2.1 specs.
double contrastRatio(Color fg, Color bg) {
  final l1 = fg.computeLuminance();
  final l2 = bg.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Warm Amber & Emerald Lounge Theme Tokens Contrast', () {
    test('Primary text on warm surface meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppBranding.warmOnSurface, AppBranding.warmSurfaceRaised);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'warmOnSurface must be crisp on warmSurfaceRaised');
    });

    test('Muted text on warm surface meets WCAG AA for large text or normal text (>= 4.0:1)', () {
      final ratio = contrastRatio(AppBranding.warmOnSurfaceMuted, AppBranding.warmSurfaceRaised);
      expect(ratio, greaterThanOrEqualTo(4.0), reason: 'warmOnSurfaceMuted must have solid readability');
    });

    test('White text on emerald daub fill meets WCAG AA for graphics/large text (>= 3.0:1)', () {
      final ratio = contrastRatio(Colors.white, AppBranding.emeraldDaubFill);
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'White text on emerald dauber must be high contrast');
    });

    test('Gold button text on gold button meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppBranding.bingoGoldButtonText, AppBranding.bingoGoldButton);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Dark brown text on gold button must be readable');
    });

    test('Coral pill text on coral pill background meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppBranding.coralPillText, AppBranding.coralPill);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Coral text on coral pill must be readable');
    });

    test('Emerald pill text on emerald pill background meets WCAG AA (>= 4.5:1)', () {
      final ratio = contrastRatio(AppBranding.emeraldPillText, AppBranding.emeraldPill);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Emerald text on emerald pill must be readable');
    });
  });
}

