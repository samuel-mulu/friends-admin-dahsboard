import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_support.dart';
import '../../../games/data/games_repository.dart';

final appSupportConfigProvider =
    AsyncNotifierProvider<AppSupportConfigNotifier, AppSupportConfig>(
  AppSupportConfigNotifier.new,
);

class AppSupportConfigNotifier extends AsyncNotifier<AppSupportConfig> {
  @override
  Future<AppSupportConfig> build() async {
    try {
      return await ref.read(gamesRepositoryProvider).getSupportConfig();
    } catch (_) {
      return AppSupportConfig.fallback;
    }
  }

  Future<void> refresh() async {
    try {
      state = AsyncData(
        await ref.read(gamesRepositoryProvider).getSupportConfig(),
      );
    } catch (_) {
      state = const AsyncData(AppSupportConfig.fallback);
    }
  }
}
