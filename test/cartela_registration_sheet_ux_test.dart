import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_reservation_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/cartela_board_preview_cache.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_registration_sheet.dart';

const _boardColumns = (
  b: ['1', '2', '3', '4', '5'],
  i: ['16', '17', '18', '19', '20'],
  n: ['31', '32', 'FREE', '34', '35'],
  g: ['46', '47', '48', '49', '50'],
  o: ['61', '62', '63', '64', '65'],
);

CartelaModel _cartela({bool withBoard = false}) {
  return CartelaModel(
    id: 'cartela-42',
    number: 42,
    createdAt: DateTime.utc(2026, 1, 1),
    b: withBoard ? _boardColumns.b : null,
    i: withBoard ? _boardColumns.i : null,
    n: withBoard ? _boardColumns.n : null,
    g: withBoard ? _boardColumns.g : null,
    o: withBoard ? _boardColumns.o : null,
  );
}

Widget _sheet({
  required GamesRepository repository,
  CartelaModel? cartela,
  String? sessionId = 'session-1',
  String entryFee = '10.00',
  String? walletBalance = '100.00',
  GameCategory category = GameCategory.normal,
}) {
  return ProviderScope(
    overrides: [
      gamesRepositoryProvider.overrideWithValue(repository),
      authControllerProvider.overrideWith(_FakeAuthController.new),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CartelaRegistrationSheet(
          cartela: cartela ?? _cartela(),
          entryFee: entryFee,
          walletBalance: walletBalance,
          slotId: 'slot-1',
          sessionId: sessionId,
          cartelaHoldSeconds: 30,
          category: category,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows cartela number immediately before reserve completes',
      (tester) async {
    final completer = Completer<CartelaReservationModel>();
    await tester.pumpWidget(
      _sheet(repository: _DelayedReserveRepository(completer)),
    );

    expect(find.text('42'), findsWidgets);
    expect(find.textContaining('Cartela #42'), findsOneWidget);
    expect(find.text('Preparing hold...'), findsOneWidget);
    expect(find.textContaining('30s'), findsNothing);

    completer.complete(_reservation(expiresInSeconds: 25));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hold time:'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('countdown does not tick before server expiresAt', (tester) async {
    final completer = Completer<CartelaReservationModel>();
    await tester.pumpWidget(
      _sheet(repository: _DelayedReserveRepository(completer)),
    );

    expect(find.text('…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('29s'), findsNothing);
    expect(find.textContaining('28s'), findsNothing);

    completer.complete(
      _reservation(expiresAt: DateTime.now().add(const Duration(seconds: 30))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('s'), findsWidgets);
  });

  testWidgets('register stays disabled until reserve succeeds', (tester) async {
    final completer = Completer<CartelaReservationModel>();
    await tester.pumpWidget(
      _sheet(repository: _DelayedReserveRepository(completer)),
    );

    final registerButton = find.widgetWithText(FilledButton, 'Preparing...');
    expect(registerButton, findsOneWidget);
    expect(
      tester.widget<FilledButton>(registerButton).onPressed,
      isNull,
    );

    completer.complete(_reservation());
    await tester.pumpAndSettle();

    final enabledRegister = find.widgetWithText(FilledButton, 'Register');
    expect(
      tester.widget<FilledButton>(enabledRegister).onPressed,
      isNotNull,
    );
  });

  testWidgets('cached board renders before reserve completes', (tester) async {
    final cached = _cartela(withBoard: true);
    CartelaBoardPreviewCache.put(cached);

    final completer = Completer<CartelaReservationModel>();
    await tester.pumpWidget(
      _sheet(
        repository: _DelayedReserveRepository(completer),
        cartela: cached,
      ),
    );

    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Loading board...'), findsNothing);

    completer.complete(_reservation());
    await tester.pumpAndSettle();
  });

  testWidgets('reserve failure shows inline modal error and try again',
      (tester) async {
    await tester.pumpWidget(
      _sheet(
        repository: _FailingReserveRepository(
          ApiException(message: 'Cartela already taken'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This cartela was just taken. Please choose another.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNotNull,
    );
  });

  testWidgets('insufficient balance shown inside modal after hold ready',
      (tester) async {
    await tester.pumpWidget(
      _sheet(
        repository: _ImmediateReserveRepository(),
        walletBalance: '1.00',
        entryFee: '10.00',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insufficient balance'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Insufficient balance'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('bonus modal does not show balance warning', (tester) async {
    await tester.pumpWidget(
      _sheet(
        repository: _ImmediateReserveRepository(),
        walletBalance: '0.00',
        entryFee: '0',
        category: GameCategory.bonus,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insufficient balance'), findsNothing);
    expect(find.text('Register Free'), findsOneWidget);
  });
}

CartelaReservationModel _reservation({
  int expiresInSeconds = 30,
  DateTime? expiresAt,
}) {
  return CartelaReservationModel(
    id: 'reservation-1',
    gameSessionId: 'session-1',
    cartelaId: 'cartela-42',
    expiresAt: expiresAt ?? DateTime.now().add(Duration(seconds: expiresInSeconds)),
    status: 'HELD',
    cartela: _cartela(withBoard: true),
  );
}

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState();
}

class _DelayedReserveRepository extends GamesRepository {
  _DelayedReserveRepository(this._completer) : super(ApiClient(Dio()));

  final Completer<CartelaReservationModel> _completer;

  @override
  Future<CartelaReservationModel> reserveCartela({
    required String sessionId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) {
    return _completer.future;
  }

  @override
  Future<CartelaReservationModel> reserveCartelaForSlot({
    required String slotId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) {
    return _completer.future;
  }

  @override
  Future<void> cancelReservation(String reservationId) async {}
}

class _ImmediateReserveRepository extends GamesRepository {
  _ImmediateReserveRepository() : super(ApiClient(Dio()));

  @override
  Future<CartelaReservationModel> reserveCartela({
    required String sessionId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) async {
    return _reservation();
  }

  @override
  Future<CartelaReservationModel> reserveCartelaForSlot({
    required String slotId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) async {
    return _reservation();
  }

  @override
  Future<void> cancelReservation(String reservationId) async {}

  @override
  Future<GameCartelaModel> confirmReservation(String reservationId) {
    throw UnimplementedError();
  }
}

class _FailingReserveRepository extends GamesRepository {
  _FailingReserveRepository(this.error) : super(ApiClient(Dio()));

  final ApiException error;

  @override
  Future<CartelaReservationModel> reserveCartela({
    required String sessionId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) {
    return Future.error(error);
  }

  @override
  Future<CartelaReservationModel> reserveCartelaForSlot({
    required String slotId,
    required String cartelaId,
    bool preserveOtherReservations = true,
  }) {
    return Future.error(error);
  }

  @override
  Future<void> cancelReservation(String reservationId) async {}
}
