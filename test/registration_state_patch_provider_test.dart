import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/registration_state_patch.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/registration_state_patch_provider.dart';

void main() {
  test('onSnapshotLoaded clears session patches', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(registrationStatePatchProvider.notifier);
    notifier.applyConfirmedChanges('session-a', [
      const RegistrationCartelaChange(
        cartelaId: 'cartela-1',
        cartelaNumber: 1,
        owner: 'RESERVED_ME',
      ),
    ]);

    expect(
      container.read(registrationStatePatchProvider)['session-a']?.patches,
      isNotEmpty,
    );

    notifier.onSnapshotLoaded('session-a');

    expect(container.read(registrationStatePatchProvider)['session-a'], isNull);
  });

  test('patches for one session do not affect another', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(registrationStatePatchProvider.notifier);
    notifier.applyConfirmedChanges('session-normal', [
      const RegistrationCartelaChange(
        cartelaId: 'cartela-1',
        cartelaNumber: 1,
        owner: 'RESERVED_OTHER',
      ),
    ]);

    final bigGameState = registrationStatePatchForSession(
      container.read(registrationStatePatchProvider),
      'session-big-game',
    );

    expect(bigGameState.patches, isEmpty);
  });
}
