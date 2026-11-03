import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_mark_helpers.dart';

final _now = DateTime.utc(2026, 10, 15);

CalledNumberModel _call({
  required String letter,
  required int number,
  required int order,
  String sessionId = 'session-a',
}) {
  return CalledNumberModel(
    id: 'call-$order',
    sessionId: sessionId,
    letter: letter,
    number: number,
    order: order,
    createdAt: _now.add(Duration(seconds: order)),
  );
}

GameCartelaModel _cartela({
  required String id,
  required List<List<String>> columns,
}) {
  return GameCartelaModel(
    id: id,
    gameId: 'game-1',
    userId: 'user-1',
    cartelaId: 'cartela-$id',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: _now,
    updatedAt: _now,
    cartela: CartelaModel(
      id: 'cartela-$id',
      number: 1,
      createdAt: _now,
      b: columns[0],
      i: columns[1],
      n: columns[2],
      g: columns[3],
      o: columns[4],
    ),
  );
}

void main() {
  group('visualMarkedNumbers / Auto Mark runtime', () {
    final called = [
      _call(letter: 'B', number: 5, order: 1),
      _call(letter: 'I', number: 20, order: 2),
      _call(letter: 'N', number: 35, order: 3),
    ];

    test('Auto Mark OFF preserves manual-only marks', () {
      final manual = {'B:5', 'G:50'};
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: manual,
        calledNumbers: called,
        effectiveAutoMark: false,
      );

      expect(visual, {'B:5', 'G:50'});
      expect(visual.contains('I:20'), isFalse);
      expect(visual.contains('N:35'), isFalse);
    });

    test('Auto Mark ON marks matching called numbers', () {
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: {'G:50'},
        calledNumbers: called,
        effectiveAutoMark: true,
      );

      expect(visual, containsAll(['B:5', 'I:20', 'N:35', 'G:50']));
    });

    test('uncalled numbers remain unmarked when Auto Mark ON', () {
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: const {},
        calledNumbers: called,
        effectiveAutoMark: true,
      );

      expect(visual.contains('O:75'), isFalse);
      expect(visual.contains('B:1'), isFalse);
    });

    test('manual marks remain when Auto Mark is disabled', () {
      final manual = {'B:5', 'O:72'};
      final withAuto = visualMarkedNumbers(
        manualMarkedNumbers: manual,
        calledNumbers: called,
        effectiveAutoMark: true,
      );
      final withoutAuto = visualMarkedNumbers(
        manualMarkedNumbers: manual,
        calledNumbers: called,
        effectiveAutoMark: false,
      );

      expect(withAuto, containsAll(['B:5', 'I:20', 'N:35', 'O:72']));
      expect(withoutAuto, {'B:5', 'O:72'});
    });

    test('automatic marks disappear when Auto Mark disabled', () {
      final afterDisable = visualMarkedNumbers(
        manualMarkedNumbers: {'G:50'},
        calledNumbers: called,
        effectiveAutoMark: false,
      );

      expect(afterDisable, {'G:50'});
      expect(afterDisable.contains('B:5'), isFalse);
    });

    test('admin revoke (effectiveAutoMark false) drops only auto marks', () {
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: {'I:16'},
        calledNumbers: called,
        effectiveAutoMark: false,
      );

      expect(visual, {'I:16'});
    });

    test('multiple cartelas intersect shared visual marks independently', () {
      final cartelaA = _cartela(
        id: 'a',
        columns: [
          ['5', '6', '7', '8', '9'],
          ['16', '17', '18', '19', '20'],
          ['31', '32', 'FREE', '34', '35'],
          ['46', '47', '48', '49', '50'],
          ['61', '62', '63', '64', '65'],
        ],
      );
      final cartelaB = _cartela(
        id: 'b',
        columns: [
          ['1', '2', '3', '4', '10'],
          ['16', '17', '18', '19', '21'],
          ['31', '32', 'FREE', '34', '36'],
          ['46', '47', '48', '49', '51'],
          ['61', '62', '63', '64', '66'],
        ],
      );

      final visual = visualMarkedNumbers(
        manualMarkedNumbers: {'G:50'},
        calledNumbers: called,
        effectiveAutoMark: true,
      );

      final marksA = manualMarksForCartela(
        cartela: cartelaA,
        manualMarkedNumbers: visual,
      );
      final marksB = manualMarksForCartela(
        cartela: cartelaB,
        manualMarkedNumbers: visual,
      );

      expect(marksA, containsAll(['B:5', 'I:20', 'N:35', 'G:50']));
      expect(marksB.contains('B:5'), isFalse);
      expect(marksB.contains('I:20'), isFalse);
      expect(marksB.contains('N:35'), isFalse);
      expect(marksB.contains('G:50'), isFalse);
    });

    test('duplicate called-number keys are idempotent', () {
      final withDupes = [
        ...called,
        _call(letter: 'B', number: 5, order: 4),
        _call(letter: 'B', number: 5, order: 1),
      ];
      final keys = calledNumberMarkKeys(withDupes);
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: const {},
        calledNumbers: withDupes,
        effectiveAutoMark: true,
      );

      expect(keys, {'B:5', 'I:20', 'N:35'});
      expect(visual, {'B:5', 'I:20', 'N:35'});
    });

    test('reconnect snapshot restores auto marks from authoritative calls', () {
      final snapshot = [
        _call(letter: 'B', number: 12, order: 1),
        _call(letter: 'O', number: 70, order: 2),
      ];
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: {'N:33'},
        calledNumbers: snapshot,
        effectiveAutoMark: true,
      );

      expect(visual, {'N:33', 'B:12', 'O:70'});
    });

    test('new session / empty called strip clears previous automatic marks', () {
      final previous = visualMarkedNumbers(
        manualMarkedNumbers: {'G:46'},
        calledNumbers: called,
        effectiveAutoMark: true,
      );
      expect(previous.contains('B:5'), isTrue);

      final nextSession = visualMarkedNumbers(
        manualMarkedNumbers: {'G:46'},
        calledNumbers: const <CalledNumberModel>[],
        effectiveAutoMark: true,
      );

      expect(nextSession, {'G:46'});
      expect(nextSession.contains('B:5'), isFalse);
    });

    test('Chain / Big Game round boundary uses only current-session calls', () {
      final priorRoundCalls = [
        _call(letter: 'B', number: 1, order: 1, sessionId: 'chain-r1'),
      ];
      final currentRoundCalls = [
        _call(letter: 'I', number: 22, order: 1, sessionId: 'chain-r2'),
      ];

      // Callers must pass the active session strip only — never union rounds.
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: const {},
        calledNumbers: currentRoundCalls,
        effectiveAutoMark: true,
      );

      expect(visual, {'I:22'});
      expect(
        visualMarkedNumbers(
          manualMarkedNumbers: const {},
          calledNumbers: priorRoundCalls,
          effectiveAutoMark: true,
        ),
        {'B:1'},
      );
      expect(visual.contains('B:1'), isFalse);
    });

    test('manual mark persistence set is unchanged by visual derivation', () {
      final manual = {'B:5', 'O:61'};
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: manual,
        calledNumbers: called,
        effectiveAutoMark: true,
      );

      // Persistence path must keep using the original manual set.
      expect(normalizeManualMarkedNumbers(manual), {'B:5', 'O:61'});
      expect(visual.length, greaterThan(manual.length));
      expect(identical(visual, manual), isFalse);
    });

    test('lastActiveMarkKeyForDisplay follows manual key when Auto Mark OFF', () {
      expect(
        lastActiveMarkKeyForDisplay(
          effectiveAutoMark: false,
          lastManualMarkedKey: 'G:50',
          calledNumbers: called,
        ),
        'G:50',
      );
    });

    test('lastActiveMarkKeyForDisplay uses latest call when Auto Mark ON', () {
      expect(
        lastActiveMarkKeyForDisplay(
          effectiveAutoMark: true,
          lastManualMarkedKey: 'G:50',
          calledNumbers: called,
        ),
        'N:35',
      );
    });

    test('lastActiveMarkKeyForDisplay falls back when Auto Mark ON and no calls', () {
      expect(
        lastActiveMarkKeyForDisplay(
          effectiveAutoMark: true,
          lastManualMarkedKey: 'O:61',
          calledNumbers: const [],
        ),
        'O:61',
      );
    });

    test('isManuallyMarkedCell reuses existing highlight rules for auto marks', () {
      final visual = visualMarkedNumbers(
        manualMarkedNumbers: const {},
        calledNumbers: called,
        effectiveAutoMark: true,
      );

      expect(
        isManuallyMarkedCell(
          manualMarkedNumbers: visual,
          header: 'B',
          value: '5',
        ),
        isTrue,
      );
      expect(
        isManuallyMarkedCell(
          manualMarkedNumbers: visual,
          header: 'O',
          value: '75',
        ),
        isFalse,
      );
      expect(
        isManuallyMarkedCell(
          manualMarkedNumbers: visual,
          header: 'N',
          value: 'FREE',
        ),
        isTrue,
      );
    });
  });
}
