import 'package:flutter/foundation.dart';

import 'package:friends_bingo_app/src/features/games/presentation/debug/live_cartela_scroll_debug.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';
import 'live_cartela_live_store_sync.dart';

/// Notifies cartela tiles/grid when live marks or pattern state changes (Auto Mark).
class LiveCartelaLiveStore extends ChangeNotifier {
  final ValueNotifier<int> gridRevision = ValueNotifier<int>(0);
  final Map<String, ValueNotifier<int>> _tileRevisions = {};
  Map<int, Set<String>> _ballNumberToCartelaIds = {};

  ValueListenable<int> get gridListenable => gridRevision;

  ValueListenable<int> listenableFor(String gameCartelaId) {
    return _tileRevisions.putIfAbsent(
      gameCartelaId,
      () => ValueNotifier<int>(0),
    );
  }

  void clear() {
    _ballNumberToCartelaIds = {};
    for (final listenable in _tileRevisions.values) {
      listenable.dispose();
    }
    _tileRevisions.clear();
    gridRevision.value = 0;
    notifyListeners();
  }

  void syncCartelas(List<GameCartelaModel> cartelas) {
    _ballNumberToCartelaIds = buildBallNumberToCartelaIds(cartelas);
    final active = cartelas.map((c) => c.id).toSet();
    for (final id in _tileRevisions.keys.toList()) {
      if (!active.contains(id)) {
        _tileRevisions.remove(id)?.dispose();
      }
    }
    for (final cartela in cartelas) {
      _tileRevisions.putIfAbsent(cartela.id, () => ValueNotifier<int>(0));
    }
    _bumpGrid();
  }

  /// After sort/marks update: refresh tiles touched by [committedBallNumber].
  void afterCalledNumbersUpdated({
    required List<GameCartelaModel> cartelas,
    int? committedBallNumber,
    bool fullGrid = false,
  }) {
    syncCartelas(cartelas);
    var tilesBumped = 0;
    if (fullGrid || committedBallNumber == null) {
      for (final listenable in _tileRevisions.values) {
        listenable.value++;
        tilesBumped++;
      }
    } else {
      final touched = _ballNumberToCartelaIds[committedBallNumber];
      if (touched == null || touched.isEmpty) {
        LiveCartelaScrollDebug.storeGridUpdate(
          gridRevision: gridRevision.value,
          ballNumber: committedBallNumber,
          fullGrid: fullGrid,
          tilesBumped: 0,
        );
        return;
      }
      for (final id in touched) {
        final listenable = _tileRevisions[id];
        if (listenable != null) {
          listenable.value++;
          tilesBumped++;
        }
      }
    }
    LiveCartelaScrollDebug.storeGridUpdate(
      gridRevision: gridRevision.value,
      ballNumber: committedBallNumber,
      fullGrid: fullGrid,
      tilesBumped: tilesBumped,
    );
  }

  void afterManualMarkOnCartela(String gameCartelaId) {
    _tileRevisions[gameCartelaId]?.value++;
  }

  void _bumpGrid() {
    gridRevision.value++;
    notifyListeners();
  }

  @override
  void dispose() {
    gridRevision.dispose();
    for (final listenable in _tileRevisions.values) {
      listenable.dispose();
    }
    _tileRevisions.clear();
    super.dispose();
  }
}

/// Reserved for Phase C tile-scoped VM reads (pattern overlay per cartela).
@immutable
class CartelaLiveVmSnapshot {
  const CartelaLiveVmSnapshot({
    required this.sortResult,
  });

  final CartelaPatternUiResult sortResult;
}
