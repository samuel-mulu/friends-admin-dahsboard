import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_availability.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/controllers/live_registration_controller.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_action_result.dart';

void main() {
  group('Bulk selection rebuild isolation (BUG-11)', () {
    test(
      'toggleCartelaSelection mutates panel session without triggering root host.markNeedsBuild()',
      () {
        final host = _CountingLiveGameHost();
        final controller = LiveRegistrationController(host);

        final selectResult = controller.toggleCartelaSelection(
          slotId: 'slot-1',
          cartela: const RegistrationCartelaSelectionInput(
            cartelaId: 'c-1',
            cartelaNumber: 1,
            availability: CartelaAvailability.available,
          ),
          maxAffordable: 5,
          limitKind: RegistrationLimitKind.normal,
        );

        expect(selectResult, isA<RegistrationActionSuccess>());
        expect(
          controller.panelSessionFor('slot-1').selectedCartelaIds,
          contains('c-1'),
        );
        expect(
          host.markNeedsBuildCount,
          0,
          reason:
              'Chip selection in _CartelaRegistrationPanel must not rebuild the entire LiveGameScreen',
        );

        final unselectResult = controller.toggleCartelaSelection(
          slotId: 'slot-1',
          cartela: const RegistrationCartelaSelectionInput(
            cartelaId: 'c-1',
            cartelaNumber: 1,
            availability: CartelaAvailability.reservedByMe,
          ),
          maxAffordable: 5,
          limitKind: RegistrationLimitKind.normal,
        );

        expect(unselectResult, isA<RegistrationActionSuccess>());
        expect(
          controller.panelSessionFor('slot-1').selectedCartelaIds,
          isEmpty,
        );
        expect(host.markNeedsBuildCount, 0);
      },
    );
  });
}

class _CountingLiveGameHost extends Fake implements LiveGameHost {
  int markNeedsBuildCount = 0;

  @override
  bool mounted = true;

  @override
  bool isLiveHostActive = true;

  @override
  bool isGuest = false;

  @override
  final GamesRepository gamesRepository = GamesRepository(ApiClient(Dio()));

  @override
  GameModel? game;

  @override
  void markNeedsBuild([VoidCallback? fn]) {
    markNeedsBuildCount += 1;
    fn?.call();
  }
}

