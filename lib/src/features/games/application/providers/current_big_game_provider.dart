import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/controllers/auth_controller.dart';
import '../../../../core/realtime/socket_service.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_model.dart';
import '../../domain/live_connection_status.dart';
import '../../presentation/debug/big_game_debug.dart';
import '../../presentation/utils/big_game_live_presentation.dart';
import 'big_game_summary_ledger_provider.dart';
import 'realtime_connection_provider.dart';

final currentBigGameProvider =
    AsyncNotifierProvider<CurrentBigGameNotifier, GameModel?>(
      CurrentBigGameNotifier.new,
    );

class CurrentBigGameNotifier extends AsyncNotifier<GameModel?> {
  Future<GameModel?>? _inFlight;
  Timer? _refreshDebounce;
  static const _structuralRefreshDebounce = Duration(milliseconds: 350);

  /// Last final-round terminal card retained while `/big-game/current` is null
  /// so the embedded summary can finish (Continue / Live hold). Cleared on
  /// dismiss, newer authoritative event, or auth loss.
  GameModel? _retainedFinalTerminal;

  @override
  Future<GameModel?> build() async {
    ref.watch(authControllerProvider);
    if (ref.read(authControllerProvider).session == null) {
      _retainedFinalTerminal = null;
      return null;
    }

    ref.listen(realtimeConnectionProvider, (previous, next) {
      if (previous != LiveConnectionStatus.live &&
          next == LiveConnectionStatus.live) {
        unawaited(refresh());
      }
    });

    ref.listen(bigGameSummaryLedgerProvider, (previous, next) {
      final retained = _retainedFinalTerminal;
      final sessionId = retained?.sessionId;
      final userId = ref.read(authControllerProvider).session?.user.id;
      if (retained == null || sessionId == null || userId == null) {
        return;
      }
      if (next.isDismissed(
        userId: userId,
        slotId: retained.id,
        sessionId: sessionId,
      )) {
        _retainedFinalTerminal = null;
        if (state.hasValue && state.value?.sessionId == sessionId) {
          state = const AsyncData(null);
        }
      }
    });

    final socket = ref.read(socketServiceProvider);
    void onStructural(dynamic payload) {
      if (!_payloadTouchesBigGame(payload)) {
        return;
      }
      _scheduleStructuralRefresh();
    }

    void onCancelled(dynamic payload) {
      // Always refresh — cancelled Big Game should clear the card.
      _scheduleStructuralRefresh(immediate: true);
    }

    const events = <String>[
      'game:status_changed',
      'game:operation_updated',
      'game:finished',
      'session:cartelas_updated',
      'session:prize_updated',
      'slot:status_changed',
    ];

    for (final event in events) {
      socket.on(event, onStructural);
    }
    socket.on('game:cancelled', onCancelled);

    ref.onDispose(() {
      _refreshDebounce?.cancel();
      for (final event in events) {
        socket.off(event, onStructural);
      }
      socket.off('game:cancelled', onCancelled);
    });

    return _resolveCard(await _loadBigGame());
  }

  void _scheduleStructuralRefresh({bool immediate = false}) {
    _refreshDebounce?.cancel();
    if (immediate) {
      unawaited(refresh());
      return;
    }
    _refreshDebounce = Timer(_structuralRefreshDebounce, () {
      unawaited(refresh());
    });
  }

