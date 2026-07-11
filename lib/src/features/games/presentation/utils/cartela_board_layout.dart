/// Shared 5×5 cartela board layout values for live play and winner review.
abstract final class CartelaBoardLayout {
  static const double cellPadding = 0.5;
  static const double boardPadding = 2.0;
  static const double boardBorderRadius = 6.0;
  static const double headerToGridGap = 2.0;

  static const double liveHeaderFontSize = 10.0;
  static const double reviewHeaderFontSize = 13.0;
  static const double compactReviewHeaderFontSize = 9.0;

  /// Target sizes; [FittedBox] scales down to fit the cell circle.
  static const double liveCellNumberFontSize = 28.0;
  static const double liveFreeFontSize = 28.0;
  static const double reviewCellNumberFontSize = 32.0;
  static const double compactReviewCellNumberFontSize = 22.0;

  /// Fraction of cell diameter used for number text (maximizes readability).
  static const double cellNumberDiameterFactor = 0.58;

  /// Header row + gap + square board area for review dialogs.
  static const double reviewBoardAspectRatio = 1.08;

  /// Largest number font that still fits inside a circular cell.
  static double maximizedCellNumberFontSize(double diameter) {
    if (diameter <= 0) {
      return liveCellNumberFontSize;
    }
    return diameter * cellNumberDiameterFactor;
  }
}
