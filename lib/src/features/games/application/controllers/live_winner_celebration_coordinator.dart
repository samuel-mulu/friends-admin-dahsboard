import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import '../../data/models/round_winner_history_model.dart';
import '../../presentation/utils/round_winner_history_adapters.dart';

/// Coordinates winner cartela tracking, dialog auto-dismiss scheduling,
/// and All-Rounds Winner history caching for Big Game and Chain Game.
class LiveWinnerCelebrationCoordinator {
  final List<int> _winnerCartelaNumbers = [];
  final Map<int, GameCartelaModel> _winnerCards = {};
  bool isDialogOpen = false;

  // All-Rounds Winner History state (Big Game + Chain only).
  RoundWinnerHistory? allRoundsWinnerHistory;
  List<AllRoundsWinnerCardData> allRoundsWinnerCards = const [];

  /// True while the section shows its loading state — either waiting for the
  /// server to confirm the game finished, or while the request is in flight.
  bool allRoundsWinnerHistoryLoading = false;
  bool allRoundsWinnerHistoryFailed = false;
  String? allRoundsWinnerHistoryKey;

  /// True only while a history HTTP request is running (dedupes triggers).
  bool allRoundsWinnerHistoryRequestInFlight = false;

  /// Session the SERVER has confirmed finished (via `game:finished` or a
  /// FINISHED / NO_WINNER snapshot). The local winner window can end a few
  /// seconds before the server finalizes it. Keyed by session — not by history
  /// cache key — because every Big Game round shares one slot key.
  String? _serverConfirmedFinishedSessionId;

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

  bool isServerConfirmedFinished(String? sessionId) =>
      sessionId != null && _serverConfirmedFinishedSessionId == sessionId;

  void markServerConfirmedFinished(String sessionId) {
    _serverConfirmedFinishedSessionId = sessionId;
  }

  void startAllRoundsHistoryLoading(String cacheKey) {
    allRoundsWinnerHistoryLoading = true;
    allRoundsWinnerHistoryFailed = false;
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
    allRoundsWinnerHistoryFailed = false;
  }

  void setAllRoundsHistoryFailed({required String key}) {
    if (allRoundsWinnerHistoryKey != key) return;
    allRoundsWinnerHistoryLoading = false;
    allRoundsWinnerHistoryFailed = true;
  }

  void resetAllRoundsHistory() {
    allRoundsWinnerHistory = null;
    allRoundsWinnerCards = const [];
    allRoundsWinnerHistoryLoading = false;
    allRoundsWinnerHistoryFailed = false;
    allRoundsWinnerHistoryKey = null;
    allRoundsWinnerHistoryRequestInFlight = false;
    _serverConfirmedFinishedSessionId = null;
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
