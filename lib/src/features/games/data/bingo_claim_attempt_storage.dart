import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Durable identities only. Server outcomes still come from the recovery GET.
class BingoClaimAttemptStorage {
  static Future<void>? _writes;

  String _key(String userId, String sessionId, String cartelaId) =>
      'friends_bingo_attempt_v1:$userId:$sessionId:$cartelaId';

  Future<List<Map<String, dynamic>>> load(
    String userId,
    String sessionId,
  ) async {
    final pendingWrites = _writes;
    if (pendingWrites != null) {
      await pendingWrites;
      if (identical(_writes, pendingWrites)) _writes = null;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final prefix = 'friends_bingo_attempt_v1:$userId:$sessionId:';
    final result = <Map<String, dynamic>>[];
    for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
      final decoded = jsonDecode(prefs.getString(key)!);
      if (decoded is Map<String, dynamic> &&
          decoded['userId'] == userId &&
          decoded['sessionId'] == sessionId) {
        result.add(decoded);
      }
    }
    return result;
  }

  Future<void> save(Map<String, dynamic> identity) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _key(
        identity['userId'] as String,
        identity['sessionId'] as String,
        identity['gameCartelaId'] as String,
      ),
      jsonEncode(identity),
    );
    if (!saved) throw StateError('Could not persist Bingo claim identity');
  });

  Future<void> remove(Map<String, dynamic> identity) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(
      identity['userId'] as String,
      identity['sessionId'] as String,
      identity['gameCartelaId'] as String,
    );
    final raw = prefs.getString(key);
    if (raw == null) return;
    final current = jsonDecode(raw) as Map<String, dynamic>;
    if (current['claimAttemptId'] == identity['claimAttemptId']) {
      if (!await prefs.remove(key)) {
        throw StateError('Could not remove Bingo claim identity');
      }
    }
  });

  Future<void> _serialize(Future<void> Function() operation) {
    final result = (_writes ?? Future<void>.value()).then((_) => operation());
    // A failed write must not poison subsequent cleanup or another attempt.
    final settled = result.catchError((Object _) {});
    _writes = settled;
    unawaited(
      settled.then((_) {
        if (identical(_writes, settled)) _writes = null;
      }),
    );
    return result;
  }
}
