import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CartelaMarksStorage {
  CartelaMarksStorage(this._prefs);

  static const _keyPrefix = 'friends_bingo_marks_v1';

  final SharedPreferences _prefs;

  static String sessionKey(String userId, String gameSessionId) {
    return '$_keyPrefix:$userId:$gameSessionId';
  }

  Future<Set<String>> load({
    required String userId,
    required String gameSessionId,
  }) async {
    try {
      final raw = _prefs.getString(sessionKey(userId, gameSessionId));
      if (raw == null || raw.isEmpty) {
        return {};
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      if (decoded['userId'] != userId ||
          decoded['gameSessionId'] != gameSessionId) {
        return {};
      }

      final marks = decoded['marks'];
      if (marks is! List) {
        return {};
      }

      return marks
          .whereType<String>()
          .where((mark) => mark.contains(':'))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> save({
    required String userId,
    required String gameSessionId,
    required Set<String> marks,
  }) async {
    try {
      final payload = jsonEncode({
        'gameSessionId': gameSessionId,
        'userId': userId,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'marks': marks.toList(growable: false)..sort(),
      });

      await _prefs.setString(sessionKey(userId, gameSessionId), payload);
    } catch (_) {
      // Fail silently - marks are local UX only.
    }
  }

  Future<void> clear({
    required String userId,
    required String gameSessionId,
  }) async {
    try {
      await _prefs.remove(sessionKey(userId, gameSessionId));
    } catch (_) {}
  }
}
