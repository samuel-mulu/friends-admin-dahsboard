import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Documents the refetch ownership contract for Plan 1.
/// After migration, screen code must not keep parallel debounce timers.
void main() {
  test('LiveRealtimeController owns schedule + terminal + immediate APIs', () async {
    final controllerSource = await File(
      'lib/src/features/games/presentation/controllers/live_realtime_controller.dart',
    ).readAsString();
    for (final method in const [
      'void scheduleCanonicalRefetch(',
      'void requestTerminalCanonicalRefetch(',
      'Future<void> refetchCanonicalImmediate(',
      'void cancelCanonicalRefetchDebounce(',
      'Future<void> syncLatest(',
    ]) {
      expect(
        controllerSource.contains(method),
        isTrue,
        reason: 'Missing owner API: $method',
      );
    }
  });

  test('screen must not declare duplicate refetch timers after migration', () async {
    final screenSource = await File(
      'lib/src/features/games/presentation/screens/live_game_screen.dart',
    ).readAsString();
    expect(
      screenSource.contains('Timer? _canonicalRefetchDebounceTimer'),
      isFalse,
      reason: 'Duplicate screen debounce timer must be deleted; use LiveRealtimeController',
    );
    expect(
      screenSource.contains('Future<void>? _refetchCanonicalLoop'),
      isFalse,
      reason: 'Duplicate drain loop must live only on LiveRealtimeController',
    );
  });
}
