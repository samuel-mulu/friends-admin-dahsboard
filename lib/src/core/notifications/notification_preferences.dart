import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_notification_category.dart';

@immutable
class NotificationPreferencesState {
  const NotificationPreferencesState({
    this.pushEnabled = true,
    this.gameStartedEnabled = true,
    this.gameFinishedEnabled = true,
    this.winnerAnnouncementsEnabled = true,
    this.depositApprovedEnabled = true,
    this.withdrawalApprovedEnabled = true,
    this.withdrawalRejectedEnabled = true,
    this.systemEnabled = true,
  });

  final bool pushEnabled;
  final bool gameStartedEnabled;
  final bool gameFinishedEnabled;
  final bool winnerAnnouncementsEnabled;
  final bool depositApprovedEnabled;
  final bool withdrawalApprovedEnabled;
  final bool withdrawalRejectedEnabled;
  final bool systemEnabled;

  NotificationPreferencesState copyWith({
    bool? pushEnabled,
    bool? gameStartedEnabled,
    bool? gameFinishedEnabled,
    bool? winnerAnnouncementsEnabled,
    bool? depositApprovedEnabled,
    bool? withdrawalApprovedEnabled,
    bool? withdrawalRejectedEnabled,
    bool? systemEnabled,
  }) {
    return NotificationPreferencesState(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      gameStartedEnabled: gameStartedEnabled ?? this.gameStartedEnabled,
      gameFinishedEnabled: gameFinishedEnabled ?? this.gameFinishedEnabled,
      winnerAnnouncementsEnabled:
          winnerAnnouncementsEnabled ?? this.winnerAnnouncementsEnabled,
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
        return gameStartedEnabled;
      case notificationCategoryGameFinished:
        return gameFinishedEnabled;
      case notificationCategoryWinnerAnnouncement:
      case notificationCategoryWinnerWindowStarted:
        return winnerAnnouncementsEnabled;
      case notificationCategoryRegistrationOpen:
      case notificationCategoryBigGameRegistrationOpen:
      case notificationCategoryBigGameTomorrow:
      case notificationCategoryBigGameToday:
        return gameStartedEnabled;
      case notificationCategoryDepositApproved:
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
  static const _gameStartedEnabledKey = 'notifications.game_started_enabled';
  static const _gameFinishedEnabledKey = 'notifications.game_finished_enabled';
  static const _winnerAnnouncementsEnabledKey =
      'notifications.winner_announcements_enabled';
  static const _depositApprovedEnabledKey =
      'notifications.deposit_approved_enabled';
  static const _withdrawalApprovedEnabledKey =
      'notifications.withdrawal_approved_enabled';
  static const _withdrawalRejectedEnabledKey =
      'notifications.withdrawal_rejected_enabled';
  static const _systemEnabledKey = 'notifications.system_enabled';

  final SharedPreferences _prefs;

  NotificationPreferencesState load() {
    return NotificationPreferencesState(
      pushEnabled: _prefs.getBool(_pushEnabledKey) ?? true,
      gameStartedEnabled: _prefs.getBool(_gameStartedEnabledKey) ?? true,
      gameFinishedEnabled: _prefs.getBool(_gameFinishedEnabledKey) ?? true,
      winnerAnnouncementsEnabled:
          _prefs.getBool(_winnerAnnouncementsEnabledKey) ?? true,
      depositApprovedEnabled:
          _prefs.getBool(_depositApprovedEnabledKey) ?? true,
      withdrawalApprovedEnabled:
          _prefs.getBool(_withdrawalApprovedEnabledKey) ?? true,
      withdrawalRejectedEnabled:
          _prefs.getBool(_withdrawalRejectedEnabledKey) ?? true,
      systemEnabled: _prefs.getBool(_systemEnabledKey) ?? true,
    );
  }

  Future<void> save(NotificationPreferencesState state) async {
    await Future.wait([
      _prefs.setBool(_pushEnabledKey, state.pushEnabled),
      _prefs.setBool(_gameStartedEnabledKey, state.gameStartedEnabled),
      _prefs.setBool(_gameFinishedEnabledKey, state.gameFinishedEnabled),
      _prefs.setBool(
        _winnerAnnouncementsEnabledKey,
        state.winnerAnnouncementsEnabled,
      ),
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
    return store.load();
  }

  Future<void> setPushEnabled(bool value) {
    return _save(
      (current) => current.copyWith(pushEnabled: value),
    );
  }

  Future<void> setGameStartedEnabled(bool value) {
    return _save(
      (current) => current.copyWith(gameStartedEnabled: value),
    );
  }

  Future<void> setGameFinishedEnabled(bool value) {
    return _save(
      (current) => current.copyWith(gameFinishedEnabled: value),
    );
  }

  Future<void> setWinnerAnnouncementsEnabled(bool value) {
    return _save(
      (current) => current.copyWith(winnerAnnouncementsEnabled: value),
    );
  }

  Future<void> setDepositApprovedEnabled(bool value) {
    return _save(
      (current) => current.copyWith(depositApprovedEnabled: value),
    );
  }

  Future<void> setWithdrawalApprovedEnabled(bool value) {
    return _save(
      (current) => current.copyWith(withdrawalApprovedEnabled: value),
    );
  }

  Future<void> setWithdrawalRejectedEnabled(bool value) {
    return _save(
      (current) => current.copyWith(withdrawalRejectedEnabled: value),
    );
  }

  Future<void> setSystemEnabled(bool value) {
    return _save(
      (current) => current.copyWith(systemEnabled: value),
    );
  }

  Future<void> _save(
    NotificationPreferencesState Function(NotificationPreferencesState current)
    transform,
  ) async {
    final current = state.value ?? const NotificationPreferencesState();
    final next = transform(current);
    _log(
      'save push=${next.pushEnabled} '
      'gameStarted=${next.gameStartedEnabled} '
      'gameFinished=${next.gameFinishedEnabled} '
      'winner=${next.winnerAnnouncementsEnabled} '
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
