import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerCartelasNotifier extends Notifier<Map<String, Set<int>>> {
  @override
  Map<String, Set<int>> build() => {};

  void toggleMark(String cartelaId, int number) {
    final current = Map<String, Set<int>>.from(state);
    final cartelaMarks = Set<int>.from(current[cartelaId] ?? const {});

    if (cartelaMarks.contains(number)) {
      cartelaMarks.remove(number);
    } else {
      cartelaMarks.add(number);
    }

    current[cartelaId] = cartelaMarks;
    state = current;
  }

  void setMarksForCartela(String cartelaId, Set<int> marks) {
    final current = Map<String, Set<int>>.from(state);
    current[cartelaId] = Set<int>.from(marks);
    state = current;
  }

  void clear() {
    state = {};
  }
}

final playerCartelasNotifierProvider =
    NotifierProvider<PlayerCartelasNotifier, Map<String, Set<int>>>(
  PlayerCartelasNotifier.new,
);
