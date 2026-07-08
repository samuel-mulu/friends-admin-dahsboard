import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final cartelaSortModeProvider =
    NotifierProvider<CartelaSortModeController, CartelaSortMode>(
      CartelaSortModeController.new,
    );
