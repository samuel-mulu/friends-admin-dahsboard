import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_response.dart';
import '../../../../core/network/pagination_meta.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../../domain/attended_game_history_state.dart';

final gameHistoryProvider =
    FutureProvider<PaginatedResponse<GameModel>>((ref) async {
  return ref.read(gamesRepositoryProvider).getGameHistory();
});

final attendedGameHistoryProvider =
    AsyncNotifierProvider<AttendedGameHistoryNotifier, AttendedGameHistoryState>(
      AttendedGameHistoryNotifier.new,
    );

class AttendedGameHistoryNotifier extends AsyncNotifier<AttendedGameHistoryState> {
  static const defaultPageSize = 50;

  @override
  Future<AttendedGameHistoryState> build() async {
    ref.watch(authControllerProvider);
    if (ref.read(authControllerProvider).session == null) {
      return AttendedGameHistoryState(
        entries: const [],
        pagination: PaginationMeta(
          page: 1,
          pageSize: defaultPageSize,
          totalItems: 0,
          totalPages: 0,
        ),
      );
    }

    return _fetchPage(page: 1);
  }

  Future<void> refresh() async {
    final previous = state.value;
    state = previous == null
        ? const AsyncLoading()
        : AsyncData(previous.copyWith(isLoadingMore: false));
    state = AsyncData(await _fetchPage(page: 1));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = await _fetchPage(page: current.pagination.page + 1);
      state = AsyncData(
        AttendedGameHistoryState(
          entries: [...current.entries, ...nextPage.entries],
          pagination: nextPage.pagination,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<AttendedGameHistoryState> _fetchPage({required int page}) async {
    final response = await ref
        .read(gamesRepositoryProvider)
        .getMyAttendedGameHistory(page: page, pageSize: defaultPageSize);

    return AttendedGameHistoryState(
      entries: response.items,
      pagination: response.pagination,
    );
  }
}
