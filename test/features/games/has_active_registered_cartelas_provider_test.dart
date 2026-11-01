import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/providers/has_active_registered_cartelas_provider.dart';

void main() {
  group('HasActiveRegisteredCartelasNotifier (BUG-09)', () {
    test('updateSessionState(null, 0) clears activeSessionId to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        hasActiveRegisteredCartelasProvider.notifier,
      );
      notifier.updateSessionState(
        'session-1',
        3,
        requiresLeaveConfirmation: true,
      );
      final populated = container.read(hasActiveRegisteredCartelasProvider);
      expect(populated.activeSessionId, 'session-1');
      expect(populated.registeredCartelaCount, 3);
      expect(populated.requiresLeaveConfirmation, isTrue);

      notifier.updateSessionState(
        null,
        0,
        requiresLeaveConfirmation: false,
      );
      final cleared = container.read(hasActiveRegisteredCartelasProvider);
      expect(cleared.activeSessionId, isNull);
      expect(cleared.registeredCartelaCount, 0);
      expect(cleared.requiresLeaveConfirmation, isFalse);
      expect(cleared.hasActiveRegisteredCartelas, isFalse);
    });
  });
}
