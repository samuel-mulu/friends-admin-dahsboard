import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_session_ownership.dart';

void main() {
  group('ownsSessionByCartelas', () {
    test('requested A, cartelas contain A → true', () {
      expect(
        ownsSessionByCartelas('session-a', const ['session-a']),
        isTrue,
      );
    });

    test('requested A, cartelas contain B → false', () {
      expect(
        ownsSessionByCartelas('session-a', const ['session-b']),
        isFalse,
      );
    });

    test('null or empty session → false', () {
      expect(ownsSessionByCartelas(null, const ['session-a']), isFalse);
      expect(ownsSessionByCartelas('', const ['session-a']), isFalse);
    });

    test('empty cartela list → false', () {
      expect(ownsSessionByCartelas('session-a', const []), isFalse);
    });
  });

  group('ownsSession', () {
    test('requested A, cartelas contain A → true', () {
      expect(
        ownsSession('session-a', const ['session-a']),
        isTrue,
      );
    });

    test('requested A, cartelas contain B → false', () {
      expect(
        ownsSession('session-a', const ['session-b']),
        isFalse,
      );
    });

    test('primarySession match alone does NOT grant ownership', () {
      expect(
        ownsSession(
          'session-a',
          const [],
          primarySessionId: 'session-a',
        ),
        isFalse,
      );
    });

    test('requested A, cartelas B, primary B → false', () {
      expect(
        ownsSession(
          'session-a',
          const ['session-b'],
          primarySessionId: 'session-b',
        ),
        isFalse,
      );
    });

    test('null session → false', () {
      expect(
        ownsSession(null, const ['session-a'], primarySessionId: 'session-a'),
        isFalse,
      );
    });
  });

  group('ownsLiveSessionCartelas', () {
    test('returns false when liveSessionId is null or empty', () {
      expect(
        ownsLiveSessionCartelas(
          liveSessionId: null,
          primarySessionId: 'live-1',
          cartelaSessionIds: const ['live-1'],
        ),
        isFalse,
      );
      expect(
        ownsLiveSessionCartelas(
          liveSessionId: '',
          primarySessionId: 'live-1',
          cartelaSessionIds: const ['live-1'],
        ),
        isFalse,
      );
    });

    test(
      'Player 2: primary matches live but no cartelas → false (missed entry)',
      () {
        expect(
          ownsLiveSessionCartelas(
            liveSessionId: 'live-1',
            primarySessionId: 'live-1',
            cartelaSessionIds: const [],
          ),
          isFalse,
        );
      },
    );

    test('returns true when a cartela session matches live despite stale primary', () {
      expect(
        ownsLiveSessionCartelas(
          liveSessionId: 'live-1',
          primarySessionId: 'ready-2',
          cartelaSessionIds: const ['live-1', 'other'],
        ),
        isTrue,
      );
    });

    test('returns false when cartelas only match registration primary', () {
      expect(
        ownsLiveSessionCartelas(
          liveSessionId: 'live-1',
          primarySessionId: 'ready-2',
          cartelaSessionIds: const ['ready-2'],
        ),
        isFalse,
      );
      expect(
        ownsLiveSessionCartelas(
          liveSessionId: 'live-1',
          primarySessionId: null,
          cartelaSessionIds: const [],
        ),
        isFalse,
      );
    });
  });
}
