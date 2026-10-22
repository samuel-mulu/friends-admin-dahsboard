import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences_storage.dart';

final profileAvatarProvider = FutureProvider.family<String?, String>((
  ref,
  userId,
) async {
  final storage = await ref.read(appPreferencesStorageProvider.future);
  return storage.readProfileAvatarId(userId);
});

class ProfileAvatarController {
  const ProfileAvatarController(this.ref, this.userId);

  final Ref ref;
  final String userId;

  Future<void> setAvatar(String? avatarId) async {
    final storage = await ref.read(appPreferencesStorageProvider.future);
    if (avatarId == null || avatarId.isEmpty) {
      await storage.clearProfileAvatarId(userId);
    } else {
      await storage.writeProfileAvatarId(userId, avatarId);
    }

    ref.invalidate(profileAvatarProvider(userId));
  }
}

final profileAvatarControllerProvider =
    Provider.family<ProfileAvatarController, String>((ref, userId) {
      return ProfileAvatarController(ref, userId);
    });
