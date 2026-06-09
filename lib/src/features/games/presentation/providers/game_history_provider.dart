import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/paginated_response.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';

final gameHistoryProvider =
    FutureProvider<PaginatedResponse<GameModel>>((ref) async {
  return ref.read(gamesRepositoryProvider).getGameHistory();
});
