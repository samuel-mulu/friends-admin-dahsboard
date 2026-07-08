import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/theme_mode_provider.dart';
import '../../domain/cartela_mark_color.dart';

class CartelaMarkColorController extends Notifier<CartelaMarkColor> {
  @override
  CartelaMarkColor build() {
    final storageAsync = ref.watch(appPreferencesStorageProvider);
    return storageAsync.maybeWhen(
      data: (storage) => storage.readCartelaMarkColor(),
      orElse: () => CartelaMarkColor.green,
    );
  }

  Future<void> setColor(CartelaMarkColor color) async {
    state = color;
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writeCartelaMarkColor(color);
  }
}

final cartelaMarkColorProvider =
    NotifierProvider<CartelaMarkColorController, CartelaMarkColor>(
  CartelaMarkColorController.new,
);
