import 'package:friends_bingo_app/src/features/games/data/models/game_timing_config_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fullTimingConfigJson() => {
  'registrationDurationSeconds': 120,
  'autoCallIntervalSeconds': 15,
  'winnerWindowSeconds': 30,
  'cartelaHoldSeconds': 12,
  'finishedResultDisplaySeconds': 4,
  'winningPatternDisplaySeconds': 8,
  'preparingDisplayMaxSeconds': null,
  'missedNumberAnimationMs': 150,
  'missedNumberStaggerMaxBalls': 10,
  'flutterRefetchDebounceMs': 400,
};

void main() {
  test('parses full timing config payload', () {
    final config = GameTimingConfigModel.fromJson(_fullTimingConfigJson());

    expect(config.registrationDurationSeconds, 120);
    expect(config.autoCallIntervalSeconds, 15);
    expect(config.winnerWindowSeconds, 30);
    expect(config.cartelaHoldSeconds, 12);
    expect(config.winningPatternDisplaySeconds, 8);
    expect(config.winningPatternDisplayHold, const Duration(seconds: 8));
    expect(config.finishedSummaryMinimumHold, const Duration(seconds: 8));
  });

  test('finished summary hold defaults to 60 seconds when config is unavailable', () {
    const config = GameTimingConfigModel.fallback;

    expect(config.finishedSummaryMinimumHold, const Duration(seconds: 60));
  });

  test('fallback provides stable defaults when config is unavailable', () {
    const config = GameTimingConfigModel.fallback;

    expect(config.registrationDurationSeconds, 180);
    expect(config.autoCallIntervalSeconds, 18);
    expect(config.winnerWindowSeconds, 25);
    expect(config.cartelaHoldSeconds, 10);
    expect(config.flutterRefetchDebounceMs, 400);
  });

  test('throws when required timing fields are missing', () {
    final json = Map<String, dynamic>.from(_fullTimingConfigJson())
      ..remove('registrationDurationSeconds');

    expect(
      () => GameTimingConfigModel.fromJson(json),
      throwsFormatException,
    );
  });

  test('falls back to 10 seconds when winningPatternDisplaySeconds is absent', () {
    final config = GameTimingConfigModel.fromJson(_fullTimingConfigJson()
      ..remove('winningPatternDisplaySeconds'));

    expect(
      config.winningPatternDisplaySeconds,
      GameTimingConfigModel.defaultWinningPatternDisplaySeconds,
    );
    expect(config.finishedSummaryMinimumHold, const Duration(seconds: 10));
  });

  test('falls back to 25 seconds when winnerWindowSeconds is absent', () {
    final config = GameTimingConfigModel.fromJson(_fullTimingConfigJson()
      ..remove('winnerWindowSeconds'));

    expect(
      config.winnerWindowSeconds,
      GameTimingConfigModel.defaultWinnerWindowSeconds,
    );
  });
}
