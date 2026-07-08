import '../../../../core/utils/api_date_time.dart';
import '../../data/models/game_model.dart';
import 'socket_payload_normalizer.dart';

class NumberCalledSchedulePatch {
  const NumberCalledSchedulePatch({
    required this.game,
    required this.scheduleChanged,
    this.autoCallEnabled,
  });

  final GameModel game;
  final bool scheduleChanged;
  final bool? autoCallEnabled;
}

DateTime? parseNextAutoCallAtFromPayload(Map<String, dynamic> payload) {
  final raw = payload['nextAutoCallAt'];
  if (raw is String) {
    return parseApiDateTime(raw);
  }
  if (raw is DateTime) {
    return raw.toLocal();
  }
  return null;
}

bool? parseAutoCallEnabledFromPayload(Map<String, dynamic> payload) {
  final raw = payload['autoCallEnabled'];
  if (raw is bool) {
    return raw;
  }
  return null;
}

int? parseAutoCallIntervalMsFromPayload(Map<String, dynamic> payload) {
  final raw = payload['autoCallIntervalMs'];
  if (raw is num) {
    return raw.round();
  }
  return null;
}

bool dateTimesEqualForSchedule(DateTime? left, DateTime? right) {
  if (left == null && right == null) {
    return true;
  }
  if (left == null || right == null) {
    return false;
  }
  return left.isAtSameMomentAs(right);
}

/// Applies socket schedule fields from [game:number_called] onto [game].
NumberCalledSchedulePatch patchGameFromNumberCalledPayload(
  GameModel game,
  dynamic payload,
) {
  final normalizedPayload = normalizeSocketPayload(payload);
  if (normalizedPayload == null) {
    return NumberCalledSchedulePatch(
      game: game,
      scheduleChanged: false,
      autoCallEnabled: null,
    );
  }

  var scheduleChanged = false;
  var patched = game;

  if (normalizedPayload.containsKey('nextAutoCallAt')) {
    final nextAutoCallAt = parseNextAutoCallAtFromPayload(normalizedPayload);
    if (!dateTimesEqualForSchedule(nextAutoCallAt, game.nextAutoCallAt)) {
      scheduleChanged = true;
    }
    patched = patched.copyWith(nextAutoCallAt: nextAutoCallAt);
  }

  final autoCallEnabled = parseAutoCallEnabledFromPayload(normalizedPayload);
  if (autoCallEnabled == false && game.nextAutoCallAt != null) {
    scheduleChanged = true;
    patched = patched.copyWith(nextAutoCallAt: null);
  }

  final intervalMs = parseAutoCallIntervalMsFromPayload(normalizedPayload);
  if (intervalMs != null && intervalMs != game.autoCallIntervalMs) {
    scheduleChanged = true;
    patched = patched.copyWith(autoCallIntervalMs: intervalMs);
  }

  return NumberCalledSchedulePatch(
    game: patched,
    scheduleChanged: scheduleChanged,
    autoCallEnabled: autoCallEnabled,
  );
}
