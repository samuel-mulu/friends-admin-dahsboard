import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences_storage.dart';
import '../../../settings/presentation/providers/theme_mode_provider.dart';

final gameAnnouncementDismissProvider =
    NotifierProvider<GameAnnouncementDismissNotifier, Set<String>>(
      GameAnnouncementDismissNotifier.new,
    );

class GameAnnouncementDismissNotifier extends Notifier<Set<String>> {
  static const _storagePrefix = 'game_announcement_dismissed_';

  @override
  Set<String> build() {
    final storageAsync = ref.watch(appPreferencesStorageProvider);
    return storageAsync.maybeWhen(
      data: (storage) => _readDismissed(storage),
      orElse: () => <String>{},
    );
  }

  Set<String> _readDismissed(AppPreferencesStorage storage) {
    final keys = storage.readDismissedGameAnnouncements();
    return keys.toSet();
  }

  Future<void> dismiss(String announcementId) async {
    if (state.contains(announcementId)) {
      return;
    }
    state = {...state, announcementId};
    final storage = await ref.read(appPreferencesStorageProvider.future);
    await storage.writeDismissedGameAnnouncements(state.toList(growable: false));
  }

  bool isDismissed(String announcementId) => state.contains(announcementId);

  static String storageKey(String announcementId) =>
      '$_storagePrefix$announcementId';
}
