import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/models/game_model.dart';
import '../../domain/big_game_phase.dart';

/// Opt-in `[big-game]` console tracing for round handoffs / registration window.
///
/// Enabled in debug builds when `BIG_GAME_DEBUG=true` or `REALTIME_DEBUG=true`.
class BigGameDebug {
  BigGameDebug._();

  static bool get isEnabled =>
      kDebugMode &&
      (AppConfig.fromEnvironment().bigGameDebug ||
          AppConfig.fromEnvironment().realtimeDebug);

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('big-game', message);
  }

  static void phase({
    required BigGamePhase? from,
    required BigGamePhase to,
    required GameModel game,
    required DateTime now,
  }) {
    if (!isEnabled) {
      return;
    }
    final windowOpen = isBigGameRegistrationWindowOpen(game, now: now);
    log(
      'phase ${from?.name ?? '-'} -> ${to.name} '
      'round=${game.displayRoundIndex}/${game.displayRoundCount} '
      'status=${game.status.name} session=${game.sessionId ?? '-'} '
      'canRegister=${game.canRegister} windowOpen=$windowOpen '
      'regOpensAt=${game.registrationOpensAt?.toIso8601String() ?? '-'} '
      'playStartsAt=${game.scheduledStartAt?.toIso8601String() ?? '-'} '
      'nextRoundStartsAt=${game.nextRoundStartsAt?.toIso8601String() ?? '-'} '
      'nextReg=${game.nextRoundRegistration?.sessionId ?? '-'} '
      'now=${now.toIso8601String()}',
    );
  }

  static void snapshot(GameModel? game, {required String reason}) {
    if (!isEnabled) {
      return;
    }
    if (game == null) {
      log('snapshot reason=$reason game=null');
      return;
    }
    log(
      'snapshot reason=$reason '
      'round=${game.displayRoundIndex}/${game.displayRoundCount} '
      'status=${game.status.name} session=${game.sessionId ?? '-'} '
      'canRegister=${game.canRegister} '
      'regOpensAt=${game.registrationOpensAt?.toIso8601String() ?? '-'} '
      'playStartsAt=${game.scheduledStartAt?.toIso8601String() ?? '-'} '
      'nextRoundStartsAt=${game.nextRoundStartsAt?.toIso8601String() ?? '-'} '
      'nextRegSession=${game.nextRoundRegistration?.sessionId ?? '-'} '
      'nextRegCanRegister=${game.nextRoundRegistration?.canRegister}',
    );
  }
}
