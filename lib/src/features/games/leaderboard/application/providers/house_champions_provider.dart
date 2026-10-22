import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/house_champions_model.dart';
import '../../data/repositories/leaderboard_repository.dart';

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
          .read(leaderboardRepositoryProvider)
          .getCartelaWinsLeaderboard(period: period.apiValue);
    });
