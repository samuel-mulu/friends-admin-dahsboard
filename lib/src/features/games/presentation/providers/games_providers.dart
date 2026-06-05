import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/games_repository.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';

final currentLiveGameProvider = FutureProvider<GameModel?>((ref) async {
  return ref.watch(gamesRepositoryProvider).getCurrentLiveGame();
});

final cartelasProvider = FutureProvider<List<CartelaModel>>((ref) async {
  return ref.watch(gamesRepositoryProvider).getCartelas();
});

final myGameCartelasProvider =
    FutureProvider.family<List<GameCartelaModel>, String>((ref, gameId) async {
      return ref.watch(gamesRepositoryProvider).getMyGameCartelas(gameId);
    });
