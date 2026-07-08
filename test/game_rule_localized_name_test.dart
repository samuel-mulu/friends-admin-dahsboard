import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/game_rule_localized_name.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameRuleNamesRepository repository;

  setUp(() async {
    repository = await GameRuleNamesRepository.load();
  });

  test('returns Amharic for FULL_HOUSE with am locale', () {
    expect(
      repository.nameForKey(
        'FULL_HOUSE',
        const Locale('am'),
      ),
      'ሙሉ ቤት',
    );
  });

  test('returns English for om locale', () {
    expect(
      repository.nameForKey(
        'FULL_HOUSE',
        const Locale('om'),
      ),
      'Full house',
    );
  });

  test('falls back to API name for unknown key', () {
    expect(
      repository.nameForKey(
        'UNKNOWN_RULE',
        const Locale('en'),
        fallback: 'Custom API Name',
      ),
      'Custom API Name',
    );
  });

  test('MIX_08 Amharic uses English fallback until corrected', () {
    expect(
      repository.nameForKey(
        'MIX_08',
        const Locale('am'),
      ),
      '2 rows with 1 square',
    );
  });
}
