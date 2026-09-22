import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_model.dart';

/// While set, [BigGameScreen] keeps this FINISHED round as the shell primary
/// even when `/games/big-game/current` already returns Round N+1 READY.
final bigGameFinishedSummaryPinProvider = StateProvider<GameModel?>(
  (ref) => null,
);
