import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/storage/app_preferences_storage.dart';
import 'package:friends_bingo_app/src/features/games/domain/cartela_mark_color.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults cartela mark color to green', () async {
    final storage = await AppPreferencesStorage.create();
    expect(storage.readCartelaMarkColor(), CartelaMarkColor.green);
  });

  test('persists cartela mark color choice', () async {
    final storage = await AppPreferencesStorage.create();

    await storage.writeCartelaMarkColor(CartelaMarkColor.yellow);
    expect(storage.readCartelaMarkColor(), CartelaMarkColor.yellow);

    final reloaded = await AppPreferencesStorage.create();
    expect(reloaded.readCartelaMarkColor(), CartelaMarkColor.yellow);
  });

  test('ignores unknown stored cartela mark color', () async {
    SharedPreferences.setMockInitialValues({
      'cartela_mark_color': 'purple',
    });

    final storage = await AppPreferencesStorage.create();
    expect(storage.readCartelaMarkColor(), CartelaMarkColor.green);
  });
}
