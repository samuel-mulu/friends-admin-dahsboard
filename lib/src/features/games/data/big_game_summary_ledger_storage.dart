import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local Big Game finished-summary dismissal ledger (no DB schema).
///
/// Keys: authenticated user + Big Game slot (event) + finished session.
/// Used only by `/games/big-game` across route re-entry and process restart.
class BigGameSummaryLedgerStorage {
  BigGameSummaryLedgerStorage(this._prefs);

  static const _keyPrefix = 'friends_bingo_bg_summary_v1';
  static const _indexKeyPrefix = 'friends_bingo_bg_summary_idx_v1';
  static const _maxEntriesPerUser = 40;
  static const _maxAge = Duration(days: 7);

  final SharedPreferences _prefs;

  static String entryKey({
    required String userId,
    required String slotId,
    required String sessionId,
  }) {
    return '$_keyPrefix:$userId:$slotId:$sessionId';
  }

  static String indexKey(String userId) => '$_indexKeyPrefix:$userId';

  Future<BigGameSummaryLedgerEntry?> load({
    required String userId,
    required String slotId,
    required String sessionId,
  }) async {
    try {
      final raw = _prefs.getString(
        entryKey(userId: userId, slotId: slotId, sessionId: sessionId),
      );
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return BigGameSummaryLedgerEntry.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isDismissed({
    required String userId,
    required String slotId,
    required String sessionId,
  }) async {
    final entry = await load(
      userId: userId,
      slotId: slotId,
      sessionId: sessionId,
    );
    return entry?.dismissed == true;
  }

  Future<void> markDismissed({
    required String userId,
    required String slotId,
    required String sessionId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final existing = await load(
        userId: userId,
        slotId: slotId,
        sessionId: sessionId,
      );
      final entry = BigGameSummaryLedgerEntry(
        userId: userId,
        slotId: slotId,
        sessionId: sessionId,
        dismissed: true,
        visibleFrom: existing?.visibleFrom,
        updatedAt: now,
      );
      final key = entryKey(
        userId: userId,
        slotId: slotId,
        sessionId: sessionId,
      );
      await _prefs.setString(key, jsonEncode(entry.toJson()));
      await _touchIndex(userId: userId, entryKey: key);
      await pruneBounded(userId: userId, now: now);
    } catch (_) {
      // Local UX only — never block game flow.
    }
  }

  Future<void> pruneBounded({
    required String userId,
    required DateTime now,
  }) async {
    try {
      final index = _readIndex(userId);
      if (index.isEmpty) {
        return;
      }
      final cutoff = now.toUtc().subtract(_maxAge);
      final kept = <String>[];
      for (final key in index) {
        final raw = _prefs.getString(key);
        if (raw == null) {
          continue;
        }
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) {
            await _prefs.remove(key);
            continue;
          }
          final updatedAt = DateTime.tryParse(
            decoded['updatedAt']?.toString() ?? '',
          );
          if (updatedAt == null || updatedAt.isBefore(cutoff)) {
            await _prefs.remove(key);
            continue;
          }
          kept.add(key);
        } catch (_) {
          await _prefs.remove(key);
        }
      }
      if (kept.length > _maxEntriesPerUser) {
        final overflow = kept.length - _maxEntriesPerUser;
        for (var i = 0; i < overflow; i++) {
          await _prefs.remove(kept[i]);
        }
        kept.removeRange(0, overflow);
      }
      await _prefs.setStringList(indexKey(userId), kept);
    } catch (_) {}
  }

  List<String> _readIndex(String userId) {
    try {
      return _prefs.getStringList(indexKey(userId)) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _touchIndex({
    required String userId,
    required String entryKey,
  }) async {
    final index = [..._readIndex(userId)]..remove(entryKey);
    index.add(entryKey);
    await _prefs.setStringList(indexKey(userId), index);
  }
}

class BigGameSummaryLedgerEntry {
  const BigGameSummaryLedgerEntry({
    required this.userId,
    required this.slotId,
    required this.sessionId,
    required this.dismissed,
    required this.updatedAt,
    this.visibleFrom,
  });

  final String userId;
  final String slotId;
  final String sessionId;
  final bool dismissed;
  final DateTime? visibleFrom;
  final DateTime updatedAt;

  factory BigGameSummaryLedgerEntry.fromJson(Map<String, dynamic> json) {
    return BigGameSummaryLedgerEntry(
      userId: json['userId']?.toString() ?? '',
      slotId: json['slotId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      dismissed: json['dismissed'] == true,
      visibleFrom: json['visibleFrom'] is String
          ? DateTime.tryParse(json['visibleFrom'] as String)
          : null,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'slotId': slotId,
      'sessionId': sessionId,
      'dismissed': dismissed,
      if (visibleFrom != null) 'visibleFrom': visibleFrom!.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
