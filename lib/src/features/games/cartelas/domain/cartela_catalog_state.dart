import '../data/models/cartela_model.dart';

class CartelaCatalogState {
  const CartelaCatalogState({
    required this.items,
    this.shuffledPool = const [],
    this.nextCursor,
    this.total,
    this.searchQuery = '',
    this.isLoadingMore = false,
    this.isShuffled = false,
    this.isReshuffling = false,
    this.isSearchPending = false,
  });

  final List<CartelaModel> items;
  final List<CartelaModel> shuffledPool;
  final String? nextCursor;
  final int? total;
  final String searchQuery;
  final bool isLoadingMore;
  final bool isShuffled;
  final bool isReshuffling;
  final bool isSearchPending;

  bool get hasMore =>
      !isShuffled && nextCursor != null && nextCursor!.isNotEmpty;

  bool get hasMoreShufflePool =>
      isShuffled && items.length < shuffledPool.length;

  CartelaCatalogState copyWith({
    List<CartelaModel>? items,
    List<CartelaModel>? shuffledPool,
    String? nextCursor,
    int? total,
    String? searchQuery,
    bool? isLoadingMore,
    bool? isShuffled,
    bool? isReshuffling,
    bool? isSearchPending,
  }) {
    return CartelaCatalogState(
      items: items ?? this.items,
      shuffledPool: shuffledPool ?? this.shuffledPool,
      nextCursor: nextCursor ?? this.nextCursor,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isShuffled: isShuffled ?? this.isShuffled,
      isReshuffling: isReshuffling ?? this.isReshuffling,
      isSearchPending: isSearchPending ?? this.isSearchPending,
    );
  }
}
