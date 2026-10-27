import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';

class _FakeLiveGameHost extends Fake implements LiveGameHost {}

void main() {
  test('isDuplicateCalledNumber ignores deferred-only processed order', () {
    final host = _FakeLiveGameHost();
    final controller = LiveCalledNumbersController(host);

    final deferredOnly = CalledNumberModel(
      id: 'cn-41',
      sessionId: 'session-1',
      order: 41,
      letter: 'N',
      number: 31,
      createdAt: DateTime.utc(2026, 10, 27),
    );

    controller.deferredCalledNumbers = [deferredOnly];
    controller.rebuildCalledNumberTracking();
    controller.calledNumbers = const [];

    expect(controller.isDuplicateCalledNumber(deferredOnly), isFalse);
  });

  test('isDuplicateCalledNumber true when order is on committed strip', () {
    final host = _FakeLiveGameHost();
    final controller = LiveCalledNumbersController(host);

    final onStrip = CalledNumberModel(
      id: 'cn-41',
      sessionId: 'session-1',
      order: 41,
      letter: 'N',
      number: 31,
      createdAt: DateTime.utc(2026, 10, 27),
    );

    controller.calledNumbers = [onStrip];
    controller.rebuildCalledNumberTracking();

    expect(controller.isDuplicateCalledNumber(onStrip), isTrue);
  });
}
