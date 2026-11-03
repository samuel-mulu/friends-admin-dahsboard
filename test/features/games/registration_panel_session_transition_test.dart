import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_panel_session.dart';

void main() {
  group('RegistrationPanelSession cross-round transition (BUG-13)', () {
    test(
      'syncSessionId preserves selection when resolving null sessionId to initial session-1',
      () {
        final session = RegistrationPanelSession()
          ..selectModeEnabled = true
          ..selectedCartelaIds.add('c-1')
          ..selectedCartelaNumbers['c-1'] = 1;

        final resetOccurred = session.syncSessionId('session-1');

        expect(resetOccurred, isFalse);
        expect(session.resolvedSessionId, 'session-1');
        expect(session.selectModeEnabled, isTrue);
        expect(session.selectedCartelaIds, contains('c-1'));
      },
    );

    test(
      'syncSessionId clears trackedRegisteredCartelas and selection state when transitioning from session-1 to session-2 on same slot',
      () {
        final now = DateTime.utc(2026, 8, 7, 12);
        final session = RegistrationPanelSession()
          ..resolvedSessionId = 'session-1'
          ..selectModeEnabled = true
          ..selectedCartelaIds.add('c-1')
          ..selectedCartelaNumbers['c-1'] = 1
          ..registeringCartelaIds.add('c-2')
          ..trackedRegisteredCartelas = [
            GameCartelaModel(
              id: 'gc-1',
              gameId: 'session-1',
              userId: 'user-1',
              cartelaId: 'c-1',
              status: GameCartelaStatus.registered,
              isWinner: false,
              blockedAt: null,
              createdAt: now,
              updatedAt: now,
              cartela: CartelaModel(id: 'c-1', number: 1, createdAt: now),
            ),
          ];

        final resetOccurred = session.syncSessionId('session-2');

        expect(resetOccurred, isTrue);
        expect(session.resolvedSessionId, 'session-2');
        expect(session.trackedRegisteredCartelas, isEmpty);
        expect(session.selectedCartelaIds, isEmpty);
        expect(session.selectedCartelaNumbers, isEmpty);
        expect(session.registeringCartelaIds, isEmpty);
        expect(session.selectModeEnabled, isFalse);
      },
    );
  });
}
