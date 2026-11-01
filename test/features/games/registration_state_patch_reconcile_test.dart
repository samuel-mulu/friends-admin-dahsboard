import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/providers/registration_state_patch_provider.dart';
import 'package:friends_bingo_app/src/features/games/registration/data/models/registration_state_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_state_patch.dart';

void main() {
  group('RegistrationStatePatchNotifier reconciliation & priority (BUG-05, BUG-14)', () {
    test(
      'onSnapshotLoaded(sessionId, snapshot: ...) retains un-acknowledged socket patches while clearing acknowledged ones (BUG-05)',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(registrationStatePatchProvider.notifier);

        // Two socket patches arrive while HTTP snapshot is in flight:
        // c-1 is already included in the HTTP snapshot; c-2 arrived after the snapshot was generated.
        notifier.applyChanges('session-1', const [
          RegistrationCartelaChange(
            cartelaId: 'c-1',
            cartelaNumber: 1,
            owner: 'ME',
          ),
          RegistrationCartelaChange(
            cartelaId: 'c-2',
            cartelaNumber: 2,
            owner: 'OTHER',
          ),
        ]);

        final snapshot = RegistrationStateResponse(
          sessionId: 'session-1',
          registeredCartelasSummary: const [
            RegisteredCartelaSummary(
              cartelaId: 'c-1',
              cartelaNumber: 1,
              owner: 'ME',
              status: 'REGISTERED',
            ),
          ],
          myCartelaIds: const ['c-1'],
        );

        notifier.onSnapshotLoaded('session-1', snapshot: snapshot);

        final stateAfter = notifier.stateFor('session-1');
        expect(
          stateAfter.patches.containsKey('c-1'),
          isFalse,
          reason: 'c-1 is already present in the canonical snapshot and should be pruned',
        );
        expect(
          stateAfter.patches['c-2']?.owner,
          'OTHER',
          reason: 'c-2 is not yet in the snapshot and must not be wiped on snapshot load',
        );
      },
    );

    test(
      'applyChanges allows newer RESERVED_ME / RESERVED_OTHER changes to replace an older ME / OTHER patch (BUG-14)',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(registrationStatePatchProvider.notifier);

        notifier.applyChanges('session-1', const [
          RegistrationCartelaChange(
            cartelaId: 'c-10',
            cartelaNumber: 10,
            owner: 'OTHER',
          ),
        ]);
        expect(notifier.stateFor('session-1').patches['c-10']?.owner, 'OTHER');

        final expiresAt = DateTime.utc(2026, 8, 7, 12, 5);
        notifier.applyChanges('session-1', [
          RegistrationCartelaChange(
            cartelaId: 'c-10',
            cartelaNumber: 10,
            owner: 'RESERVED_ME',
            expiresAt: expiresAt,
          ),
        ]);

        expect(
          notifier.stateFor('session-1').patches['c-10']?.owner,
          'RESERVED_ME',
        );
      },
    );
  });
}

