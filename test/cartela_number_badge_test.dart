import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/cartela_number_badge.dart';

void main() {
  test('cartelaNumberCircleFontSize scales down for 4+ digits', () {
    expect(cartelaNumberCircleFontSize(7), 28);
    expect(cartelaNumberCircleFontSize(8407), lessThan(28));
    expect(cartelaNumberCircleFontSize(5645), lessThan(28));
    expect(cartelaNumberCircleFontSize(12345), lessThan(cartelaNumberCircleFontSize(5645)));
  });

  test('cartelaNumberHeaderFontSize keeps 4-digit numbers readable', () {
    expect(cartelaNumberHeaderFontSize(42), greaterThan(cartelaNumberHeaderFontSize(5645)));
    expect(cartelaNumberHeaderFontSize(5645), greaterThanOrEqualTo(18));
  });
}
