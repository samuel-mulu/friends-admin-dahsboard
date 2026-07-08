import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/games_repository.dart';
import '../../data/models/cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/registration_state_model.dart';
import '../../domain/cartela_board_preview_cache.dart';

final cartelasProvider = FutureProvider<List<CartelaModel>>((ref) async {
  final link = ref.keepAlive();
  ref.onDispose(link.close);

  final cartelas = await ref.watch(gamesRepositoryProvider).getCartelas();
  for (final cartela in cartelas) {
    CartelaBoardPreviewCache.put(cartela);
  }
  return cartelas;
});

final registrationStateProvider =
    FutureProvider.family<RegistrationStateResponse, String>((ref, sessionId) async {
      return ref.watch(gamesRepositoryProvider).getRegistrationState(sessionId);
    });

/// O(1) taken-cartela lookup for the registration grid (avoids per-chip linear scans).
final registrationTakenSummaryMapProvider =
    Provider.family<Map<String, RegisteredCartelaSummary>, String>((
      ref,
      sessionId,
    ) {
      final state = ref.watch(registrationStateProvider(sessionId)).asData?.value;
      if (state == null) {
        return const {};
      }

      final map = <String, RegisteredCartelaSummary>{
        for (final summary in state.registeredCartelasSummary)
          summary.cartelaId: summary,
      };

      for (final summary in state.reservedCartelasSummary) {
        map[summary.cartelaId] = summary;
      }

      return map;
    });
