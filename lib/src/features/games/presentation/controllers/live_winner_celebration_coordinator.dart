import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/round_winner_history_model.dart';
import '../utils/round_winner_history_adapters.dart';

/// Coordinates winner cartela tracking, dialog auto-dismiss scheduling,
/// and All-Rounds Winner history caching for Big Game and Chain Game.
class LiveWinnerCelebrationCoordinator {
  final List<int> _winnerCartelaNumbers = [];
  final Map<int, GameCartelaModel> _winnerCards = {};
  bool isDialogOpen = false;

  // All-Rounds Winner History state (Big Game + Chain only).
  RoundWinnerHistory? allRoundsWinnerHistory;
  List<AllRoundsWinnerCardData> allRoundsWinnerCards = const [];
  bool allRoundsWinnerHistoryLoading = false;
  String? allRoundsWinnerHistoryError;
  String? allRoundsWinnerHistoryKey;

  List<int> get winnerCartelaNumbers => List.unmodifiable(_winnerCartelaNumbers);
  Map<int, GameCartelaModel> get winnerCards => Map.unmodifiable(_winnerCards);

  void recordWinnerCartela(int number, [GameCartelaModel? card]) {
    if (!_winnerCartelaNumbers.contains(number)) {
      _winnerCartelaNumbers.add(number);
    }
    if (card != null) {
      _winnerCards[number] = card;
    }
  }

  Duration calculateAutoDismissDuration(
    DateTime? winnerWindowEndsAt, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (winnerWindowEndsAt != null && winnerWindowEndsAt.isAfter(current)) {
      final remaining = winnerWindowEndsAt.difference(current);
      return remaining + const Duration(seconds: 4);
    }
    return const Duration(seconds: 8);
  }

  void startAllRoundsHistoryLoading(String cacheKey) {
    allRoundsWinnerHistoryLoading = true;
    allRoundsWinnerHistoryError = null;
    allRoundsWinnerHistoryKey = cacheKey;
  }

  void setAllRoundsHistory(
    RoundWinnerHistory? history,
    List<AllRoundsWinnerCardData> cards, {
    required String key,
  }) {
    if (allRoundsWinnerHistoryKey != key) return;
    allRoundsWinnerHistory = history;
    allRoundsWinnerCards = cards;
    allRoundsWinnerHistoryLoading = false;
    allRoundsWinnerHistoryError = null;
  }

  void setAllRoundsHistoryError(String error, {required String key}) {
    if (allRoundsWinnerHistoryKey != key) return;
    allRoundsWinnerHistoryLoading = false;
    allRoundsWinnerHistoryError = error;
  }

  void resetAllRoundsHistory() {
    allRoundsWinnerHistory = null;
    allRoundsWinnerCards = const [];
    allRoundsWinnerHistoryLoading = false;
    allRoundsWinnerHistoryError = null;
    allRoundsWinnerHistoryKey = null;
  }

  void reset() {
    _winnerCartelaNumbers.clear();
    _winnerCards.clear();
    isDialogOpen = false;
    resetAllRoundsHistory();
  }

  void dispose() {
    reset();
  }
}
