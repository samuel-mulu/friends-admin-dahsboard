import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/time/server_clock_service.dart';
import 'package:friends_bingo_app/src/core/utils/api_date_time.dart';

void main() {
  test('synced clock corrects a device that is five minutes behind', () {
    final clock = ServerClockService();
    final deviceNow = DateTime.now().toUtc();
    final serverNow = deviceNow.add(const Duration(minutes: 5));
    final target = serverNow.add(const Duration(seconds: 30)).toLocal();

    clock.sync(serverNow, snap: true);

    expect(secondsUntilCeil(target, clock: clock), 30);
  });

  test('snap replaces offset immediately', () {
    final clock = ServerClockService();
    clock.sync(DateTime.now().toUtc().add(const Duration(seconds: 4)), snap: true);
    final first = clock.offsetMs!;

    clock.sync(DateTime.now().toUtc().add(const Duration(seconds: 9)), snap: true);

    expect(clock.offsetMs, greaterThan(first));
  });

  test('stale past target clamps to zero', () {
    final clock = ServerClockService();
    final serverNow = DateTime.now().toUtc();
    clock.sync(serverNow, snap: true);

    final target = serverNow.subtract(const Duration(seconds: 2)).toLocal();
    expect(secondsUntilCeil(target, clock: clock), 0);
  });
}
