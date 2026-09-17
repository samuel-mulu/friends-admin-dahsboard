import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/user_profile.dart';
import '../../features/auth/session/session_manager.dart';
import '../network/api_client.dart';
import 'app_notification_category.dart';

@immutable
class NotificationPreferencesState {
  const NotificationPreferencesState({
    this.pushEnabled = true,
    this.gamePushMode = GamePushMode.always,
    this.depositApprovedEnabled = true,
    this.withdrawalApprovedEnabled = true,
    this.withdrawalRejectedEnabled = true,
    this.systemEnabled = true,
  });

  final bool pushEnabled;
  final GamePushMode gamePushMode;
  final bool depositApprovedEnabled;
  final bool withdrawalApprovedEnabled;
  final bool withdrawalRejectedEnabled;
  final bool systemEnabled;

  NotificationPreferencesState copyWith({
    bool? pushEnabled,
    GamePushMode? gamePushMode,
    bool? depositApprovedEnabled,
    bool? withdrawalApprovedEnabled,
    bool? withdrawalRejectedEnabled,
    bool? systemEnabled,
  }) {
    return NotificationPreferencesState(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      gamePushMode: gamePushMode ?? this.gamePushMode,
      depositApprovedEnabled:
          depositApprovedEnabled ?? this.depositApprovedEnabled,
      withdrawalApprovedEnabled:
          withdrawalApprovedEnabled ?? this.withdrawalApprovedEnabled,
      withdrawalRejectedEnabled:
          withdrawalRejectedEnabled ?? this.withdrawalRejectedEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
    );
  }

  bool allowsCategory(String category) {
    if (!pushEnabled) {
      return false;
    }

    switch (category) {
      case notificationCategoryGameStarted:
      case notificationCategoryBonusGameStarted:
      case notificationCategoryGameFinished:
      case notificationCategoryWinnerAnnouncement:
      case notificationCategoryWinnerWindowStarted:
      case notificationCategoryBigGameTicketGranted:
        return gamePushMode != GamePushMode.off;
      case notificationCategoryRegistrationOpen:
      case notificationCategoryBigGameRegistrationOpen:
      case notificationCategoryBigGameTomorrow:
      case notificationCategoryBigGameToday:
        return gamePushMode == GamePushMode.always;
      case notificationCategoryDepositApproved:
      case notificationCategoryDepositRejected:
        return depositApprovedEnabled;
      case notificationCategoryWithdrawalApproved:
      case notificationCategoryWithdrawalCompleted:
        return withdrawalApprovedEnabled;
      case notificationCategoryWithdrawalRejected:
        return withdrawalRejectedEnabled;
      case notificationCategorySystem:
      default:
        return systemEnabled;
    }
  }
}

class NotificationPreferencesStore {
  NotificationPreferencesStore(this._prefs);

  static const _pushEnabledKey = 'notifications.push_enabled';
  static const _gamePushModeKey = 'notifications.game_push_mode';
  static const _depositApprovedEnabledKey =
      'notifications.deposit_approved_enabled';
  static const _withdrawalApprovedEnabledKey =
      'notifications.withdrawal_approved_enabled';
  static const _withdrawalRejectedEnabledKey =
      'notifications.withdrawal_rejected_enabled';
  static const _systemEnabledKey = 'notifications.system_enabled';

  /// Legacy per-category keys — used only to migrate old installs once.
  static const _legacyGameStartedEnabledKey =
      'notifications.game_started_enabled';
  static const _legacyGameFinishedEnabledKey =
      'notifications.game_finished_enabled';
  static const _legacyWinnerAnnouncementsEnabledKey =
      'notifications.winner_announcements_enabled';

  final SharedPreferences _prefs;

  NotificationPreferencesState load() {
    return NotificationPreferencesState(
      pushEnabled: _prefs.getBool(_pushEnabledKey) ?? true,
      gamePushMode: _loadGamePushMode(),
      depositApprovedEnabled:
          _prefs.getBool(_depositApprovedEnabledKey) ?? true,
      withdrawalApprovedEnabled:
          _prefs.getBool(_withdrawalApprovedEnabledKey) ?? true,
      withdrawalRejectedEnabled:
          _prefs.getBool(_withdrawalRejectedEnabledKey) ?? true,
      systemEnabled: _prefs.getBool(_systemEnabledKey) ?? true,
    );
  }

  GamePushMode _loadGamePushMode() {
    final stored = _prefs.getString(_gamePushModeKey);
    if (stored != null && stored.isNotEmpty) {
      return GamePushMode.fromApi(stored);
    }

    // Migrate old on/off game toggles into a best-effort mode.
    final gameStarted = _prefs.getBool(_legacyGameStartedEnabledKey);
    final gameFinished = _prefs.getBool(_legacyGameFinishedEnabledKey);
    final winner = _prefs.getBool(_legacyWinnerAnnouncementsEnabledKey);
    if (gameStarted == false && gameFinished == false && winner == false) {
      return GamePushMode.off;
    }
    return GamePushMode.always;
  }

