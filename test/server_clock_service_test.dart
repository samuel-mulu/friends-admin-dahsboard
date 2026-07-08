import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/time/server_clock_service.dart';

void main() {
  test('updates offset on each sync', () {
    final clock = ServerClockService();

    clock.sync(DateTime.now().toUtc(), snap: true);
    expect(clock.isSynced, isTrue);
    expect(clock.offsetMs, isNotNull);

    clock.sync(DateTime.now().toUtc().add(const Duration(seconds: 2)), snap: true);
    expect(clock.offsetMs!, greaterThan(1000));
  });

  test('ignoreOlder rejects regressing serverNow', () {
    final clock = ServerClockService();
    final newer = DateTime.utc(2026, 6, 10, 12, 0, 10);
    final older = DateTime.utc(2026, 6, 10, 12, 0, 5);

    expect(clock.sync(newer, snap: true), isTrue);
    final offsetAfterNewer = clock.offsetMs;

    expect(clock.sync(older, snap: true, ignoreOlder: true), isFalse);
    expect(clock.offsetMs, offsetAfterNewer);
    expect(clock.lastServerNowUtc, newer);
  });

  test('nowUtc applies stored offset', () {
    final clock = ServerClockService();
    final beforeDevice = DateTime.now().toUtc();
    clock.sync(beforeDevice.add(const Duration(seconds: 7)), snap: true);

    final effective = clock.nowUtc();
    final expectedMin = beforeDevice.add(const Duration(seconds: 6));
    final expectedMax = beforeDevice.add(const Duration(seconds: 8));

    expect(effective.isAfter(expectedMin), isTrue);
    expect(effective.isBefore(expectedMax), isTrue);
  });
}
