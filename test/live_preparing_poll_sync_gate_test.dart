import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_preparing_poll_sync_gate.dart';

void main() {
  test('skips preparing poll while resume sync is in flight', () {
    expect(
      shouldSkipPreparingPollDuringSync(
        resumeSyncInFlight: true,
        canonicalRefetchInFlight: false,
      ),
      isTrue,
    );
  });

  test('skips preparing poll while canonical refetch is in flight', () {
    expect(
      shouldSkipPreparingPollDuringSync(
        resumeSyncInFlight: false,
        canonicalRefetchInFlight: true,
      ),
      isTrue,
    );
  });

  test('allows preparing poll when idle', () {
    expect(
      shouldSkipPreparingPollDuringSync(
        resumeSyncInFlight: false,
        canonicalRefetchInFlight: false,
      ),
      isFalse,
    );
  });
}
