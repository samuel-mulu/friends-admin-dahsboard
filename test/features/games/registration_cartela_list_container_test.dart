import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_cartela_list_container.dart';

CartelaModel _sampleCartela(int number) {
  final now = DateTime.utc(2026, 1, 1);
  return CartelaModel(
    id: 'cartela-$number',
    number: number,
    createdAt: now,
    b: ['1', '2', '3', '4', '5'],
    i: ['16', '17', '18', '19', '20'],
    n: ['31', '32', 'FREE', '34', '35'],
    g: ['46', '47', '48', '49', '50'],
    o: ['61', '62', '63', '64', '65'],
  );
}

void main() {
  group('RegistrationCartelaListContainer', () {
    testWidgets('renders loading state when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegistrationCartelaListContainer(
              cartelas: const [],
              isLoading: true,
              itemBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegistrationCartelaListContainer(
              cartelas: const [],
              errorMessage: 'Network timeout',
              itemBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.text('Could not load cartelas'), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('renders empty card when cartelas is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RegistrationCartelaListContainer(
              cartelas: const [],
              emptyTitle: 'No matches found',
              emptyMessage: 'Try another search.',
              itemBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),
      );

      expect(find.text('No matches found'), findsOneWidget);
      expect(find.text('Try another search.'), findsOneWidget);
    });

    testWidgets('renders cartelas in grid layout', (tester) async {
      final items = List.generate(10, (i) => _sampleCartela(i + 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: RegistrationCartelaListContainer(
                cartelas: items,
                layout: RegistrationCartelaContainerLayout.grid,
                itemBuilder: (context, cartela, index) {
                  return Text('Item ${cartela.number}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('renders cartelas in list layout', (tester) async {
      final items = List.generate(5, (i) => _sampleCartela(i + 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 600,
              child: RegistrationCartelaListContainer(
                cartelas: items,
                layout: RegistrationCartelaContainerLayout.list,
                itemBuilder: (context, cartela, index) {
                  return Text('ListRow ${cartela.number}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SliverList), findsOneWidget);
      expect(find.text('ListRow 1'), findsOneWidget);
    });
  });
}
