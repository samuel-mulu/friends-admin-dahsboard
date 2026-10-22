import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live_game_screen.dart line count is under 400 lines', () async {
    final file = File(
      'lib/src/features/games/presentation/screens/live_game_screen.dart',
    );
    expect(file.existsSync(), isTrue);
    final lineCount = file.readAsLinesSync().length;
    expect(
      lineCount,
      lessThan(400),
      reason: 'Expected under 400 lines, was $lineCount',
    );
  });
}
