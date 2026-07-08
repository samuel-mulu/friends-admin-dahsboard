import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/widgets/app_back_confirm_scope.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('confirm back dialog shows copy and returns stay', (
    tester,
  ) async {
    ConfirmBackChoice? choice;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                choice = await showConfirmBackDialog(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Go back?'), findsOneWidget);
    expect(find.text('Do you want to leave this page?'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(choice, ConfirmBackChoice.stay);
  });

  testWidgets('confirm back dialog returns leave choice', (tester) async {
    ConfirmBackChoice? choice;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                choice = await showConfirmBackDialog(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(choice, ConfirmBackChoice.leave);
  });

  testWidgets('leave live game dialog shows copy and returns stay', (
    tester,
  ) async {
    ConfirmBackChoice? choice;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                choice = await showLeaveLiveGameDialog(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Leave live game?'), findsOneWidget);
    expect(
      find.text(
        'Your game will continue on the server. Your marked cells will be saved on this device.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(choice, ConfirmBackChoice.stay);
  });

  testWidgets('leave live game dialog returns leave choice', (tester) async {
    ConfirmBackChoice? choice;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                choice = await showLeaveLiveGameDialog(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(choice, ConfirmBackChoice.leave);
  });
}
