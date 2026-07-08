/// Shared 5×5 cartela board layout values for live play and winner review.
abstract final class CartelaBoardLayout {
  static const double cellPadding = 0.5;
  static const double boardPadding = 2.0;
  static const double boardBorderRadius = 6.0;
  static const double headerToGridGap = 2.0;

  static const double liveHeaderFontSize = 10.0;
  static const double reviewHeaderFontSize = 13.0;
  static const double compactReviewHeaderFontSize = 9.0;

  static const double liveCellNumberFontSize = 11.0;
  static const double liveFreeFontSize = 11.0;
  static const double reviewCellNumberFontSize = 15.0;
  static const double compactReviewCellNumberFontSize = 11.0;

  /// Header row + gap + square board area for review dialogs.
  static const double reviewBoardAspectRatio = 1.08;
}
