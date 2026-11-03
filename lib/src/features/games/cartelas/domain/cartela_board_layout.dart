/// Shared 5×5 cartela board layout values for live play and winner review.
abstract final class CartelaBoardLayout {
  /// Inset inside each grid slot; matches [CartelaPatternProgressPainter] cell inset.
  static const double cellPadding = 2.0;

  /// Gap between live-play cell slots (aligned with pattern progress geometry).
  static const double liveCellGap = 3.0;
  static const double boardPadding = 2.0;
  static const double boardBorderRadius = 6.0;
  static const double headerToGridGap = 2.0;

  static const double liveHeaderFontSize = 10.0;
  static const double liveBingoLetterRowHeight = 18.0;
  static const double reviewHeaderFontSize = 13.0;
  static const double compactReviewHeaderFontSize = 9.0;

  /// Target sizes; [FittedBox] scales down to fit the cell circle.
  static const double liveCellNumberFontSize = 28.0;
  static const double liveFreeFontSize = 28.0;
  static const double reviewCellNumberFontSize = 32.0;
  static const double compactReviewCellNumberFontSize = 22.0;

  /// Fraction of cell diameter used for number text (maximizes readability).
  static const double cellNumberDiameterFactor = 0.58;

  /// Live 2-up grid: slightly smaller type so cells feel balanced, not oversized.
  static const double liveExpandedCellNumberFactor = 0.54;

  /// Header row + gap + square board area for review dialogs (width / height).
  static const double reviewBoardAspectRatio = 0.86;

  /// Largest number font that still fits inside a circular cell.
  static double maximizedCellNumberFontSize(double diameter) {
    if (diameter <= 0) {
      return liveCellNumberFontSize;
    }
    return diameter * cellNumberDiameterFactor;
  }

  static double liveExpandedCellNumberFontSize(double cellSide) {
    if (cellSide <= 0) {
      return liveCellNumberFontSize;
    }
    final circleDiameter = cellSide - (cellPadding * 2);
    final basis = circleDiameter > 0 ? circleDiameter : cellSide;
    return basis * liveExpandedCellNumberFactor;
  }

  static double liveGridCellSlotSize(double boardWidth) {
    if (boardWidth <= 0) {
      return 0;
    }
    return (boardWidth - (liveCellGap * 4)) / 5;
  }

  /// Grid tile width/height for live 2-up layout (matches [LiveCartelaCard] + square board).
  static double liveTwoUpTileAspectRatio(double tileWidth) {
    if (tileWidth <= 0) {
      return 0.80;
    }
    const outerCartelaHeader = 34.0;
    const cardHorizontalInset = 4.0;
    final boardBodyWidth = tileWidth - cardHorizontalInset;
    final innerBoardHeight =
        liveBingoLetterRowHeight + boardBodyWidth + boardPadding;
    final tileHeight = outerCartelaHeader + innerBoardHeight;
    return tileWidth / tileHeight;
  }
}
