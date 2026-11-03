import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_catalog_controls.dart';

Widget _wrapWithLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('RegistrationCatalogControls renders controls and handles actions', (
    tester,
  ) async {
    final searchController = TextEditingController();
    var reshuffled = false;
    var selectMode = false;
    int? tappedRegisteredNumber;

    await tester.pumpWidget(
      _wrapWithLocalizations(
        RegistrationCatalogControls(
          registeredNumbers: const [10, 25],
          walletBalance: '150.00',
          bonusCartelaBalance: 2,
          selectModeEnabled: false,
          maxAffordableSelections: 5,
          remainingBonusCartelas: 2,
          category: GameCategory.normal,
          entryFee: '10.00',
          fixedPrizeAmount: '500.00',
          maxCartelasPerPlayer: 10,
          selectedCount: 0,
          onSelectModeChanged: (val) => selectMode = val,
          isGuest: false,
          searchController: searchController,
          onReshuffle: () => reshuffled = true,
          onRegisteredNumberTap: (n) => tappedRegisteredNumber = n,
        ),
      ),
    );

    // Verify search field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify select filter chip exists and handles tap
    final selectChip = find.text('Select');
    expect(selectChip, findsOneWidget);
    await tester.tap(selectChip);
    await tester.pump();
    expect(selectMode, isTrue);

    // Verify reshuffle button exists and handles tap
    final reshuffleButton = find.byType(RegistrationReshuffleButton);
    expect(reshuffleButton, findsOneWidget);
    await tester.tap(reshuffleButton);
    await tester.pump();
    expect(reshuffled, isTrue);

    // Verify registered number chips exist
    expect(find.text('10'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    await tester.tap(find.text('10'));
    await tester.pump();
    expect(tappedRegisteredNumber, equals(10));
  });

  testWidgets('RegistrationBulkBanner renders progress and count', (tester) async {
    await tester.pumpWidget(
      _wrapWithLocalizations(
        const RegistrationBulkBanner(count: 3),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
