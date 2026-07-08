import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('_onGameCancelled uses requestTerminalCanonicalRefetch', () async {
    final source = await File(
      'lib/src/features/games/presentation/screens/live_game_orchestration.dart',
    ).readAsString();
    final cancelFnStart = source.indexOf('void _onGameCancelled');
    expect(cancelFnStart, greaterThanOrEqualTo(0));
    final snippet = source.substring(cancelFnStart, cancelFnStart + 1200);
    expect(
      snippet.contains('requestTerminalCanonicalRefetch'),
      isTrue,
      reason: 'CANCELLED must use terminal coalesce path, not generic immediate',
    );
    expect(snippet.contains('_refetchCanonicalImmediate'), isFalse);
  });

  test('_onGameFinished uses requestTerminalCanonicalRefetch', () async {
    final source = await File(
      'lib/src/features/games/presentation/screens/live_game_orchestration.dart',
    ).readAsString();
    final start = source.indexOf('void _onGameFinished');
    expect(start, greaterThanOrEqualTo(0));
    final snippet = source.substring(start, start + 900);
    expect(snippet.contains('requestTerminalCanonicalRefetch'), isTrue);
    expect(snippet.contains('_refetchCanonicalImmediate'), isFalse);
  });

  test('terminal status_changed uses requestTerminalCanonicalRefetch', () async {
    final source = await File(
      'lib/src/features/games/presentation/screens/live_game_realtime.dart',
    ).readAsString();
    final start = source.indexOf('void _onGameStatusChanged');
    expect(start, greaterThanOrEqualTo(0));
    final snippet = source.substring(start, start + 2000);
    expect(snippet.contains('requestTerminalCanonicalRefetch'), isTrue);
    expect(
      snippet.contains("status == 'FINISHED'") ||
          snippet.contains('isTerminalGameStatus') ||
          snippet.contains('terminalTransitionSnapshot'),
      isTrue,
    );
  });
}
