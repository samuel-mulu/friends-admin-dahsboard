import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/games_repository.dart';
import '../../data/models/house_champions_model.dart';

class HouseChampionsPeriodController extends Notifier<HouseChampionsPeriod> {
  @override
  HouseChampionsPeriod build() => HouseChampionsPeriod.week;

  void setPeriod(HouseChampionsPeriod period) {
    state = period;
  }
}

final houseChampionsPeriodProvider =
    NotifierProvider<HouseChampionsPeriodController, HouseChampionsPeriod>(
      HouseChampionsPeriodController.new,
    );

final houseChampionsProvider =
    FutureProvider.autoDispose<HouseChampionsResponse>((ref) async {
      final period = ref.watch(houseChampionsPeriodProvider);
      return ref
          .read(gamesRepositoryProvider)
          .getCartelaWinsLeaderboard(period: period.apiValue);
    });
