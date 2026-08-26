import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/current_cartela_snapshot_guard.dart';

void main() {
  group('CurrentCartelaSnapshotGuard', () {
    test(
      'CS-2 rejects stale same-session snapshot after confirmed registration bump',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.captureForFetch('session-a');
        guard.bumpForConfirmedRegistration('session-a');

        expect(
          guard.canApplyRemote(token, responseSessionId: 'session-a'),
          isFalse,
        );
      },
    );

    test(
      'CS-1 newer request sequence wins and older same-revision fetch is rejected',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final staleToken = guard.captureForFetch('session-a');
        final freshToken = guard.captureForFetch('session-a');

        expect(
          guard.canApplyRemote(freshToken, responseSessionId: 'session-a'),
          isTrue,
        );
        guard.markRemoteApplied(freshToken);

        expect(
          guard.canApplyRemote(staleToken, responseSessionId: 'session-a'),
          isFalse,
        );
        expect(guard.lastAppliedRequestSeq, 2);
      },
    );

    test(
      'CS-6 newer authoritative remote snapshot can replace with fewer cartelas',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final firstToken = guard.captureForFetch('session-a');
        guard.markRemoteApplied(firstToken);

        final secondToken = guard.captureForFetch('session-a');
        expect(
          guard.canApplyRemote(secondToken, responseSessionId: 'session-a'),
          isTrue,
        );
      },
    );

    test(
      'CS-4 rejects remote apply when request sequence token is missing',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final legacyToken = guard.capture('session-a');

        expect(
          guard.canApplyRemote(legacyToken, responseSessionId: 'session-a'),
          isFalse,
        );
      },
    );

    test(
      'CS-7 ignores response from prior session after switching to a new session',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.captureForFetch('session-a');
        guard.reset('session-b');

        expect(
          guard.canApplyRemote(token, responseSessionId: 'session-a'),
          isFalse,
        );
      },
    );

    test(
      'CS-11 READY to PLAYING stale snapshot rejected after registration bump',
      () {
        final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

        final token = guard.captureForFetch('session-a');
        guard.bumpForConfirmedRegistration('session-a');

        expect(
          guard.canApplyRemote(token, responseSessionId: 'session-a'),
          isFalse,
        );
      },
    );

    test('next-registration legacy capture still uses revision-only canApply', () {
      final guard = CurrentCartelaSnapshotGuard()..reset('session-a');

      final token = guard.capture('session-a');

      expect(guard.canApply(token, responseSessionId: 'session-a'), isTrue);
      expect(
        guard.canApplyRemote(token, responseSessionId: 'session-a'),
        isFalse,
      );
    });
  });
}
