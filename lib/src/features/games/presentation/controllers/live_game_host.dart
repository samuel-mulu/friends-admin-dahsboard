import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../../core/time/server_clock_service.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/game_model.dart';
import '../../data/models/game_timing_config_model.dart';
import '../providers/game_operations_sync_coordinator.dart';
import '../utils/live_ui_mode.dart';
import 'live_game_controllers.dart';

/// Narrow surface the live controllers use to read session truth and request UI
/// rebuilds. Presentation mode is always derived via [resolveLiveUiMode].
abstract class LiveGameHost {
  bool get mounted;

  /// False while tearing down — safe for async/socket callbacks to bail out.
  bool get isLiveHostActive;

  BuildContext get context;

  WidgetRef get ref;

  bool get embedded;

  bool get isAppInForeground;

  String? get gameId;

  GameModel? get initialGame;

  LiveGameControllers get controllers;

  void markNeedsBuild([VoidCallback? fn]);

  // Canonical session snapshot (backend truth after apply).
  GameModel? get game;

  set game(GameModel? value);

  GameOperationsCurrentResponse? get lastOperations;

  set lastOperations(GameOperationsCurrentResponse? value);

  GameModel? get nextUpcomingGame;

  set nextUpcomingGame(GameModel? value);

  bool get hasBlockingLiveGame;

  set hasBlockingLiveGame(bool value);

  bool get isLoading;

  set isLoading(bool value);

  String? get errorMessage;

  set errorMessage(String? value);

  String? get emptyMessage;

  set emptyMessage(String? value);

  bool get timingConfigLoaded;

  GameTimingConfigModel get effectiveTimingConfig;

  bool get awaitingLiveRoom;

  set awaitingLiveRoom(bool value);

  int get loadGeneration;

  set loadGeneration(int value);

  bool get isGuest;

  GamesRepository get gamesRepository;

  /// Ownership test used by the read-only missed-player preview observer.
  /// True when the player owns cartelas in [sessionId] (never for Player 2's
  /// observed round).
  bool ownsSessionForPreview(String? sessionId);

  SocketService get socketService;

  ServerClockService get serverClock;

  List<GameCartelaModel> get myCartelas;

  DateTime countdownNow({bool useServerClock = true});

  LiveUiModeState get liveUiMode;

  bool get currentReadyCountdownDeferredByLiveGame;

  Duration get preparingPhaseCap;

  /// True while post-game summary / terminal refetch should block resume sync.
  bool get isTerminalTransitionActive;

  /// True after the first successful canonical apply on this screen instance.
  bool get initialLoadComplete;

  /// Full canonical reload after resume/reconnect (backend truth only).
  Future<void> runResumeSync({
    bool allowCachedOperations = true,
    OperationsSyncReason operationsSyncReason = OperationsSyncReason.appResume,
  });

  /// Invoked by controllers that need a full canonical reload.
  Future<void> runInitialLoad({
    bool showLoading = true,
    bool includeCalledNumbers = true,
    bool includeMyCartelas = true,
    bool allowTerminalTransition = false,
    GameModel? advanceTarget,
    OperationsSyncReason operationsSyncReason =
        OperationsSyncReason.inconsistencyRecovery,
  });
}
