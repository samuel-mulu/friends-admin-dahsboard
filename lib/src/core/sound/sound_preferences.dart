import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sound_event.dart';

@immutable
class SoundPreferencesState {
  const SoundPreferencesState({
    this.soundsEnabled = true,
    this.calledNumberEnabled = true,
    this.gameStartEnabled = true,
    this.winnerWindowEnabled = true,
    this.validBingoEnabled = true,
    this.vibrateEnabled = false,
  });

  final bool soundsEnabled;
  final bool calledNumberEnabled;
  final bool gameStartEnabled;
  final bool winnerWindowEnabled;
  final bool validBingoEnabled;
  final bool vibrateEnabled;

  SoundPreferencesState copyWith({
    bool? soundsEnabled,
    bool? calledNumberEnabled,
    bool? gameStartEnabled,
    bool? winnerWindowEnabled,
    bool? validBingoEnabled,
    bool? vibrateEnabled,
  }) {
    return SoundPreferencesState(
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      calledNumberEnabled: calledNumberEnabled ?? this.calledNumberEnabled,
      gameStartEnabled: gameStartEnabled ?? this.gameStartEnabled,
      winnerWindowEnabled: winnerWindowEnabled ?? this.winnerWindowEnabled,
      validBingoEnabled: validBingoEnabled ?? this.validBingoEnabled,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
    );
  }

  bool allowsEvent(SoundEvent event) {
    if (!soundsEnabled) {
      return false;
    }

    switch (event) {
      case SoundEvent.calledNumber:
        return calledNumberEnabled;
      case SoundEvent.gameStart:
        return gameStartEnabled;
      case SoundEvent.winnerWindow:
        return winnerWindowEnabled;
      case SoundEvent.validBingo:
        return validBingoEnabled;
    }
  }
}

class SoundPreferencesStore {
  SoundPreferencesStore(this._prefs);

  static const _soundsEnabledKey = 'sounds.enabled';
  static const _calledNumberEnabledKey = 'sounds.called_number_enabled';
  static const _gameStartEnabledKey = 'sounds.game_start_enabled';
  static const _winnerWindowEnabledKey = 'sounds.winner_window_enabled';
  static const _validBingoEnabledKey = 'sounds.valid_bingo_enabled';
  static const _vibrateEnabledKey = 'sounds.vibrate_enabled';

  final SharedPreferences _prefs;

  SoundPreferencesState load() {
    return SoundPreferencesState(
      soundsEnabled: _prefs.getBool(_soundsEnabledKey) ?? true,
      calledNumberEnabled: _prefs.getBool(_calledNumberEnabledKey) ?? true,
      gameStartEnabled: _prefs.getBool(_gameStartEnabledKey) ?? true,
      winnerWindowEnabled: _prefs.getBool(_winnerWindowEnabledKey) ?? true,
      validBingoEnabled: _prefs.getBool(_validBingoEnabledKey) ?? true,
      vibrateEnabled: _prefs.getBool(_vibrateEnabledKey) ?? false,
    );
  }

  Future<void> save(SoundPreferencesState state) async {
    await Future.wait([
      _prefs.setBool(_soundsEnabledKey, state.soundsEnabled),
      _prefs.setBool(_calledNumberEnabledKey, state.calledNumberEnabled),
      _prefs.setBool(_gameStartEnabledKey, state.gameStartEnabled),
      _prefs.setBool(_winnerWindowEnabledKey, state.winnerWindowEnabled),
      _prefs.setBool(_validBingoEnabledKey, state.validBingoEnabled),
      _prefs.setBool(_vibrateEnabledKey, state.vibrateEnabled),
    ]);
  }
}

final soundPreferencesStoreProvider =
    FutureProvider<SoundPreferencesStore>((ref) async {
      final prefs = await SharedPreferences.getInstance();
      return SoundPreferencesStore(prefs);
    });

class SoundPreferencesController
    extends AsyncNotifier<SoundPreferencesState> {
  @override
  Future<SoundPreferencesState> build() async {
    final store = await ref.watch(soundPreferencesStoreProvider.future);
    return store.load();
  }

  Future<void> setSoundsEnabled(bool value) {
    return _save(
      (current) => current.copyWith(soundsEnabled: value),
    );
  }

  Future<void> setCalledNumberEnabled(bool value) {
    return _save(
      (current) => current.copyWith(calledNumberEnabled: value),
    );
  }

  Future<void> setGameStartEnabled(bool value) {
    return _save(
      (current) => current.copyWith(gameStartEnabled: value),
    );
  }

  Future<void> setWinnerWindowEnabled(bool value) {
    return _save(
      (current) => current.copyWith(winnerWindowEnabled: value),
    );
  }

  Future<void> setValidBingoEnabled(bool value) {
    return _save(
      (current) => current.copyWith(validBingoEnabled: value),
    );
  }

  Future<void> setVibrateEnabled(bool value) {
    return _save(
      (current) => current.copyWith(vibrateEnabled: value),
    );
  }

  Future<void> _save(
    SoundPreferencesState Function(SoundPreferencesState current) transform,
  ) async {
    final current = state.value ?? const SoundPreferencesState();
    final next = transform(current);
    _log(
      'save sounds=${next.soundsEnabled} '
      'calledNumber=${next.calledNumberEnabled} '
      'gameStart=${next.gameStartEnabled} '
      'winnerWindow=${next.winnerWindowEnabled} '
      'validBingo=${next.validBingoEnabled} '
      'vibrate=${next.vibrateEnabled}',
    );
    state = AsyncData(next);
    final store = await ref.read(soundPreferencesStoreProvider.future);
    await store.save(next);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Sounds/Prefs] $message');
    }
  }
}

final soundPreferencesControllerProvider = AsyncNotifierProvider<
  SoundPreferencesController,
  SoundPreferencesState
>(SoundPreferencesController.new);