  Future<void> save(NotificationPreferencesState state) async {
    await Future.wait([
      _prefs.setBool(_pushEnabledKey, state.pushEnabled),
      _prefs.setString(_gamePushModeKey, state.gamePushMode.apiValue),
      _prefs.setBool(
        _depositApprovedEnabledKey,
        state.depositApprovedEnabled,
      ),
      _prefs.setBool(
        _withdrawalApprovedEnabledKey,
        state.withdrawalApprovedEnabled,
      ),
      _prefs.setBool(
        _withdrawalRejectedEnabledKey,
        state.withdrawalRejectedEnabled,
      ),
      _prefs.setBool(_systemEnabledKey, state.systemEnabled),
    ]);
  }
}

final notificationPreferencesStoreProvider =
    FutureProvider<NotificationPreferencesStore>((ref) async {
      final prefs = await SharedPreferences.getInstance();
      return NotificationPreferencesStore(prefs);
    });

class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferencesState> {
  @override
  Future<NotificationPreferencesState> build() async {
    final store = await ref.watch(notificationPreferencesStoreProvider.future);
    final local = store.load();

    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      final mode = next.session?.user.gamePushMode;
      if (mode == null) {
        return;
      }
      final current = state.value;
      if (current == null || current.gamePushMode == mode) {
        return;
      }
      unawaited(_hydrateGamePushMode(mode));
    });

    final sessionMode =
        ref.read(sessionManagerProvider).session?.user.gamePushMode;
    if (sessionMode != null && sessionMode != local.gamePushMode) {
      final hydrated = local.copyWith(gamePushMode: sessionMode);
      await store.save(hydrated);
      return hydrated;
    }

    return local;
  }

  Future<void> setPushEnabled(bool value) {
    return _saveLocal(
      (current) => current.copyWith(pushEnabled: value),
    );
  }

  Future<void> setGamePushMode(GamePushMode value) async {
    final current = state.value ?? const NotificationPreferencesState();
    if (current.gamePushMode == value) {
      return;
    }

    final previous = current;
    final optimistic = current.copyWith(gamePushMode: value);
    state = AsyncData(optimistic);
    final store = await ref.read(notificationPreferencesStoreProvider.future);
    await store.save(optimistic);

    try {
      final apiClient = ref.read(apiClientProvider);
      final updatedUser = await apiClient.patch<UserProfile>(
        '/users/me/notification-preferences',
        data: {'gamePushMode': value.apiValue},
        decoder: (raw) {
          if (raw is! Map<String, dynamic>) {
            throw StateError('Invalid notification preferences response.');
          }
          return UserProfile.fromJson(raw);
        },
      );

      final sessionManager = ref.read(sessionManagerProvider.notifier);
      final session = ref.read(sessionManagerProvider).session;
      if (session != null) {
        await sessionManager.updateSession(
          session.copyWith(
            user: session.user.copyWith(
              gamePushMode: updatedUser.gamePushMode,
            ),
          ),
        );
      }

      final confirmed = optimistic.copyWith(
        gamePushMode: updatedUser.gamePushMode,
      );
      state = AsyncData(confirmed);
      await store.save(confirmed);
      _log('gamePushMode synced=${confirmed.gamePushMode.apiValue}');
    } catch (error) {
      _log('gamePushMode sync failed: $error');
      state = AsyncData(previous);
      await store.save(previous);
      rethrow;
    }
  }

  Future<void> setDepositApprovedEnabled(bool value) {
    return _saveLocal(
      (current) => current.copyWith(depositApprovedEnabled: value),
    );
  }

  Future<void> setWithdrawalApprovedEnabled(bool value) {
    return _saveLocal(
      (current) => current.copyWith(withdrawalApprovedEnabled: value),
    );
  }

  Future<void> setWithdrawalRejectedEnabled(bool value) {
    return _saveLocal(
      (current) => current.copyWith(withdrawalRejectedEnabled: value),
    );
  }

  Future<void> setSystemEnabled(bool value) {
    return _saveLocal(
      (current) => current.copyWith(systemEnabled: value),
    );
  }

  Future<void> _hydrateGamePushMode(GamePushMode mode) async {
    final current = state.value ?? const NotificationPreferencesState();
    final next = current.copyWith(gamePushMode: mode);
    state = AsyncData(next);
    final store = await ref.read(notificationPreferencesStoreProvider.future);
    await store.save(next);
  }

  Future<void> _saveLocal(
    NotificationPreferencesState Function(NotificationPreferencesState current)
    transform,
  ) async {
    final current = state.value ?? const NotificationPreferencesState();
    final next = transform(current);
    _log(
      'save push=${next.pushEnabled} '
      'gamePushMode=${next.gamePushMode.apiValue} '
      'deposit=${next.depositApprovedEnabled} '
      'withdrawalApproved=${next.withdrawalApprovedEnabled} '
      'withdrawalRejected=${next.withdrawalRejectedEnabled} '
      'system=${next.systemEnabled}',
    );
    state = AsyncData(next);
    final store = await ref.read(notificationPreferencesStoreProvider.future);
    await store.save(next);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Notifications/Prefs] $message');
    }
  }
}

final notificationPreferencesControllerProvider = AsyncNotifierProvider<
  NotificationPreferencesController,
  NotificationPreferencesState
>(NotificationPreferencesController.new);
