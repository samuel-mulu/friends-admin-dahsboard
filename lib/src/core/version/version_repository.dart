import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'android_app_version_model.dart';

class VersionRepository {
  VersionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AndroidAppVersionModel> fetchAndroidVersion() {
    return _apiClient.get(
      '/app-version/android',
      decoder: (rawData) {
        if (rawData is! Map<String, dynamic>) {
          throw const FormatException('Unexpected app version payload.');
        }
        return AndroidAppVersionModel.fromJson(rawData);
      },
    );
  }
}

final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  return VersionRepository(ref.watch(apiClientProvider));
});
