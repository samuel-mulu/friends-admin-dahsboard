import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/cartela_catalog_shuffle.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/cartela_catalog_provider.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/registration_cartela_grid_layout.dart';

CartelaModel _cartela(String id, int number) {
  return CartelaModel(
    id: id,
    number: number,
    createdAt: DateTime(2026, 6, 1),
  );
}

void main() {
  group('CartelaCatalogNotifier.pageLimit', () {
    test('uses full catalog page size for shuffle browse mode', () {
      expect(
        CartelaCatalogNotifier.pageLimit(isSearch: false, shuffle: true),
        CartelaCatalogNotifier.defaultPageSize,
      );
    });

    test('uses 300 for search mode', () {
      expect(
        CartelaCatalogNotifier.pageLimit(isSearch: true, shuffle: false),
        CartelaCatalogNotifier.searchPageSize,
      );
    });
  });

  group('CartelaCatalogShuffle', () {
    final pool = List<CartelaModel>.generate(
      4000,
      (index) => _cartela('c-$index', index + 1),
    );

    test('shows up to 3000 cartelas from a larger shuffled pool', () {
      final visible = CartelaCatalogShuffle.visibleBatchFromPool(pool);

      expect(visible, hasLength(CartelaCatalogShuffle.displayBatchSize));
      expect(
        visible.map((cartela) => cartela.id).toSet(),
        hasLength(CartelaCatalogShuffle.displayBatchSize),
      );
    });

    test('reshuffle picks a different 3000 window from the same pool', () {
      final first = CartelaCatalogShuffle.visibleBatchFromPool(pool);
      final second = CartelaCatalogShuffle.visibleBatchFromPool(
        pool,
        reshuffle: true,
        random: Random(22),
      );

      expect(first, hasLength(CartelaCatalogShuffle.displayBatchSize));
      expect(second, hasLength(CartelaCatalogShuffle.displayBatchSize));
      expect(
        first.map((cartela) => cartela.id).toList(),
        isNot(equals(second.map((cartela) => cartela.id).toList())),
      );
    });

    test('shows the full pool when it is smaller than the display batch', () {
      final smallPool = pool.take(2500).toList(growable: false);
      final visible = CartelaCatalogShuffle.visibleBatchFromPool(smallPool);

      expect(visible, hasLength(2500));
    });
  });

  group('RegistrationCartelaGridLayout', () {
    test('fits all shuffled items into the available height', () {
      const itemCount = 3000;
      const maxWidth = 800.0;
      const maxHeight = 16000.0;

      expect(
        RegistrationCartelaGridLayout.fitsWithoutScrolling(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          itemCount: itemCount,
        ),
        isTrue,
      );

      final aspectRatio = RegistrationCartelaGridLayout.aspectRatioForItemCount(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        itemCount: itemCount,
      );
      final rows = (itemCount / RegistrationCartelaGridLayout.crossAxisCount)
          .ceil();
      final cellWidth =
          (maxWidth -
                  (RegistrationCartelaGridLayout.crossAxisCount - 1) *
                      RegistrationCartelaGridLayout.crossAxisSpacing) /
              RegistrationCartelaGridLayout.crossAxisCount;
      final cellHeight = cellWidth / aspectRatio;
      final totalHeight =
          rows * cellHeight + (rows - 1) * RegistrationCartelaGridLayout.mainAxisSpacing;

      expect(totalHeight, lessThanOrEqualTo(maxHeight + 0.01));
    });

    test('requires scrolling on a normal registration panel height', () {
      expect(
        RegistrationCartelaGridLayout.fitsWithoutScrolling(
          maxWidth: 400,
          maxHeight: 520,
          itemCount: CartelaCatalogShuffle.displayBatchSize,
        ),
        isFalse,
      );
    });
  });

  group('CartelaCatalogShuffle pool paging', () {
    test('nextVisibleCount grows in displayBatchSize steps', () {
      expect(
        CartelaCatalogShuffle.nextVisibleCount(
          currentVisibleCount: 3000,
          poolLength: 4500,
        ),
        4500,
      );
      expect(
        CartelaCatalogShuffle.nextVisibleCount(
          currentVisibleCount: 3000,
          poolLength: 8000,
        ),
        6000,
      );
    });

    test('visibleSliceFromPool exposes more of the same shuffled pool', () {
      final pool = List<CartelaModel>.generate(
        4500,
        (index) => _cartela('c-$index', index + 1),
      );

      final first = CartelaCatalogShuffle.visibleSliceFromPool(
        pool,
        visibleCount: 3000,
      );
      final second = CartelaCatalogShuffle.visibleSliceFromPool(
        pool,
        visibleCount: 4500,
      );

      expect(first, hasLength(3000));
      expect(second, hasLength(4500));
      expect(
        second.take(3000).map((cartela) => cartela.id).toList(),
        equals(first.map((cartela) => cartela.id).toList()),
      );
    });
  });
}
