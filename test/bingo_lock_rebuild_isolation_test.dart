import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_countdown_controller.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_controllers.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/live_game_host.dart';

void main() {
  test('bingo lock notifier can flip without touching cartela list version', () {
    final lock = ValueNotifier<bool>(false);
    var cartelaListVersion = 0;

    void onLockTick(bool locked) {
      lock.value = locked;
    }

    onLockTick(true);
    expect(lock.value, isTrue);
    expect(cartelaListVersion, 0);

    onLockTick(false);
    expect(lock.value, isFalse);
    expect(cartelaListVersion, 0);
  });

  test('updateBingoClaimLocked is idempotent', () {
    final host = _FakeHost();
    final countdown = LiveCountdownController(host);
    addTearDown(countdown.dispose);

    countdown.updateBingoClaimLocked(true);
    expect(countdown.bingoClaimLocked.value, isTrue);
    countdown.updateBingoClaimLocked(true);
    expect(countdown.bingoClaimLocked.value, isTrue);
    countdown.updateBingoClaimLocked(false);
    expect(countdown.bingoClaimLocked.value, isFalse);
  });

  testWidgets('lock notifier does not rebuild cartela list state', (tester) async {
    final lock = ValueNotifier<bool>(false);
    addTearDown(lock.dispose);
    var listBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            listBuilds++;
            return Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: lock,
                  builder: (_, locked, __) => Text('locked:$locked'),
                ),
                const Text('cartela-list'),
              ],
            );
          },
        ),
      ),
    );

    final buildsAfterFirstPump = listBuilds;
    lock.value = true;
    await tester.pump();
    expect(listBuilds, buildsAfterFirstPump);
    expect(find.text('locked:true'), findsOneWidget);
  });
}

class _FakeHost implements LiveGameHost {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  LiveGameControllers get controllers => LiveGameControllers(this);
}
