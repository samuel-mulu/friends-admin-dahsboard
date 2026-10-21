import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/called_number_model.dart';

class CalledBallsNotifier extends Notifier<List<CalledNumberModel>> {
  @override
  List<CalledNumberModel> build() => [];

  void setInitialBalls(List<CalledNumberModel> balls) {
    final sorted = List<CalledNumberModel>.from(balls)
      ..sort((a, b) => a.order.compareTo(b.order));
    state = sorted;
  }

  void addBall(CalledNumberModel ball) {
    if (state.any((b) => b.order == ball.order || b.number == ball.number)) {
      return;
    }
    state = [...state, ball];
  }

  void clear() {
    state = [];
  }
}

final calledBallsNotifierProvider =
    NotifierProvider<CalledBallsNotifier, List<CalledNumberModel>>(
  CalledBallsNotifier.new,
);
