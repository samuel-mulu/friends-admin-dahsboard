import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/debug/live_realtime_debug.dart';

void main() {
  test('LiveRealtimeDebug is disabled without REALTIME_DEBUG define', () {
    expect(LiveRealtimeDebug.isEnabled, isFalse);
  });
}
