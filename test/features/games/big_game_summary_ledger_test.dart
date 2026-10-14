import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/big_game_summary_ledger_storage.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/big_game_summary_ledger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost.invalid');
  });

  group('BigGameSummaryLedgerStorage', () {
    test('persists dismissed and survives reload', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = BigGameSummaryLedgerStorage(prefs);
      await storage.markDismissed(
        userId: 'user-1',
        slotId: 'slot-bg',
        sessionId: 's1',
      );
      expect(
        await storage.isDismissed(
          userId: 'user-1',
          slotId: 'slot-bg',
          sessionId: 's1',
        ),
        isTrue,
      );
      expect(
        await storage.isDismissed(
          userId: 'user-1',
          slotId: 'slot-bg',
          sessionId: 's2',
        ),
        isFalse,
      );

      // Simulate full app restart with same prefs mock.
      final storage2 = BigGameSummaryLedgerStorage(prefs);
      expect(
        await storage2.isDismissed(
          userId: 'user-1',
          slotId: 'slot-bg',
          sessionId: 's1',
        ),
        isTrue,
      );
    });
  });

  group('BigGameSummaryLedgerNotifier', () {
    test('markDismissed is immediate in memory before prefs settle', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _waitLedgerReady(container);
      expect(container.read(bigGameSummaryLedgerProvider).ready, isTrue);

      container.read(bigGameSummaryLedgerProvider.notifier).markDismissed(
            slotId: 'slot-bg',
            sessionId: 'finished-s1',
          );

      expect(
        container.read(bigGameSummaryLedgerProvider.notifier).isDismissed(
              slotId: 'slot-bg',
              sessionId: 'finished-s1',
            ),
        isTrue,
      );

      // Key uses finished session id, not a next-round id.
      expect(
        container.read(bigGameSummaryLedgerProvider.notifier).isDismissed(
              slotId: 'slot-bg',
              sessionId: 'next-s2',
            ),
        isFalse,
      );
    });

    test('in-memory dismiss survives slow prefs load merge', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _TestAuthController(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Mark before async load finishes — memory must win.
      container.read(bigGameSummaryLedgerProvider.notifier).markDismissed(
            slotId: 'slot-bg',
            sessionId: 's1',
          );
      expect(
        container.read(bigGameSummaryLedgerProvider.notifier).isDismissed(
              slotId: 'slot-bg',
              sessionId: 's1',
            ),
        isTrue,
      );

      await _waitLedgerReady(container);
      expect(
        container.read(bigGameSummaryLedgerProvider.notifier).isDismissed(
              slotId: 'slot-bg',
              sessionId: 's1',
            ),
        isTrue,
      );
    });
  });
}

Future<void> _waitLedgerReady(ProviderContainer container) async {
  for (var i = 0; i < 50; i++) {
    if (container.read(bigGameSummaryLedgerProvider).ready) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

AuthState _signedInAuthState() {
  return AuthState(
    session: AuthSession(
      accessToken: 'token',
      user: UserProfile(
        id: 'user-1',
        fullName: 'Test User',
        phoneNumber: '0911000000',
        role: UserRole.player,
        status: UserStatus.active,
        createdAt: DateTime.utc(2026, 8, 3, 12),
        updatedAt: DateTime.utc(2026, 8, 3, 12),
      ),
    ),
  );
}
