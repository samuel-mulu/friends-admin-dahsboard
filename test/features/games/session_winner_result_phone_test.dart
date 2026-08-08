import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/session_winner_result_model.dart';

void main() {
  group('SessionWinnerResultModel phoneNumber', () {
    test('parses local phoneNumber from JSON', () {
      final result = SessionWinnerResultModel.fromJson({
        'gameCartelaId': 'gc-1',
        'cartelaId': 'c-1',
        'cartelaNumber': 42,
        'amount': '25.00',
        'phoneNumber': '0962520885',
        'b': <String>['1', '2', '3', '4', '5'],
        'i': <String>['16', '17', '18', '19', '20'],
        'n': <String>['31', '32', 'FREE', '34', '35'],
        'g': <String>['46', '47', '48', '49', '50'],
        'o': <String>['61', '62', '63', '64', '65'],
        'completedPatterns': <Map<String, dynamic>>[],
      });

      expect(result.phoneNumber, '0962520885');
    });

    test('keeps phoneNumber null when API omits it', () {
      final result = SessionWinnerResultModel.fromJson({
        'gameCartelaId': 'gc-1',
        'cartelaId': 'c-1',
        'cartelaNumber': 42,
        'amount': '25.00',
        'b': <String>['1', '2', '3', '4', '5'],
        'i': <String>['16', '17', '18', '19', '20'],
        'n': <String>['31', '32', 'FREE', '34', '35'],
        'g': <String>['46', '47', '48', '49', '50'],
        'o': <String>['61', '62', '63', '64', '65'],
        'completedPatterns': <Map<String, dynamic>>[],
      });

      expect(result.phoneNumber, isNull);
    });

    test('copyWith preserves phoneNumber by default', () {
      const original = SessionWinnerResultModel(
        gameCartelaId: 'gc-1',
        cartelaId: 'c-1',
        cartelaNumber: 42,
        amount: '25.00',
        phoneNumber: '0962520885',
        columns: <List<String>>[],
        completedPatterns: [],
      );

      expect(original.copyWith(amount: '30.00').phoneNumber, '0962520885');
    });
  });
}
