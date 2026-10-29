import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/games_repository.dart';
import '../../data/models/app_display_config_model.dart';

final appDisplayConfigProvider =
    AsyncNotifierProvider<AppDisplayConfigNotifier, AppDisplayConfigModel>(
  AppDisplayConfigNotifier.new,
);

class AppDisplayConfigNotifier extends AsyncNotifier<AppDisplayConfigModel> {
  @override
  Future<AppDisplayConfigModel> build() async {
    try {
      return await ref.read(gamesRepositoryProvider).getDisplayConfig();
    } catch (_) {
      return AppDisplayConfigModel.fallback;
    }
  }

  Future<void> refresh() async {
    try {
      state = AsyncData(
        await ref.read(gamesRepositoryProvider).getDisplayConfig(),
      );
    } catch (_) {
      state = const AsyncData(AppDisplayConfigModel.fallback);
    }
  }
}
