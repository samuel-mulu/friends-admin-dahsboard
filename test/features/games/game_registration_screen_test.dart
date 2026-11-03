import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_catalog_provider.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_catalog_state.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/game_registration_screen.dart';

void main() {
  testWidgets('GameRegistrationScreen mounts with AppBar and body', (
    tester,
  ) async {
    final now = DateTime.now();
    final game = GameModel(
      id: 'slot-1',
      sessionId: 'session-123',
      staticCode: 'T-1',
      playCode: 'PLAY-T',
      name: 'Mega Bingo',
      gameRule: null,
      gameType: 'ONE_LINE',
      entryFee: '25.00',
      prizePerCartela: '20.00',
      companyFeePerCartela: '5.00',
      prizeAmount: '500.00',
      companyRevenue: '50.00',
      status: GameStatus.playing,
      playOrder: 1,
      startedAt: now,
      finishedAt: null,
      createdAt: now,
      updatedAt: now,
      registeredCartelasCount: 4,
      calledNumbersCount: 0,
      registrationOpen: true,
      canRegister: true,
      category: GameCategory.normal,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartelaCatalogProvider.overrideWith(
            () => _FakeCartelaCatalogNotifier(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: GameRegistrationScreen(game: game, isGuest: true),
        ),
      ),
    );

    await tester.pump();

    // Verify AppBar contains title or category fee
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(GameRegistrationScreen), findsOneWidget);
  });
}

class _FakeCartelaCatalogNotifier extends CartelaCatalogNotifier {
  @override
  Future<CartelaCatalogState> build() async {
    return const CartelaCatalogState(
      items: [],
      isLoadingMore: false,
    );
  }
}
