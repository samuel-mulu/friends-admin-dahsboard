import '../../data/models/game_model.dart';

/// KISS: never invent PLAYING from number_called — status_changed / ops own it.
bool shouldPromoteToPlayingFromNumberCalled({
  required GameStatus? currentStatus,
}) {
  return false;
}
