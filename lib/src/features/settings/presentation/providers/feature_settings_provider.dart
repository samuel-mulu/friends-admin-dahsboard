import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/user_profile.dart';
import '../../../auth/session/session_manager.dart';
import '../../data/feature_settings_repository.dart';
import '../../domain/feature_settings.dart';

class FeatureSettingsController extends AsyncNotifier<FeatureSettingsUiState> {
  var _boundUserId = '';
  var _autoMarkEpoch = 0;
  var _autoBingoEpoch = 0;

  @override
  Future<FeatureSettingsUiState> build() async {
    final session = ref.watch(sessionManagerProvider).session;
    final userId = session?.user.id ?? '';

    if (userId.isEmpty) {
      _boundUserId = '';
      return const FeatureSettingsUiState();
    }

    if (_boundUserId != userId) {
      _boundUserId = userId;
      _autoMarkEpoch = 0;
      _autoBingoEpoch = 0;
    }

    final hydrated = _fromUserProfile(session!.user);
    // Kick a server refresh without blocking first paint on session hydrate.
    unawaited(refresh(quiet: true));
    return FeatureSettingsUiState(settings: hydrated);
  }

  Future<void> refresh({bool quiet = false}) async {
    final session = ref.read(sessionManagerProvider).session;
    if (session == null) {
      state = const AsyncData(FeatureSettingsUiState());
      return;
    }

    try {
      final settings = await ref
          .read(featureSettingsRepositoryProvider)
          .getFeatureSettings();
      _applyAuthoritative(settings);
    } catch (error, stackTrace) {
      _log('refresh failed: $error');
      if (!quiet && state.hasValue) {
        // Keep last known good UI state; surface only when empty.
        return;
      }
      if (!state.hasValue) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  void applySocketSettings(FeatureSettings incoming) {
    _applyAuthoritative(incoming);
  }

  Future<void> setAutoMarkEnabled(bool value) async {
    await _setPreference(
      field: _PreferenceField.autoMark,
      value: value,
    );
  }

  Future<void> setAutoBingoEnabled(bool value) async {
    await _setPreference(
      field: _PreferenceField.autoBingo,
      value: value,
    );
  }

  Future<void> _setPreference({
    required _PreferenceField field,
    required bool value,
  }) async {
    final current = state.value ?? const FeatureSettingsUiState();
    final settings = current.settings;

    if (field == _PreferenceField.autoMark) {
      if (!settings.autoMarkGranted || settings.autoMarkEnabled == value) {
        return;
      }
      if (current.autoMarkPending) {
        return;
      }
    } else {
      if (!settings.autoBingoGranted || settings.autoBingoEnabled == value) {
        return;
      }
      if (current.autoBingoPending) {
        return;
      }
    }

    final epoch = field == _PreferenceField.autoMark
        ? ++_autoMarkEpoch
        : ++_autoBingoEpoch;

    final optimisticSettings = field == _PreferenceField.autoMark
        ? settings.copyWith(
            autoMarkEnabled: value,
            effectiveAutoMark: settings.autoMarkGranted && value,
          )
        : settings.copyWith(
            autoBingoEnabled: value,
            effectiveAutoBingo: settings.autoBingoGranted && value,
          );

    state = AsyncData(
      current.copyWith(
        settings: optimisticSettings,
        autoMarkPending: field == _PreferenceField.autoMark
            ? true
            : current.autoMarkPending,
        autoBingoPending: field == _PreferenceField.autoBingo
            ? true
            : current.autoBingoPending,
      ),
    );

    try {
      final confirmed = await ref
          .read(featureSettingsRepositoryProvider)
          .updateFeatureSettings(
            autoMarkEnabled: field == _PreferenceField.autoMark ? value : null,
            autoBingoEnabled: field == _PreferenceField.autoBingo
                ? value
                : null,
          );

      if (!_isEpochCurrent(field, epoch)) {
        return;
      }

      _applyAuthoritative(
        confirmed,
        clearAutoMarkPending: field == _PreferenceField.autoMark,
        clearAutoBingoPending: field == _PreferenceField.autoBingo,
      );
    } catch (error) {
      _log('patch failed field=$field error=$error');
      if (!_isEpochCurrent(field, epoch)) {
        return;
      }

      // Do not restore a stale optimistic snapshot — reconcile with server.
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          autoMarkPending: field == _PreferenceField.autoMark
              ? false
              : latest.autoMarkPending,
          autoBingoPending: field == _PreferenceField.autoBingo
              ? false
              : latest.autoBingoPending,
        ),
      );
      await refresh(quiet: true);
      rethrow;
    }
  }

  void _applyAuthoritative(
    FeatureSettings incoming, {
    bool clearAutoMarkPending = false,
    bool clearAutoBingoPending = false,
  }) {
    final current = state.value ?? const FeatureSettingsUiState();
    final accepted = FeatureSettings.takeIfNewer(
      current: current.settings,
      incoming: incoming,
    );
    if (accepted == null) {
      _log(
        'ignored stale settings version=${incoming.featureSettingsVersion} '
        'current=${current.settings.featureSettingsVersion}',
      );
      if (clearAutoMarkPending || clearAutoBingoPending) {
        state = AsyncData(
          current.copyWith(
            autoMarkPending: clearAutoMarkPending
                ? false
                : current.autoMarkPending,
            autoBingoPending: clearAutoBingoPending
                ? false
                : current.autoBingoPending,
          ),
        );
      }
      return;
    }

    state = AsyncData(
      current.copyWith(
        settings: accepted,
        autoMarkPending: clearAutoMarkPending ? false : current.autoMarkPending,
        autoBingoPending: clearAutoBingoPending
            ? false
            : current.autoBingoPending,
      ),
    );
  }

  bool _isEpochCurrent(_PreferenceField field, int epoch) {
    return field == _PreferenceField.autoMark
        ? epoch == _autoMarkEpoch
        : epoch == _autoBingoEpoch;
  }

  static FeatureSettings _fromUserProfile(UserProfile user) {
    return FeatureSettings(
      autoMarkGranted: user.autoMarkGranted,
      autoBingoGranted: user.autoBingoGranted,
      autoMarkEnabled: user.autoMarkEnabled,
      autoBingoEnabled: user.autoBingoEnabled,
      effectiveAutoMark: user.effectiveAutoMark,
      effectiveAutoBingo: user.effectiveAutoBingo,
      featureSettingsVersion: user.featureSettingsVersion,
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FeatureSettings] $message');
    }
  }
}

enum _PreferenceField { autoMark, autoBingo }

final featureSettingsControllerProvider =
    AsyncNotifierProvider<FeatureSettingsController, FeatureSettingsUiState>(
      FeatureSettingsController.new,
    );
