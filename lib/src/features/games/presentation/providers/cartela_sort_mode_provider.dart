import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences_storage.dart';
import '../../../settings/presentation/providers/theme_mode_provider.dart';
import '../utils/cartela_marked_pattern_evaluator.dart';

class CartelaSortModeController extends Notifier<CartelaSortMode> {
  @override
  CartelaSortMode build() {
    final storageAsync = ref.watch(appPreferencesStorageProvider);
    return storageAsync.maybeWhen(
      data: (storage) => storage.readCartelaSortMode(),
      orElse: () => CartelaSortMode.manual,
    );
  }

  Future<void> setSortMode(CartelaSortMode mode) async {
    state = mode;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writeCartelaSortMode(mode);
  }

  Future<void> setRemainsSortEnabled(bool enabled) async {
    if (enabled) {
      await setSortMode(CartelaSortMode.smart);
      return;
    }
    if (state == CartelaSortMode.smart) {
      await setSortMode(CartelaSortMode.manual);
    }
  }
}

class CartelaSortMaxRemainsController extends Notifier<int> {
  @override
  int build() {
    final storageAsync = ref.watch(appPreferencesStorageProvider);
    return storageAsync.maybeWhen(
      data: (storage) => storage.readCartelaSortMaxRemains(),
      orElse: () => AppPreferencesStorage.defaultCartelaSortMaxRemains,
    );
  }

  Future<void> setMaxRemains(int maxRemains) async {
    final next = maxRemains.clamp(1, 4);
    state = next;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writeCartelaSortMaxRemains(next);
  }
}

final cartelaSortModeProvider =
    NotifierProvider<CartelaSortModeController, CartelaSortMode>(
      CartelaSortModeController.new,
    );

final cartelaSortMaxRemainsProvider =
    NotifierProvider<CartelaSortMaxRemainsController, int>(
      CartelaSortMaxRemainsController.new,
    );
