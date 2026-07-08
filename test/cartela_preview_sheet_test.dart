import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/cartela_board_preview_cache.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_preview_sheet.dart';

class _FakeGamesRepository extends Fake implements GamesRepository {}

void main() {
  testWidgets('preview sheet shows B-I-N-G-O board from cache', (tester) async {
    final cartela = CartelaModel(
      id: 'cartela-1',
      number: 14,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      b: const ['1', '2', '3', '4', '5'],
      i: const ['16', '17', '18', '19', '20'],
      n: const ['31', '32', 'FREE', '34', '35'],
      g: const ['46', '47', '48', '49', '50'],
      o: const ['61', '62', '63', '64', '65'],
    );

    CartelaBoardPreviewCache.put(cartela);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesRepositoryProvider.overrideWithValue(_FakeGamesRepository()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: FilledButton(
                  onPressed: () => showCartelaPreviewSheet(
                    context: context,
                    cartela: CartelaModel(
                      id: cartela.id,
                      number: cartela.number,
                      createdAt: cartela.createdAt,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('14'), findsWidgets);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Cartela preview'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
