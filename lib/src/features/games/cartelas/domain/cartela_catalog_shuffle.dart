import 'dart:math';

import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_catalog_limits.dart';

({List<CartelaModel> pool, List<CartelaModel> visibleBatch})
reshuffleCatalogPool(
  List<CartelaModel> pool, {
  int batchSize = CartelaCatalogShuffle.displayBatchSize,
  Random? random,
}) {
  if (pool.isEmpty) {
    return (pool: const [], visibleBatch: const []);
  }

  final working = pool.toList(growable: false)..shuffle(random ?? Random());
  final visibleBatch = CartelaCatalogShuffle.visibleSliceFromPool(
    working,
    visibleCount: batchSize,
  );
  return (pool: working, visibleBatch: visibleBatch);
}

class CartelaCatalogShuffle {
  const CartelaCatalogShuffle._();

  static const displayBatchSize = CartelaCatalogLimits.visibleBatchSize;

  static List<CartelaModel> visibleBatchFromPool(
    List<CartelaModel> pool, {
    int batchSize = displayBatchSize,
    bool reshuffle = false,
    Random? random,
  }) {
    if (pool.isEmpty) {
      return const [];
    }

    if (reshuffle) {
      return reshuffleCatalogPool(
        pool,
        batchSize: batchSize,
        random: random,
      ).visibleBatch;
    }

    return visibleSliceFromPool(
      pool,
      visibleCount: batchSize,
    );
  }

  /// Next visible window from an already-shuffled [pool].
  static List<CartelaModel> visibleSliceFromPool(
    List<CartelaModel> pool, {
    required int visibleCount,
  }) {
    if (pool.isEmpty || visibleCount <= 0) {
      return const [];
    }

    final take = visibleCount < pool.length ? visibleCount : pool.length;
    return pool.take(take).toList(growable: false);
  }

  static int nextVisibleCount({
    required int currentVisibleCount,
    required int poolLength,
    int batchSize = displayBatchSize,
  }) {
    if (currentVisibleCount >= poolLength) {
      return poolLength;
    }

    final next = currentVisibleCount + batchSize;
    return next < poolLength ? next : poolLength;
  }
}
