import 'package:shared_preferences/shared_preferences.dart';

import 'app_notification_category.dart';
import 'app_push_message.dart';
import 'notification_preferences.dart';

const androidNotificationGroupKey = 'friends_bingo_updates';

const _displayWindowMs = 60 * 1000;
const _maxDisplaysPerWindow = 4;
const _dedupeWindowMs = 2 * 60 * 1000;

const _rateExemptCategories = <String>{
  notificationCategoryDepositApproved,
  notificationCategoryWithdrawalApproved,
  notificationCategoryWithdrawalCompleted,
  notificationCategoryWithdrawalRejected,
  notificationCategoryWinnerAnnouncement,
  notificationCategorySystem,
};

bool isRateExemptNotificationCategory(String category) {
  return _rateExemptCategories.contains(category);
}

String notificationDisplayKey(String category, String? entityId) {
  final normalizedEntityId = entityId?.trim() ?? '';
  return '$category:$normalizedEntityId';
}

class NotificationDisplayThrottle {
  NotificationDisplayThrottle({
    List<int>? recentDisplayTimestamps,
    Map<String, int>? recentDedupeTimestamps,
    int Function()? nowMs,
  })  : recentDisplayTimestamps = List<int>.from(
          recentDisplayTimestamps ?? const [],
        ),
        recentDedupeTimestamps = Map<String, int>.from(
          recentDedupeTimestamps ?? const {},
        ),
        _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final List<int> recentDisplayTimestamps;
  final Map<String, int> recentDedupeTimestamps;
  final int Function() _nowMs;

  bool shouldDisplay({
    required String category,
    String? entityId,
  }) {
    final now = _nowMs();
    _prune(now);

    final dedupeKey = notificationDisplayKey(category, entityId);
    final lastDedupedAt = recentDedupeTimestamps[dedupeKey];
    if (lastDedupedAt != null && now - lastDedupedAt < _dedupeWindowMs) {
      return false;
    }

    if (isRateExemptNotificationCategory(category)) {
      return true;
    }

    return recentDisplayTimestamps.length < _maxDisplaysPerWindow;
  }

  void recordDisplayed({
    required String category,
    String? entityId,
  }) {
    final now = _nowMs();
    _prune(now);
    recentDisplayTimestamps.add(now);
    recentDedupeTimestamps[notificationDisplayKey(category, entityId)] = now;
  }

  void _prune(int now) {
    final displayCutoff = now - _displayWindowMs;
    recentDisplayTimestamps.removeWhere(
      (timestamp) => timestamp < displayCutoff,
    );

    final dedupeCutoff = now - _dedupeWindowMs;
    recentDedupeTimestamps.removeWhere(
      (_, timestamp) => timestamp < dedupeCutoff,
    );
  }
}

class NotificationDisplayThrottleStore {
  NotificationDisplayThrottleStore(this._prefs);

  static const _displayTimestampsKey =
      'notifications.display_timestamps_ms';
  static const _dedupeTimestampsKey = 'notifications.dedupe_timestamps_ms';

  final SharedPreferences _prefs;

  NotificationDisplayThrottle load() {
    final displayRaw = _prefs.getStringList(_displayTimestampsKey) ?? const [];
    final dedupeRaw = _prefs.getString(_dedupeTimestampsKey);

    return NotificationDisplayThrottle(
      recentDisplayTimestamps: displayRaw
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: true),
      recentDedupeTimestamps: _decodeDedupeMap(dedupeRaw),
    );
  }

  Future<void> save(NotificationDisplayThrottle throttle) async {
    await _prefs.setStringList(
      _displayTimestampsKey,
      throttle.recentDisplayTimestamps
          .map((value) => value.toString())
          .toList(),
    );
    await _prefs.setString(
      _dedupeTimestampsKey,
      _encodeDedupeMap(throttle.recentDedupeTimestamps),
    );
  }

  Map<String, int> _decodeDedupeMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = <String, int>{};
    for (final entry in raw.split('|')) {
      final separatorIndex = entry.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      final key = entry.substring(0, separatorIndex);
      final value = int.tryParse(entry.substring(separatorIndex + 1));
      if (value != null) {
        decoded[key] = value;
      }
    }
    return decoded;
  }

  String _encodeDedupeMap(Map<String, int> values) {
    return values.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('|');
  }
}

Future<bool> shouldDisplayPushNotification(AppPushMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final preferences = NotificationPreferencesStore(prefs).load();
  if (!preferences.allowsCategory(message.category)) {
    return false;
  }

  final store = NotificationDisplayThrottleStore(prefs);
  final throttle = store.load();
  final allowed = throttle.shouldDisplay(
    category: message.category,
    entityId: message.entityId,
  );
  if (!allowed) {
    return false;
  }

  throttle.recordDisplayed(
    category: message.category,
    entityId: message.entityId,
  );
  await store.save(throttle);
  return true;
}
