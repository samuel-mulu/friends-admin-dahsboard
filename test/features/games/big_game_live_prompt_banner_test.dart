import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/app_display_config_provider.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/current_big_game_provider.dart';
import 'package:friends_bingo_app/src/features/games/application/providers/current_game_operations_provider.dart';
import 'package:friends_bingo_app/src/features/games/data/models/app_display_config_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/big_game_live_prompt_banner.dart';

void main() {
  testWidgets('hides the Games strip when Big Game promotion is off', (
    tester,
  ) async {
    await _pumpBanner(tester, enabled: false);

    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.text('Go to Big Game'), findsNothing);
  });

  testWidgets('shows the Games strip when Big Game promotion is on', (
    tester,
  ) async {
    await _pumpBanner(tester, enabled: true);

    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(
      find.text('Remaining games are here. Big Game Round 1 is playing'),
      findsOneWidget,
    );
    expect(find.text('Go to Big Game'), findsOneWidget);
  });
}

Future<void> _pumpBanner(WidgetTester tester, {required bool enabled}) async {
  final now = DateTime.utc(2026, 11, 4, 7);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDisplayConfigProvider.overrideWith(
          () => _FixedDisplayConfig(enabled),
        ),
        currentBigGameProvider.overrideWith(_EmptyBigGame.new),
        currentGameOperationsProvider.overrideWith(
          () => _FixedOperations(
            GameOperationsCurrentResponse(
              liveGame: null,
              checkingGame: null,
              registrationOpenGame: null,
              queue: const [],
              timestamp: now,
              serverNow: now,
              bigGameLiveElsewhere: const BigGameLiveElsewhere(
                sessionId: 'big-session',
                phase: 'live',
              ),
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BigGameLivePromptBanner(currentGame: null)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FixedDisplayConfig extends AppDisplayConfigNotifier {
  _FixedDisplayConfig(this.enabled);

  final bool enabled;

  @override
  Future<AppDisplayConfigModel> build() async {
    return AppDisplayConfigModel(bigGamePromotionCardEnabled: enabled);
  }
}

class _EmptyBigGame extends CurrentBigGameNotifier {
  @override
  Future<GameModel?> build() async => null;
}

class _FixedOperations extends CurrentGameOperationsNotifier {
  _FixedOperations(this.response);

  final GameOperationsCurrentResponse response;

  @override
  Future<GameOperationsCurrentResponse?> build() async => response;
}
