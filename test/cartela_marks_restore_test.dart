import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/cartela_marks_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<CartelaMarksStorage> createStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return CartelaMarksStorage(prefs);
  }

  test('same session restore returns the exact saved marks', () async {
    const userId = 'user-1';
    const sessionId = 'session-1';
    const savedMarks = {'B:7', 'I:22', 'G:52'};

    final store = await createStorage();
    await store.save(
      userId: userId,
      gameSessionId: sessionId,
      marks: savedMarks,
    );

    expect(
      await store.load(userId: userId, gameSessionId: sessionId),
      savedMarks,
    );
  });

  test('different session does not reuse marks from another round', () async {
    const userId = 'user-1';

    final store = await createStorage();
    await store.save(
      userId: userId,
      gameSessionId: 'session-1',
      marks: {'B:7', 'I:22'},
    );

    expect(
      await store.load(userId: userId, gameSessionId: 'session-2'),
      isEmpty,
    );
  });

  test(
    'saving empty marks replaces existing marks for that same session',
    () async {
      const userId = 'user-1';
      const sessionId = 'session-1';

      final store = await createStorage();
      await store.save(
        userId: userId,
        gameSessionId: sessionId,
        marks: {'B:7', 'I:22'},
      );

      await store.save(
        userId: userId,
        gameSessionId: sessionId,
        marks: const {},
      );

      expect(
        await store.load(userId: userId, gameSessionId: sessionId),
        isEmpty,
      );
    },
  );
}
