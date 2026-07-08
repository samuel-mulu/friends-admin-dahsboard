import 'dart:math';

import '../data/models/cartela_model.dart';

class CartelaCatalogShuffle {
  const CartelaCatalogShuffle._();

  static const displayBatchSize = 3000;

  static List<CartelaModel> visibleBatchFromPool(
    List<CartelaModel> pool, {
    int batchSize = displayBatchSize,
    bool reshuffle = false,
    Random? random,
  }) {
    if (pool.isEmpty) {
      return const [];
    }

    final working = pool.toList();
    if (reshuffle) {
      working.shuffle(random ?? Random());
    }

    return visibleSliceFromPool(
      working,
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
