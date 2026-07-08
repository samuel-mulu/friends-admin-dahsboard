import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_registration_target.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_registration_visibility.dart';

void main() {
  group('shouldShowInlineRegistrationPanel', () {
    test('hides next-round panel when live player already has cartelas', () {
      expect(
        shouldShowInlineRegistrationPanel(
          shouldShowRegistrationPanel: true,
          showsInlinePlayCartelas: true,
          hasCartelas: true,
          registrationTargetIsCurrentGame: false,
        ),
        isFalse,
      );
    });

    test('shows add-more panel when current round registration is open', () {
      expect(
        shouldShowInlineRegistrationPanel(
          shouldShowRegistrationPanel: true,
          showsInlinePlayCartelas: true,
          hasCartelas: true,
          registrationTargetIsCurrentGame: true,
        ),
        isTrue,
      );
    });

    test('shows next-round panel when player has no cartelas during live', () {
      expect(
        shouldShowInlineRegistrationPanel(
          shouldShowRegistrationPanel: true,
          showsInlinePlayCartelas: true,
          hasCartelas: false,
          registrationTargetIsCurrentGame: false,
        ),
        isTrue,
      );
    });

    test('expanded sticky layout disabled when no registration target', () {
      expect(
        usesExpandedNoCartelaRegistrationLayout(
          isGuest: false,
          hasCurrentCartelas: false,
          showsInlinePlayCartelas: true,
          registrationTarget: null,
        ),
        isFalse,
      );
    });

    test('returns false when registration panel is not applicable', () {
      expect(
        shouldShowInlineRegistrationPanel(
          shouldShowRegistrationPanel: false,
          showsInlinePlayCartelas: true,
          hasCartelas: true,
          registrationTargetIsCurrentGame: false,
        ),
        isFalse,
      );
    });
  });
}
