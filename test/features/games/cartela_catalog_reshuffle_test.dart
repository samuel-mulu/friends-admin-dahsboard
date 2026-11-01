import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_catalog_shuffle.dart';

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  List<CartelaModel> buildCatalog(int count) {
    return List<CartelaModel>.generate(
      count,
      (index) => CartelaModel(
        id: 'cartela-${index + 1}',
        number: index + 1,
        createdAt: now,
      ),
      growable: false,
    );
  }

  group('Catalog reshuffle pool consistency (BUG-04)', () {
    test(
      'reshuffleCatalogPool returns both the newly shuffled pool and matching first visible batch so subsequent pagination has zero duplicates',
      () {
        final pool = buildCatalog(120);
        final reshuffled = reshuffleCatalogPool(
          pool,
          batchSize: 60,
          random: Random(42),
        );

        expect(reshuffled.visibleBatch.length, 60);
        expect(reshuffled.pool.length, 120);
        expect(
          reshuffled.visibleBatch.map((c) => c.id).toList(),
          equals(reshuffled.pool.take(60).map((c) => c.id).toList()),
        );

        // Simulate loadMoreShuffledFromPool slicing the next 60 items from reshuffled.pool
        final secondBatch = reshuffled.pool.sublist(60, 120);
        final allLoadedIds = <String>{
          ...reshuffled.visibleBatch.map((c) => c.id),
          ...secondBatch.map((c) => c.id),
        };
        expect(allLoadedIds.length, 120);
      },
    );
  });
}