  bool _payloadTouchesBigGame(dynamic payload) {
    if (payload is! Map) {
      // Unknown shape — refresh once so we never miss a handoff.
      return true;
    }

    final map = Map<Object?, Object?>.from(payload);
    final category = map['category']?.toString().toUpperCase();
    final isBigGame =
        category == 'BIG_GAME' || map['isBigGame'] == true;
    if (isBigGame) {
      return true;
    }

    final current = state.value ?? _retainedFinalTerminal;
    if (current == null) {
      // No cache yet — only refresh when category is clearly Big Game.
      return false;
    }

    final sessionId =
        map['sessionId']?.toString() ?? map['id']?.toString();
    String? slotId =
        map['slotId']?.toString() ?? map['gameSlotId']?.toString();
    final gameSlot = map['gameSlot'];
    if (slotId == null && gameSlot is Map) {
      slotId = gameSlot['id']?.toString();
    }

    if (sessionId != null &&
        (sessionId == current.sessionId ||
            sessionId == current.previousRound?.sessionId ||
            sessionId == current.nextRoundRegistration?.sessionId ||
            sessionId ==
                current.nextRoundRegistration?.previousRound?.sessionId)) {
      return true;
    }
    if (slotId != null && slotId == current.id) {
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    if (ref.read(authControllerProvider).session == null) {
      _retainedFinalTerminal = null;
      state = const AsyncData(null);
      return;
    }

    final current = state.value;
    if (current == null && _retainedFinalTerminal == null) {
      state = const AsyncLoading<GameModel?>();
    }

    try {
      final next = await _loadBigGame();
      if (!ref.mounted) {
        return;
      }
      final resolved = _resolveCard(next);
      final previous = state.value;
      final roundChanged =
          previous?.sessionId != resolved?.sessionId ||
          previous?.status != resolved?.status ||
          previous?.roundIndex != resolved?.roundIndex ||
          previous?.nextRoundRegistration?.sessionId !=
              resolved?.nextRoundRegistration?.sessionId ||
          previous?.scheduledStartAt != resolved?.scheduledStartAt ||
          previous?.canRegister != resolved?.canRegister;
      if (roundChanged) {
        BigGameDebug.snapshot(resolved, reason: 'refresh_round_change');
      }
      state = AsyncData(resolved);
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      if (current != null || _retainedFinalTerminal != null) {
        state = AsyncData(current ?? _retainedFinalTerminal);
        return;
      }
      state = AsyncError(error, stackTrace);
    }
  }

  /// Prefer authoritative API card. On null after last-round tearDown, retain
  /// the final-round card (promoting live/WW → FINISHED for shell phase) so
  /// Live can show winner dialog + PIN summary for the configured hold.
  ///
  /// Root cause this covers: backend never returns final FINISHED on
  /// `/big-game/current` (lean set drops torn-down terminals), so retention
  /// must seed from the previous PLAYING/WW card — not only observed FINISHED.
  ///
  /// Limitation: cold process restart after teardown (API already null, no
  /// in-memory previous card) cannot restore the final PIN without backend grace.
  GameModel? _resolveCard(GameModel? next) {
    if (next != null) {
      if (_retainedFinalTerminal != null &&
          next.id != _retainedFinalTerminal!.id) {
        // Newer Big Game event replaces retained finished card.
        BigGameDebug.log(
          'retention_drop reason=newer_event '
          'prevSlot=${_retainedFinalTerminal!.id} nextSlot=${next.id}',
        );
        _retainedFinalTerminal = null;
      } else if (isBigGameFinalTerminalCard(next)) {
        _retainedFinalTerminal = next;
        BigGameDebug.log(
          'retention_seed reason=api_final_finished '
          'session=${next.sessionId} round=${next.displayRoundIndex}',
        );
      } else if (isBigGameFinalRoundCard(next)) {
        // Keep a live final-round card as retention seed so a later null
        // refresh can promote it even if FINISHED is never observed.
        _retainedFinalTerminal = next;
        BigGameDebug.log(
          'retention_seed reason=api_final_live '
          'status=${next.status.name} session=${next.sessionId}',
        );
      } else if (_retainedFinalTerminal != null &&
          next.sessionId != _retainedFinalTerminal!.sessionId) {
        BigGameDebug.log(
          'retention_drop reason=session_moved '
          'retained=${_retainedFinalTerminal!.sessionId} next=${next.sessionId}',
        );
        _retainedFinalTerminal = null;
      }
      return next;
    }

    final previous = state.hasValue ? state.value : null;
    final retained = resolveRetainedBigGameCardAfterCurrentNull(
      previousCard: previous,
      alreadyRetained: _retainedFinalTerminal,
      isDismissed: ({required slotId, required sessionId}) {
        return ref.read(bigGameSummaryLedgerProvider.notifier).isDismissed(
              slotId: slotId,
              sessionId: sessionId,
            );
      },
    );
    if (retained == null) {
      BigGameDebug.log(
        'retention_miss reason=api_null '
        'prevStatus=${previous?.status.name ?? '-'} '
        'prevRound=${previous?.displayRoundIndex ?? '-'}/'
        '${previous?.displayRoundCount ?? '-'} '
        'hadRetained=${_retainedFinalTerminal != null}',
      );
      _retainedFinalTerminal = null;
      return null;
    }

    BigGameDebug.log(
      'retention_keep reason=api_null '
      'session=${retained.sessionId} status=${retained.status.name} '
      'round=${retained.displayRoundIndex}/${retained.displayRoundCount}',
    );
    _retainedFinalTerminal = retained;
    return retained;
  }

  Future<GameModel?> _loadBigGame() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = ref.read(gamesRepositoryProvider).getCurrentBigGame();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }
}
