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

  test('save and load marks for user and session', () async {
    final store = await createStorage();
    await store.save(
      userId: 'user-1',
      gameSessionId: 'session-1',
      marks: {'B:7', 'I:22'},
    );

    final loaded = await store.load(
      userId: 'user-1',
      gameSessionId: 'session-1',
    );

    expect(loaded, {'B:7', 'I:22'});
  });

  test('load ignores different session', () async {
    final store = await createStorage();
    await store.save(
      userId: 'user-1',
      gameSessionId: 'session-1',
      marks: {'B:7'},
    );

    final loaded = await store.load(
      userId: 'user-1',
      gameSessionId: 'session-2',
    );

    expect(loaded, isEmpty);
  });

  test('load ignores different user', () async {
    final store = await createStorage();
    await store.save(
      userId: 'user-1',
      gameSessionId: 'session-1',
      marks: {'B:7'},
    );

    final loaded = await store.load(
      userId: 'user-2',
      gameSessionId: 'session-1',
    );

    expect(loaded, isEmpty);
  });

  test('clear removes saved marks', () async {
    final store = await createStorage();
    await store.save(
      userId: 'user-1',
      gameSessionId: 'session-1',
      marks: {'G:52'},
    );
    await store.clear(userId: 'user-1', gameSessionId: 'session-1');

    final loaded = await store.load(
      userId: 'user-1',
      gameSessionId: 'session-1',
    );

    expect(loaded, isEmpty);
  });

  test('corrupted json returns empty marks', () async {
    SharedPreferences.setMockInitialValues({
      CartelaMarksStorage.sessionKey('user-1', 'session-1'): '{not-json',
    });

    final store = await createStorage();
    final loaded = await store.load(
      userId: 'user-1',
      gameSessionId: 'session-1',
    );

    expect(loaded, isEmpty);
  });

  test('different users keep separate session mark state', () async {
    final store = await createStorage();
    await store.save(
      userId: 'user-1',
      gameSessionId: 'session-1',
      marks: {'B:7'},
    );
    await store.save(
      userId: 'user-2',
      gameSessionId: 'session-1',
      marks: {'I:22'},
    );

    expect(await store.load(userId: 'user-1', gameSessionId: 'session-1'), {
      'B:7',
    });
    expect(await store.load(userId: 'user-2', gameSessionId: 'session-1'), {
      'I:22',
    });
  });
}
