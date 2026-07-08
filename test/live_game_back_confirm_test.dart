import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/widgets/app_back_confirm_scope.dart';
import 'package:friends_bingo_app/src/features/games/presentation/providers/has_active_registered_cartelas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _backConfirmPopScopeKey = ValueKey<String>('back-confirm-pop-scope');

class BackConfirmHarness extends StatelessWidget {
  const BackConfirmHarness({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackConfirmScope(
      child: const Scaffold(
        key: _backConfirmPopScopeKey,
        body: Center(child: Text('screen')),
      ),
    );
  }
}

class _ActiveCartelasNotifier extends HasActiveRegisteredCartelasNotifier {
  @override
  ActiveRegisteredCartelasState build() {
    return const ActiveRegisteredCartelasState(
      activeSessionId: 'session-1',
      registeredCartelaCount: 2,
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Widget _wrapRouter(GoRouter router) {
  return MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

Future<void> _openNestedScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BackConfirmHarness(),
                    ),
                  );
                },
                child: const Text('open-screen'),
              ),
            ),
          );
        },
      ),
    ),
  );

  await tester.tap(find.text('open-screen'));
  await tester.pumpAndSettle();
  expect(find.text('screen'), findsOneWidget);
}

PopScope<Object?> _popScope(WidgetTester tester) {
  return tester.widget<PopScope<Object?>>(
    find.byWidgetPredicate(
      (widget) => widget is PopScope<Object?> && !widget.canPop,
    ),
  );
}

GoRouter _createGamesRouter() {
  return GoRouter(
    initialLocation: '/games/history',
    routes: [
      GoRoute(
        path: '/games',
        builder: (context, state) => appRouteWithBackConfirm(
          const Scaffold(body: Center(child: Text('live-game'))),
        ),
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) => appRouteWithBackConfirm(
              const Scaffold(body: Center(child: Text('history'))),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('home'))),
      ),
    ],
  );
}

GoRouter _createLiveGameRouter() {
  return GoRouter(
    initialLocation: '/games',
    routes: [
      GoRoute(
        path: '/games',
        builder: (context, state) => appRouteWithBackConfirm(
          const Scaffold(body: Center(child: Text('live-game'))),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('home'))),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('nested screen pops immediately without confirm dialog', (
    tester,
  ) async {
    await _openNestedScreen(tester);

    final popScope = _popScope(tester);
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(find.text('Go back?'), findsNothing);
    expect(find.text('Leave live game?'), findsNothing);
    expect(find.text('screen'), findsNothing);
    expect(find.text('open-screen'), findsOneWidget);
  });

  testWidgets('nested go_router route pops to live game without confirm', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapRouter(_createGamesRouter()));
    await tester.pumpAndSettle();

    expect(find.text('history'), findsOneWidget);

    final popScope = _popScope(tester);
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(find.text('Leave live game?'), findsNothing);
    expect(find.text('history'), findsNothing);
    expect(find.text('live-game'), findsOneWidget);
  });

  testWidgets('live game root shows leave dialog and navigates home on leave', (
    tester,
  ) async {
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasActiveRegisteredCartelasProvider.overrideWith(
            _ActiveCartelasNotifier.new,
          ),
        ],
        child: _wrapRouter(_createLiveGameRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('live-game'), findsOneWidget);

    final popScope = _popScope(tester);
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(find.text('Leave live game?'), findsOneWidget);
    expect(find.text('live-game'), findsOneWidget);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('live-game'), findsOneWidget);
    expect(find.text('home'), findsNothing);
    expect(
      platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });

  testWidgets('live game stay keeps user on live game', (tester) async {
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasActiveRegisteredCartelasProvider.overrideWith(
            _ActiveCartelasNotifier.new,
          ),
        ],
        child: _wrapRouter(_createLiveGameRouter()),
      ),
    );
    await tester.pumpAndSettle();

    final popScope = _popScope(tester);
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(find.text('Leave live game?'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(find.text('live-game'), findsOneWidget);
    expect(find.text('home'), findsNothing);
    expect(
      platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );
  });
}
