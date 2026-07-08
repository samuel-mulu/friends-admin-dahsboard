import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_model.dart';
import '../../domain/registration_state_patch.dart';
import 'games_providers.dart';
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

  final snapshotSummary = ref.watch(
    registrationTakenSummaryMapProvider(sessionId).select(
      (map) => map[cartelaId],
    ),
  );

  final patchSummary = ref.watch(
    registrationStatePatchProvider.select(
      (all) => all[sessionId]?.patches[cartelaId],
    ),
  );
  final isRemoved = ref.watch(
    registrationStatePatchProvider.select(
      (all) => all[sessionId]?.removedCartelaIds.contains(cartelaId) ?? false,
    ),
  );

  if (isRemoved) {
    return null;
  }

  return mergeCartelaSummaryWithPatch(
    base: snapshotSummary,
    patch: patchSummary,
  );
});
