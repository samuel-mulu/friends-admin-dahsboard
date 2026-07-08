import '../../../core/network/pagination_meta.dart';
import 'attended_game_history_entry.dart';

/// Paginated attended game history for the signed-in player.
class AttendedGameHistoryState {
  const AttendedGameHistoryState({
    required this.entries,
    required this.pagination,
    this.isLoadingMore = false,
  });

  final List<AttendedGameHistoryEntry> entries;
  final PaginationMeta pagination;
  final bool isLoadingMore;

  bool get hasMore => pagination.page < pagination.totalPages;

  AttendedGameHistoryState copyWith({
    List<AttendedGameHistoryEntry>? entries,
    PaginationMeta? pagination,
    bool? isLoadingMore,
  }) {
    return AttendedGameHistoryState(
      entries: entries ?? this.entries,
      pagination: pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
