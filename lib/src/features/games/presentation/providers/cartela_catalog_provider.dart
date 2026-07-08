import 'dart:async';

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
  static const searchPageSize = 300;

  static int pageLimit({required bool isSearch, required bool shuffle}) {
    if (isSearch) {
      return searchPageSize;
    }
    return defaultPageSize;
  }

  Timer? _searchDebounce;
  int _searchGeneration = 0;

  @override
  Future<CartelaCatalogState> build() async {
    final link = ref.keepAlive();
    ref.onDispose(() {
      link.close();
      _searchDebounce?.cancel();
    });

    return _fetchPage(search: '', cursor: null, shuffle: true);
  }

  Future<void> refresh() async {
    final previous = state.value;
    final search = previous?.searchQuery ?? '';
    final useShuffle = search.isEmpty;
    state = previous == null
        ? const AsyncLoading()
        : AsyncData(
            previous.copyWith(
              isLoadingMore: false,
              isShuffled: useShuffle,
              isSearchPending: false,
            ),
          );
    state = AsyncData(
      await _fetchPage(
        search: search,
        cursor: null,
        shuffle: useShuffle,
      ),
    );
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

  void setSearch(String query) {
    _searchDebounce?.cancel();
    final generation = ++_searchGeneration;

    final previous = state.value;
    if (previous != null && previous.searchQuery != query) {
      state = AsyncData(
        previous.copyWith(
          searchQuery: query,
          isLoadingMore: false,
          isShuffled: query.isEmpty,
          isSearchPending: query.isNotEmpty,
        ),
      );
    }

    final debounceMs = _searchDebounceMs(query);
    if (debounceMs == 0) {
      unawaited(_runSearchFetch(generation, query));
      return;
    }

    _searchDebounce = Timer(Duration(milliseconds: debounceMs), () {
      unawaited(_runSearchFetch(generation, query));
    });
  }

  int _searchDebounceMs(String query) {
    if (query.isEmpty) {
      return 0;
    }

    if (RegExp(r'^\d+$').hasMatch(query)) {
      return 120;
    }

    return 250;
  }

  Future<void> _runSearchFetch(int generation, String query) async {
    if (generation != _searchGeneration) {
      return;
    }

    final previous = state.value;
    if (previous != null && previous.searchQuery == query && !previous.isSearchPending) {
      return;
    }

    try {
      state = AsyncData(
        await _fetchPage(
          search: query,
          cursor: null,
          shuffle: query.isEmpty,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
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
    if (current == null ||
        current.isLoadingMore ||
        current.isSearchPending) {
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
      final nextPage = await _fetchPage(
        search: current.searchQuery,
        cursor: current.nextCursor,
      );
      state = AsyncData(
        CartelaCatalogState(
          items: [...current.items, ...nextPage.items],
          nextCursor: nextPage.nextCursor,
          total: nextPage.total ?? current.total,
          searchQuery: current.searchQuery,
          isShuffled: current.isShuffled,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<CartelaCatalogState> _fetchPage({
    required String search,
    required String? cursor,
    bool shuffle = false,
  }) async {
    final isSearch = search.isNotEmpty;
    final page = await ref.read(gamesRepositoryProvider).getCartelasPage(
      limit: pageLimit(isSearch: isSearch, shuffle: shuffle),
      cursor: cursor,
      search: isSearch ? search : null,
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
        searchQuery: search,
        isShuffled: true,
        isSearchPending: false,
      );
    }

    return CartelaCatalogState(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total,
      searchQuery: search,
      isShuffled: false,
      isSearchPending: false,
    );
  }
}
