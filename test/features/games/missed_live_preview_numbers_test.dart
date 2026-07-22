import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/missed_live_preview_numbers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/next_ball_countdown.dart';

CalledNumberModel _n(String sessionId, int number, int order) {
  return CalledNumberModel(
    id: '$sessionId-$order',
    sessionId: sessionId,
    letter: 'N',
    number: number,
    order: order,
    createdAt: DateTime.utc(2026, 7, 22),
  );
}

void main() {
  group('missed preview number helpers', () {
    test('filters by session and keeps recent tail', () {
      final shared = [
        _n('a', 1, 1),
        _n('b', 9, 1),
        _n('a', 2, 2),
        _n('a', 3, 3),
        _n('a', 4, 4),
        _n('a', 5, 5),
        _n('a', 6, 6),
      ];
      final recent = filterMissedPreviewCalledNumbers(
        sharedCalledNumbers: shared,
        previewSessionId: 'a',
        previewLimit: 3,
      );
      expect(recent.map((e) => e.number), [4, 5, 6]);
      expect(missedPreviewActiveNumber(recent), 6);
    });

    test('remaining prefers session calledNumbersCount', () {
      final now = DateTime.utc(2026, 7, 22);
      final session = GameModel(
        id: 'id-a',
        sessionId: 'a',
        staticCode: 'A',
        playCode: 'A',
        name: 'A',
        gameRule: null,
        gameType: 'NORMAL',
        entryFee: '10',
        prizePerCartela: '8',
        companyFeePerCartela: '2',
        prizeAmount: '0',
        companyRevenue: '0',
        status: GameStatus.playing,
        playOrder: 1,
        startedAt: now,
        finishedAt: null,
        createdAt: now,
        updatedAt: now,
        registeredCartelasCount: 1,
        calledNumbersCount: 10,
        registrationOpen: false,
        canRegister: false,
      );
      expect(
        missedPreviewRemainingCount(
          previewSession: session,
          filteredPreviewLength: 3,
        ),
        kMaxBingoBalls - 10,
      );
    });
  });
}
