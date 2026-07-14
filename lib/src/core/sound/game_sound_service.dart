import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sound_event.dart';
import 'sound_preferences.dart';

/// Plays short in-app game sound effects gated by [SoundPreferencesState].
///
/// One-shot events (game start, winner window) are deduped per session, and
/// every play accepts an optional [dedupeKey] (e.g. called-number id or
/// claimId) so duplicate socket payloads or canonical refetches never replay.
class GameSoundService {
  GameSoundService(this._ref);

  static const _assetByEvent = <SoundEvent, String>{
    SoundEvent.calledNumber: 'sounds/ball_called.wav',
    SoundEvent.gameStart: 'sounds/game_start.wav',
    SoundEvent.winnerWindow: 'sounds/winner_window.wav',
    SoundEvent.validBingo: 'sounds/bingo_valid.wav',
  };

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer(playerId: 'game_sounds');

  String? _sessionId;
  final Set<SoundEvent> _playedOncePerSession = <SoundEvent>{};
  final Set<String> _playedDedupeKeys = <String>{};

  Future<void> play(
    SoundEvent event, {
    String? sessionId,
    String? dedupeKey,
  }) async {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return;
    }

    final preferences =
        _ref.read(soundPreferencesControllerProvider).value ??
        const SoundPreferencesState();
    if (!preferences.allowsEvent(event)) {
      return;
    }

    _syncSession(sessionId);

    final oncePerSession =
        event == SoundEvent.gameStart || event == SoundEvent.winnerWindow;
    if (oncePerSession) {
      if (_playedOncePerSession.contains(event)) {
        return;
      }
      _playedOncePerSession.add(event);
    }

    if (dedupeKey != null) {
      final scopedKey = '${event.name}:$dedupeKey';
      if (_playedDedupeKeys.contains(scopedKey)) {
        return;
      }
      _playedDedupeKeys.add(scopedKey);
    }

    try {
      await _player.stop();
      await _player.play(AssetSource(_assetByEvent[event]!));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Sounds] play ${event.name} failed: $error');
      }
      return;
    }

    if (preferences.vibrateEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _syncSession(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty || sessionId == _sessionId) {
      return;
    }
    _sessionId = sessionId;
    _playedOncePerSession.clear();
    _playedDedupeKeys.clear();
  }

  void dispose() {
    unawaited(_player.dispose());
  }
}

final gameSoundServiceProvider = Provider<GameSoundService>((ref) {
  final service = GameSoundService(ref);
  ref.onDispose(service.dispose);
  return service;
});
