import 'package:flutter/foundation.dart';

import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';

/// Per-cartela live-play presentation snapshot (marks/sort UI inputs).
@immutable
class CartelaLiveVm {
  const CartelaLiveVm({
    required this.gameCartelaId,
    required this.sortResult,
    required this.revision,
  });

  final String gameCartelaId;
  final CartelaPatternUiResult sortResult;
  final int revision;

  CartelaLiveVm copyWith({
    CartelaPatternUiResult? sortResult,
    int? revision,
  }) {
    return CartelaLiveVm(
      gameCartelaId: gameCartelaId,
      sortResult: sortResult ?? this.sortResult,
      revision: revision ?? this.revision,
    );
  }
}
