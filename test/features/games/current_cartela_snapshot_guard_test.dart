import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/current_cartela_snapshot_guard.dart';

void main() {
  group('CurrentCartelaSnapshotGuard', () {
    test(
      'rejects stale same-session snapshot after confirmed registration bump',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.capture('session-a');
        guard.bumpForConfirmedRegistration('session-a');

        expect(guard.canApply(token, responseSessionId: 'session-a'), isFalse);
      },
    );

    test(
      'accepts legitimate fresh same-session reduction without mutation',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.capture('session-a');

        expect(guard.canApply(token, responseSessionId: 'session-a'), isTrue);
      },
    );

    test(
      'ignores response from prior session after switching to a new session',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.capture('session-a');
        guard.reset('session-b');

        expect(guard.canApply(token, responseSessionId: 'session-a'), isFalse);
      },
    );

    test(
      'READY to PLAYING same-session stale snapshot is rejected after registration bump',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.capture('session-a');
        guard.bumpForConfirmedRegistration('session-a');

        expect(guard.canApply(token, responseSessionId: 'session-a'), isFalse);
      },
    );
  });
}
