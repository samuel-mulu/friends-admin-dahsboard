import 'package:flutter/widgets.dart';

/// Global spacing tokens for a tight, premium UI.
///
/// Keep these values small and consistent across the app.
abstract final class AppSpacing {
  // Base spacing scale (tight/premium).
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 20;
  static const double jumbo = 24;

  // Common insets.
  static const EdgeInsets screenPadding = EdgeInsets.all(xl); // 12
  static const EdgeInsets screenPaddingDense = EdgeInsets.all(md); // 8

  static const EdgeInsets cardPadding = EdgeInsets.all(xxl); // 16
  static const EdgeInsets cardPaddingDense = EdgeInsets.all(xl); // 12

  static const EdgeInsets sheetHorizontalPadding =
      EdgeInsets.symmetric(horizontal: xl); // 12

  // Common gaps.
  static const double sectionGap = xl; // 12
  static const double sectionGapDense = md; // 8
  static const double rowGap = sm; // 6
  static const double rowGapDense = xs; // 4
}

class VGap extends StatelessWidget {
  const VGap(this.height, {super.key});

  final double height;

  static const xxs = VGap(AppSpacing.xxs);
  static const xs = VGap(AppSpacing.xs);
  static const sm = VGap(AppSpacing.sm);
  static const md = VGap(AppSpacing.md);
  static const lg = VGap(AppSpacing.lg);
  static const xl = VGap(AppSpacing.xl);
  static const xxl = VGap(AppSpacing.xxl);

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class HGap extends StatelessWidget {
  const HGap(this.width, {super.key});

  final double width;

  static const xxs = HGap(AppSpacing.xxs);
  static const xs = HGap(AppSpacing.xs);
  static const sm = HGap(AppSpacing.sm);
  static const md = HGap(AppSpacing.md);
  static const lg = HGap(AppSpacing.lg);
  static const xl = HGap(AppSpacing.xl);
  static const xxl = HGap(AppSpacing.xxl);

  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}

