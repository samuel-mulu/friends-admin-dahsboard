import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/l10n/fallback_global_localizations.dart';
import 'package:friends_bingo_app/src/core/storage/app_preferences_storage.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/providers/first_launch_preferences_provider.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/screens/first_launch_preferences_screen.dart';
import 'package:friends_bingo_app/src/features/settings/presentation/widgets/first_launch_preferences_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness({
  required AppPreferencesStorage storage,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      appPreferencesStorageProvider.overrideWith((ref) async => storage),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...fallbackGlobalLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Future<AppPreferencesStorage> _storage() => AppPreferencesStorage.create();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirstLaunchPreferencesScreen', () {
    testWidgets('preselects light theme and Amharic on fresh install', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await _storage();

      await tester.pumpWidget(
        _harness(storage: storage, child: const FirstLaunchPreferencesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.byKey(const Key('first_launch_lang_am')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    });

    testWidgets('Continue persists selected theme and language', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await _storage();

      await tester.pumpWidget(
        _harness(storage: storage, child: const FirstLaunchPreferencesScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('first_launch_theme_dark')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('first_launch_lang_en')));
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(const Key('first_launch_continue')),
      );
      await tester.tap(find.byKey(const Key('first_launch_continue')));
      await tester.pumpAndSettle();

      expect(storage.hasCompletedFirstLaunchPreferences(), isTrue);
      expect(storage.readThemeMode(), ThemeMode.dark);
      expect(storage.readLocale()?.languageCode, 'en');
    });

    testWidgets('dark preview uses readable card text colors', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await _storage();

      await tester.pumpWidget(
        _harness(storage: storage, child: const FirstLaunchPreferencesScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('first_launch_theme_dark')));
      await tester.pump();

      final darkLabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('first_launch_theme_dark')),
          matching: find.text('Dark'),
        ),
      );
      final englishLabel = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('first_launch_lang_en')),
          matching: find.text('English'),
        ),
      );

      expect(darkLabel.style?.color, Colors.white);
      expect(englishLabel.style?.color, Colors.white);
    });

    testWidgets('Skip keeps defaults and marks completion', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await _storage();

      await tester.pumpWidget(
        _harness(storage: storage, child: const FirstLaunchPreferencesScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('first_launch_theme_dark')));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('first_launch_skip')));
      await tester.tap(find.byKey(const Key('first_launch_skip')));
      await tester.pumpAndSettle();

      expect(storage.hasCompletedFirstLaunchPreferences(), isTrue);
      expect(storage.readThemeMode(), ThemeMode.light);
      expect(storage.readLocale(), isNull);
    });
  });

  group('FirstLaunchPreferencesGate', () {
    testWidgets('shows prompt when incomplete and hides after skip', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await _storage();

      await tester.pumpWidget(
        _harness(
          storage: storage,
          child: const FirstLaunchPreferencesGate(
            child: Scaffold(body: Text('app-shell')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose your experience'), findsOneWidget);
      expect(find.text('app-shell'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('first_launch_skip')));
      await tester.tap(find.byKey(const Key('first_launch_skip')));
      await tester.pumpAndSettle();

      expect(find.text('Choose your experience'), findsNothing);
      expect(find.text('app-shell'), findsOneWidget);
      expect(
        tester
            .container()
            .read(firstLaunchPreferencesCompletedProvider)
            .asData
            ?.value,
        isTrue,
      );
    });

    testWidgets('does not show prompt when already completed', (tester) async {
      SharedPreferences.setMockInitialValues({
        'first_launch_preferences_completed': true,
      });
      final storage = await _storage();

      await tester.pumpWidget(
        _harness(
          storage: storage,
          child: const FirstLaunchPreferencesGate(
            child: Scaffold(body: Text('app-shell')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose your experience'), findsNothing);
      expect(find.text('app-shell'), findsOneWidget);
    });
  });
}
