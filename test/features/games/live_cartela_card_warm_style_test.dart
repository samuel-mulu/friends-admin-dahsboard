import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('LiveCartelaCard renders with warm ivory background, not pure white', (tester) async {
    final now = DateTime.now();
    final dummyCartela = CartelaModel(
      id: 'c1',
      number: 1074,
      createdAt: now,
      b: ['9', '4', '2', '5', '15'],
      i: ['30', '23', '24', '16', '26'],
      n: ['35', '42', 'FREE', '40', '33'],
      g: ['55', '56', '46', '50', '52'],
      o: ['63', '75', '65', '66', '61'],
    );
    final dummyGameCartela = GameCartelaModel(
      id: 'gc1',
      gameId: 'g1',
      userId: 'u1',
      cartelaId: 'c1',
      cartela: dummyCartela,
      isWinner: false,
      blockedAt: null,
      createdAt: now,
      updatedAt: now,
      status: GameCartelaStatus.registered,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.light().copyWith(
            extensions: const [LivePlayThemeTokens.light],
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 240,
                child: LiveCartelaCard(
                  gameCartela: dummyGameCartela,
                  canClaimBingo: false,
                  isClaiming: false,
                  pendingReview: false,
                  manualMarkedNumbers: const {},
                  onMarkedNumberToggled: (_, __, ___) {},
                  onClaimBingo: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card).first);
    expect(card.color, const Color(0xFFEAE3D5));
    expect(card.color, isNot(equals(Colors.white)));
  });
}
