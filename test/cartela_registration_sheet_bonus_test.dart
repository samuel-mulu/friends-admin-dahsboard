import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_reservation_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_registration_sheet.dart';

void main() {
  testWidgets(
    'bonus registration sheet shows free button and no balance warning',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamesRepositoryProvider.overrideWithValue(_FakeGamesRepository()),
            authControllerProvider.overrideWith(_FakeAuthController.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CartelaRegistrationSheet(
                cartela: CartelaModel(
                  id: 'cartela-7',
                  number: 7,
                  createdAt: DateTime.utc(2026, 1, 1),
                ),
                entryFee: '0',
                walletBalance: '0.00',
                slotId: 'slot-bonus',
                cartelaHoldSeconds: 30,
                category: GameCategory.bonus,
                fixedPrizeAmount: '5000.00',
                maxCartelasPerPlayer: 5,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bonus Game'), findsOneWidget);
      expect(find.text('Register Free'), findsOneWidget);
      expect(find.text('Insufficient balance'), findsNothing);
      expect(find.textContaining('Fixed prize:'), findsWidgets);
      expect(find.text('Max 5 cartelas'), findsOneWidget);
    },
  );
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState();
}

class _FakeGamesRepository extends GamesRepository {
  _FakeGamesRepository() : super(ApiClient(Dio()));

  @override
  Future<CartelaReservationModel> reserveCartelaForSlot({
    required String slotId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) async {
    return CartelaReservationModel(
      id: 'reservation-1',
      gameSessionId: 'session-bonus',
      cartelaId: cartelaId,
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      status: 'HELD',
      cartela: CartelaModel(
        id: cartelaId,
        number: 7,
        createdAt: DateTime.utc(2026, 1, 1),
        b: const ['1', '2', '3', '4', '5'],
        i: const ['16', '17', '18', '19', '20'],
        n: const ['31', '32', 'FREE', '34', '35'],
        g: const ['46', '47', '48', '49', '50'],
        o: const ['61', '62', '63', '64', '65'],
      ),
    );
  }

  @override
  Future<void> cancelReservation(String reservationId) async {}

  @override
  Future<GameCartelaModel> confirmReservation(String reservationId) {
    throw UnimplementedError();
  }
}
