import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/domain/cartela_marked_pattern_evaluator.dart';

class LiveCartelaLiveSyncInput {
  const LiveCartelaLiveSyncInput({
    required this.cartelas,
    required this.ruleKey,
    required this.marksFor,
    required this.latestCalledNumber,
    required this.frozenSortResults,
  });

  final List<GameCartelaModel> cartelas;
  final String ruleKey;
  final Set<String> Function(GameCartelaModel cartela) marksFor;
  final int? latestCalledNumber;
  final Map<String, CartelaPatternUiResult> frozenSortResults;
}

Map<int, Set<String>> buildBallNumberToCartelaIds(
  List<GameCartelaModel> cartelas,
) {
  final index = <int, Set<String>>{};
  for (final gameCartela in cartelas) {
    final columns = gameCartela.cartela.columns;
    for (var col = 0; col < columns.length && col < 5; col++) {
      for (var row = 0; row < columns[col].length && row < 5; row++) {
        if (col == 2 && row == 2) {
          continue;
        }
        final number = int.tryParse(columns[col][row]);
        if (number == null || number <= 0) {
          continue;
        }
        index.putIfAbsent(number, () => <String>{}).add(gameCartela.id);
      }
    }
  }
  return index;
}
