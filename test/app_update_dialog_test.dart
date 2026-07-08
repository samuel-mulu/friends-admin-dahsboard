import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/version/android_app_version_model.dart';
import 'package:friends_bingo_app/src/core/version/app_update_dialog.dart';

const _sampleUpdate = AndroidAppVersionModel(
  version: '2.4.1',
  versionCode: 5,
  minimumVersionCode: 3,
  downloadUrl: 'https://example.com/app-release.apk',
  sha256: 'abc123',
  releaseNotes: 'Stability improvements',
  forceUpdate: false,
);

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
  testWidgets('optional update dialog shows Later and Update', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showAppUpdateDialog(
                  context,
                  info: _sampleUpdate,
                  isForce: false,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Stability improvements'), findsOneWidget);
    expect(find.text('abc123'), findsOneWidget);
  });

  testWidgets('force update dialog shows Update only', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showAppUpdateDialog(
                  context,
                  info: _sampleUpdate,
                  isForce: true,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('force update dialog cannot be dismissed by barrier tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showAppUpdateDialog(
                  context,
                  info: _sampleUpdate,
                  isForce: true,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
  });

  testWidgets('force update calls onForceUpdateLaunched after Update tap', (
    tester,
  ) async {
    var launched = false;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showAppUpdateDialog(
                  context,
                  info: _sampleUpdate,
                  isForce: true,
                  onUpdate: (_, _) async => true,
                  onForceUpdateLaunched: () => launched = true,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(launched, isTrue);
    expect(find.text('Update required'), findsOneWidget);
  });

  testWidgets('Update button calls launcher handler', (tester) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showAppUpdateDialog(
                  context,
                  info: _sampleUpdate,
                  isForce: false,
                  onUpdate: (dialogContext, uri) async {
                    launchedUri = uri;
                    return true;
                  },
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(launchedUri, Uri.parse(_sampleUpdate.downloadUrl));
  });

  testWidgets('no update dialog shows installed version', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showNoUpdateAvailableDialog(
                  context,
                  versionLabel: '1.0.1 (2)',
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('No updates'), findsOneWidget);
    expect(find.text('Installed: 1.0.1 (2)'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}
