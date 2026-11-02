import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/games_providers.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_state_patch.dart';
import 'registration_state_patch_provider.dart';

typedef RegistrationCartelaGridSummaryKey = (String sessionId, String cartelaId);

/// Per-cartela merged availability summary for the registration grid.
///
/// Watching this provider rebuilds only the chip whose patch/snapshot changed.
final registrationCartelaGridSummaryProvider = Provider.family<
    RegisteredCartelaSummary?,
    RegistrationCartelaGridSummaryKey>((ref, key) {
  final (sessionId, cartelaId) = key;
  if (sessionId.isEmpty || cartelaId.isEmpty) {
    return null;
  }

  final snapshotSummary =
      ref.watch(registrationTakenSummaryMapProvider(sessionId))[cartelaId];

  final sessionPatch = ref.watch(registrationStatePatchProvider)[sessionId];
  final patchSummary = sessionPatch?.patches[cartelaId];
  final isRemoved =
      sessionPatch?.removedCartelaIds.contains(cartelaId) ?? false;

  if (isRemoved) {
    return null;
  }

  return mergeCartelaSummaryWithPatch(
    base: snapshotSummary,
    patch: patchSummary,
  );
});
