/// Layout math for the registration cartela number grid.
class RegistrationCartelaGridLayout {
  const RegistrationCartelaGridLayout._();

  static const crossAxisCount = 8;
  static const mainAxisSpacing = 4.0;
  static const crossAxisSpacing = 4.0;
  static const childAspectRatio = 1.2;

  /// Smallest chip height that stays tappable when the grid compresses to fit.
  static const minReadableCellHeight = 24.0;

  /// True when every [itemCount] tile can fit in [maxHeight] without scrolling.
  static bool fitsWithoutScrolling({
    required double maxWidth,
    required double maxHeight,
    required int itemCount,
  }) {
    if (!maxWidth.isFinite ||
        !maxHeight.isFinite ||
        maxWidth <= 0 ||
        maxHeight <= 0 ||
        itemCount <= 0) {
      return true;
    }

    final rows = (itemCount / crossAxisCount).ceil();
    final cellWidth =
        (maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
    if (cellWidth <= 0) {
      return false;
    }

    final compressedCellHeight =
        (maxHeight - (rows - 1) * mainAxisSpacing) / rows;
    return compressedCellHeight >= minReadableCellHeight;
  }

  static double aspectRatioForItemCount({
    required double maxWidth,
    required double maxHeight,
    required int itemCount,
  }) {
    if (!maxWidth.isFinite ||
        !maxHeight.isFinite ||
        maxWidth <= 0 ||
        maxHeight <= 0 ||
        itemCount <= 0) {
      return childAspectRatio;
    }

    final rows = (itemCount / crossAxisCount).ceil();
    final cellWidth =
        (maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
    if (cellWidth <= 0) {
      return childAspectRatio;
    }

    final cellHeight = (maxHeight - (rows - 1) * mainAxisSpacing) / rows;
    if (cellHeight <= 0) {
      return childAspectRatio;
    }

    return cellWidth / cellHeight;
  }
}
