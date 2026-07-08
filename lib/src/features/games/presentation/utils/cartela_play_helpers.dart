import '../../data/models/cartela_model.dart';
import '../../data/models/game_cartela_model.dart';
import 'cartela_marked_pattern_evaluator.dart';

bool oneAwayFromWin({
  required Set<String> manualMarkedNumbers,
  required List<List<String>> columns,
  required String ruleKey,
}) {
  final cartela = _cartelaForColumns(columns);
  final result = CartelaMarkedPatternEvaluator.evaluate(
    cartela: cartela,
    manualMarkedNumbers: manualMarkedNumbers,
    ruleKey: ruleKey,
  );

  return result.isOneAway;
}

List<GameCartelaModel> sortCartelasForPlay({
  required List<GameCartelaModel> cartelas,
  required Set<String> manualMarkedNumbers,
  required String ruleKey,
  CartelaSortMode sortMode = CartelaSortMode.manual,
}) {
  final results = CartelaMarkedPatternEvaluator.evaluateAll(
    cartelas: cartelas,
    manualMarkedNumbers: manualMarkedNumbers,
    ruleKey: ruleKey,
  );
  return CartelaMarkedPatternEvaluator.sortCartelas(
    cartelas: cartelas,
    resultsByCartelaId: results,
    sortMode: sortMode,
  );
}

GameCartelaModel _cartelaForColumns(List<List<String>> columns) {
  final now = DateTime.utc(2026, 1, 1);
  return GameCartelaModel(
    id: 'helper-cartela',
    gameId: 'helper-session',
    userId: 'helper-user',
    cartelaId: 'helper-cartela',
    status: GameCartelaStatus.registered,
    isWinner: false,
    blockedAt: null,
    createdAt: now,
    updatedAt: now,
    cartela: _HelperCartelaModel(columns: columns).toCartelaModel(now),
  );
}

class _HelperCartelaModel {
  const _HelperCartelaModel({required this.columns});

  final List<List<String>> columns;

  CartelaModel toCartelaModel(DateTime now) {
    return CartelaModel(
      id: 'helper-cartela',
      number: 0,
      createdAt: now,
      b: columns[0],
      i: columns[1],
      n: columns[2],
      g: columns[3],
      o: columns[4],
    );
  }
}
