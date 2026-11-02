import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Foreign live session ownership check snapshot guard safety (BUG-08)', () {
    test(
      'ownership check in _loadInitialState only captures currentSessionFetchToken when fetchedCartelas is non-empty',
      () {
        final orchestrationSource = File(
          'lib/src/features/games/presentation/screens/live_game_orchestration.dart',
        ).readAsStringSync();

        final startIdx = orchestrationSource.indexOf(
          'final liveSessionId = ownershipLiveCandidate.sessionId!;',
        );
        expect(startIdx, greaterThanOrEqualTo(0));
        final block = orchestrationSource.substring(startIdx, startIdx + 1200);
        final beforeIf = block.split('if (fetchedCartelas.isNotEmpty)').first;
        final insideIf = block.split('if (fetchedCartelas.isNotEmpty)').last;

        expect(
          beforeIf.contains('captureCurrentSessionFetchToken'),
          isFalse,
          reason:
              'Capturing currentSessionFetchToken before getMyGameCartelas resets the guard to the foreign liveSessionId even when the user owns 0 cartelas in it',
        );
        expect(
          insideIf.contains('captureCurrentSessionFetchToken(liveSessionId)'),
          isTrue,
        );
      },
    );
  });
}
