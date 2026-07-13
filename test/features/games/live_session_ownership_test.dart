import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_session_ownership.dart';

void main() {
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

    test('returns true when primarySessionId matches liveSessionId', () {
      expect(
        ownsLiveSessionCartelas(
          liveSessionId: 'live-1',
          primarySessionId: 'live-1',
          cartelaSessionIds: const [],
        ),
        isTrue,
      );
    });

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

    test('returns false when neither primary nor cartelas match live', () {
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
