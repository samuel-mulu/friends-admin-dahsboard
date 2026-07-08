import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/registration_cartela_grid_index.dart';

CartelaModel _cartela(String id, int number) {
  return CartelaModel(
    id: id,
    number: number,
    createdAt: DateTime(2026, 6, 1),
  );
}

void main() {
  group('RegistrationCartelaGridIndex', () {
    final catalog = [
      _cartela('c-1', 1),
      _cartela('c-2', 12),
      _cartela('c-3', 45),
      _cartela('c-4', 99),
    ];

    test('filters by search query without rebuilding on availability-only updates',
        () {
      final index = RegistrationCartelaGridIndex();

      index.update(
        catalog: catalog,
        searchQuery: '1',
        shuffledCartelaIds: const ['c-3', 'c-1', 'c-2', 'c-4'],
      );

      expect(index.length, 2);
      expect(index.cartelaAt(0).number, 1);
      expect(index.cartelaAt(1).number, 12);

      index.update(
        catalog: catalog,
        searchQuery: '1',
        shuffledCartelaIds: const ['c-3', 'c-1', 'c-2', 'c-4'],
      );

      expect(index.length, 2);
    });

    test('sorts filtered results using shuffle order', () {
      final index = RegistrationCartelaGridIndex();

      index.update(
        catalog: catalog,
        searchQuery: '',
        shuffledCartelaIds: const ['c-3', 'c-1', 'c-2', 'c-4'],
      );

      expect(index.length, 4);
      expect(index.cartelaAt(0).number, 45);
      expect(index.cartelaAt(1).number, 1);
      expect(index.cartelaAt(2).number, 12);
      expect(index.cartelaAt(3).number, 99);
    });

    test('rebuilds when catalog version changes', () {
      final index = RegistrationCartelaGridIndex();

      index.update(
        catalog: catalog,
        searchQuery: '',
        shuffledCartelaIds: const ['c-1', 'c-2', 'c-3', 'c-4'],
      );
      expect(index.length, 4);

      index.update(
        catalog: [...catalog, _cartela('c-5', 100)],
        searchQuery: '',
        shuffledCartelaIds: const ['c-1', 'c-2', 'c-3', 'c-4', 'c-5'],
      );

      expect(index.length, 5);
      expect(index.cartelaAt(4).number, 100);
    });

    test('different shuffle ids produce different display order', () {
      final indexA = RegistrationCartelaGridIndex();
      final indexB = RegistrationCartelaGridIndex();

      indexA.update(
        catalog: catalog,
        searchQuery: '',
        shuffledCartelaIds: const ['c-3', 'c-1', 'c-2', 'c-4'],
      );
      indexB.update(
        catalog: catalog,
        searchQuery: '',
        shuffledCartelaIds: const ['c-4', 'c-2', 'c-3', 'c-1'],
      );

      final orderA = List.generate(
        indexA.length,
        (index) => indexA.cartelaAt(index).number,
      );
      final orderB = List.generate(
        indexB.length,
        (index) => indexB.cartelaAt(index).number,
      );

      expect(orderA, isNot(equals(orderB)));
    });

    test('skips client search filtering when serverSideSearch is enabled', () {
      final index = RegistrationCartelaGridIndex();

      index.update(
        catalog: catalog,
        searchQuery: '9',
        shuffledCartelaIds: const ['c-1', 'c-2', 'c-3', 'c-4'],
        serverSideSearch: true,
      );

      expect(index.length, 4);
    });
  });
}
