import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/games_repository.dart';
import '../../domain/cartela_board_preview_cache.dart';
import '../../domain/cartela_catalog_shuffle.dart';
import '../../domain/cartela_catalog_state.dart';

final cartelaCatalogProvider =
    AsyncNotifierProvider<CartelaCatalogNotifier, CartelaCatalogState>(
      CartelaCatalogNotifier.new,
    );

class CartelaCatalogNotifier extends AsyncNotifier<CartelaCatalogState> {
  static const defaultPageSize = 5000;

  @override
  Future<CartelaCatalogState> build() async {
    final link = ref.keepAlive();
    ref.onDispose(link.close);

    return _fetchPage(cursor: null, shuffle: true);
  }

  Future<void> refresh() async {
    final previous = state.value;
    state = previous == null
        ? const AsyncLoading()
        : AsyncData(
            previous.copyWith(
              isLoadingMore: false,
              isShuffled: true,
              isSearchPending: false,
            ),
          );
    state = AsyncData(await _fetchPage(cursor: null, shuffle: true));
  }

  Future<void> reshuffle() async {
    final previous = state.value;
    if (previous == null ||
        !previous.isShuffled ||
        previous.shuffledPool.isEmpty) {
      return;
    }

    state = AsyncData(previous.copyWith(isReshuffling: true));

    final visibleItems = CartelaCatalogShuffle.visibleBatchFromPool(
      previous.shuffledPool,
      reshuffle: true,
    );

    state = AsyncData(
      previous.copyWith(
        items: visibleItems,
        isReshuffling: false,
      ),
    );
  }

  Future<void> loadMoreShuffledFromPool() async {
    final current = state.value;
    if (current == null ||
        !current.hasMoreShufflePool ||
        current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    final nextVisibleCount = CartelaCatalogShuffle.nextVisibleCount(
      currentVisibleCount: current.items.length,
      poolLength: current.shuffledPool.length,
    );
    final nextItems = CartelaCatalogShuffle.visibleSliceFromPool(
      current.shuffledPool,
      visibleCount: nextVisibleCount,
    );

    state = AsyncData(
      current.copyWith(
        items: nextItems,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore) {
      return;
    }

    if (current.isShuffled) {
      await loadMoreShuffledFromPool();
      return;
    }

    if (!current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = await _fetchPage(cursor: current.nextCursor);
      state = AsyncData(
        CartelaCatalogState(
          items: [...current.items, ...nextPage.items],
          nextCursor: nextPage.nextCursor,
          total: nextPage.total ?? current.total,
          isShuffled: current.isShuffled,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<CartelaCatalogState> _fetchPage({
    required String? cursor,
    bool shuffle = false,
  }) async {
    final page = await ref.read(gamesRepositoryProvider).getCartelasPage(
      limit: defaultPageSize,
      cursor: cursor,
      shuffle: shuffle,
    );

    for (final cartela in page.items) {
      CartelaBoardPreviewCache.put(cartela);
    }

    if (shuffle) {
      final pool = page.items;
      final visibleItems = CartelaCatalogShuffle.visibleBatchFromPool(pool);

      return CartelaCatalogState(
        items: visibleItems,
        shuffledPool: pool,
        nextCursor: page.nextCursor,
        total: page.total,
        isShuffled: true,
      );
    }

    return CartelaCatalogState(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total,
      isShuffled: false,
    );
  }
}
