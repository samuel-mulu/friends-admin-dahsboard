import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

void main() {
  group('Called numbers dirty gate & duplicate notification prevention (BUG-06)', () {
    test(
      '_markCalledNumbersPanelDirty only skips duplicate (count, lastOrder) when forNewBall is true',
      () {
        final stateBaseSource = File(
          'lib/src/features/games/presentation/screens/live_game_state_base.dart',
        ).readAsStringSync();

        expect(
          stateBaseSource.contains(
            'void _markCalledNumbersPanelDirty({bool forNewBall = false})',
          ),
          isTrue,
          reason:
              '_markCalledNumbersPanelDirty must accept {bool forNewBall = false} so non-ball refreshes (Auto-Mark toggle, cartela hydration) are not dropped',
        );
        expect(
          stateBaseSource.contains('forNewBall &&') &&
              stateBaseSource.contains('_lastCalledNumbersDirtyCount == count'),
          isTrue,
        );
      },
    );

    test(
      'applyNumberCalledSocket does not pre-bump calledNumbersPanelRevision when strip is not paused for claim',
      () {
        final host = _StubHost();
        final controller = LiveCalledNumbersController(host);
        addTearDown(controller.dispose);

        final initialRevision = controller.calledNumbersPanelRevision.value;

        final result = controller.applyNumberCalledSocket(
          calledNumber: CalledNumberModel(
            id: 'cn-1',
            sessionId: 'session-1',
            number: 7,
            letter: 'B',
            order: 1,
            createdAt: DateTime.utc(2026, 8, 7, 12),
          ),
          pauseStripForClaim: false,
        );

        expect(result?.applied, isTrue);
        expect(
          controller.calledNumbersPanelRevision.value,
          initialRevision,
          reason:
              'Screen _markCalledNumbersPanelDirty(forNewBall: true) owns the revision bump when !pauseStripForClaim',
        );
      },
    );
  });
}

class _StubHost extends Fake implements LiveGameHost {
  @override
  bool mounted = true;

  @override
  bool isLiveHostActive = true;

  @override
  GameModel? game;
}
