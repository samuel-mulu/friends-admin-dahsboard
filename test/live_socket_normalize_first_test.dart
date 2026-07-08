import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Plan 2 Task 4: every live socket entrypoint that accepts `dynamic payload`
/// must normalize before reading fields from that payload.
void main() {
  Future<void> expectDynamicHandlersNormalize(String relativePath) async {
    final source = await File(relativePath).readAsString();
    final handlerPattern = RegExp(
      r'void (_on\w+)\(dynamic payload\) \{([\s\S]*?)\n  \}',
      multiLine: true,
    );

    final matches = handlerPattern.allMatches(source).toList();
    expect(
      matches,
      isNotEmpty,
      reason: 'Expected dynamic payload handlers in $relativePath',
    );

    for (final match in matches) {
      final name = match.group(1)!;
      final body = match.group(2)!;
      final normalized =
          body.contains('_normalizeSocketPayloadForEvent') ||
          body.contains('normalizeSocketPayload(');
      expect(
        normalized,
        isTrue,
        reason: '$name in $relativePath must normalize before map access',
      );

      final splitToken = body.contains('_normalizeSocketPayloadForEvent')
          ? '_normalizeSocketPayloadForEvent'
          : 'normalizeSocketPayload(';
      final beforeNormalize = body.split(splitToken).first;
      expect(
        RegExp(r"payload\s*\[").hasMatch(beforeNormalize),
        isFalse,
        reason: '$name reads payload[…] before normalize in $relativePath',
      );
    }
  }

  test('live_game_realtime dynamic handlers normalize first', () async {
    await expectDynamicHandlersNormalize(
      'lib/src/features/games/presentation/screens/live_game_realtime.dart',
    );
  });

  test('live_game_orchestration dynamic handlers normalize first', () async {
    await expectDynamicHandlersNormalize(
      'lib/src/features/games/presentation/screens/live_game_orchestration.dart',
    );
  });
}
