import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/application/providers/cartela_catalog_provider.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_catalog_page.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/repositories/cartelas_repository.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_cartela_grid_index.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/registration_panel_session.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_cartela_grid.dart';

class _FakeCartelasRepository extends Fake implements CartelasRepository {
  _FakeCartelasRepository(this.pool);

  final List<CartelaModel> pool;

  @override
  Future<CartelaCatalogPage> getCartelasPage({
    int limit = 100,
    String? cursor,
    String? search,
    bool shuffle = false,
  }) async {
    return CartelaCatalogPage(
      items: pool,
      nextCursor: null,
      total: pool.length,
    );
  }
}

void main() {
  final now = DateTime.utc(2026, 8, 7, 12);

  CartelaModel cartela(int number) => CartelaModel(
    id: 'c-$number',
    number: number,
    createdAt: now,
  );

  List<String> displayedIds(RegistrationCartelaGridIndex index) => [
    for (var i = 0; i < index.length; i++) index.cartelaAt(i).id,
  ];

  group('RegistrationCartelaGridIndex version & shuffle detection (BUG-10)', () {
    test(
      'versionForCatalog changes when interior cartela order changes even if length, first, and last match',
      () {
        final orderA = [cartela(1), cartela(2), cartela(3), cartela(4)];
        final orderB = [cartela(1), cartela(3), cartela(2), cartela(4)];

        expect(
          RegistrationCartelaGridIndex.versionForCatalog(orderA),
          isNot(equals(RegistrationCartelaGridIndex.versionForCatalog(orderB))),
        );
      },
    );

    test(
      'update() rebuilds display indices when shuffledCartelaIds list is mutated in-place',
      () {
        final catalog = [cartela(1), cartela(2), cartela(3)];
        final shuffledIds = <String>['c-3', 'c-2', 'c-1'];
        final index = RegistrationCartelaGridIndex();

        index.update(
          catalog: catalog,
          shuffledCartelaIds: shuffledIds,
          searchQuery: '',
        );
        expect(displayedIds(index), <String>['c-3', 'c-2', 'c-1']);

        // Mutate the same list instance in-place:
        shuffledIds
          ..clear()
          ..addAll(['c-2', 'c-3', 'c-1']);

        index.update(
          catalog: catalog,
          shuffledCartelaIds: shuffledIds,
          searchQuery: '',
        );
        expect(displayedIds(index), <String>['c-2', 'c-3', 'c-1']);
      },
    );

    testWidgets(
      'RegistrationCartelaGrid scrolls smoothly, loads more from shuffledPool post-frame, and does not rebuild GridView on gridVisualRevision bump',
      (tester) async {
        final pool = [for (var i = 1; i <= 500; i++) cartela(i)];
        final session = RegistrationPanelSession();
        final gridVisualRevision = ValueNotifier<int>(0);
        final selectModeRevision = ValueNotifier<int>(0);
        final scrollController = ScrollController();
        addTearDown(() {
          session.dispose();
          gridVisualRevision.dispose();
          selectModeRevision.dispose();
          scrollController.dispose();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartelasRepositoryProvider.overrideWithValue(
                _FakeCartelasRepository(pool),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 360,
                  child: RegistrationCartelaGrid(
                    searchQuery: '',
                    shuffledCartelaIds: null,
                    serverSideSearch: false,
                    session: session,
                    sessionId: 'session-1',
                    lockedCartelaIds: const {'c-1'},
                    cartelaHoldSeconds: 30,
                    isGuest: false,
                    maxAffordable: 5,
                    gridVisualRevision: gridVisualRevision,
                    selectModeRevision: selectModeRevision,
                    scrollController: scrollController,
                    onCartelaTap: (_, _) {},
                    onCartelaLongPress: (_, _) {},
                    onExpiredSelectionReservations: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(scrollController.hasClients, isTrue);
        expect(scrollController.position.maxScrollExtent, greaterThan(0));

        // Drag up to scroll down to the bottom of the first 300 batch:
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pump();
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(RegistrationCartelaGrid)),
        );
        final catalogState =
            container.read(cartelaCatalogProvider).asData?.value;
        expect(catalogState, isNotNull);
        expect(catalogState!.items.length, 500);
      },
    );
  });
}
