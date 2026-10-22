import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/feature_settings.dart';

class FeatureSettingsRepository {
  FeatureSettingsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<FeatureSettings> getFeatureSettings() {
    return _apiClient.get<FeatureSettings>(
      '/users/me/feature-settings',
      decoder: _decode,
    );
  }

  Future<FeatureSettings> updateFeatureSettings({
    bool? autoMarkEnabled,
    bool? autoBingoEnabled,
  }) {
    final data = <String, dynamic>{
      'autoMarkEnabled': ?autoMarkEnabled,
      'autoBingoEnabled': ?autoBingoEnabled,
    };

    return _apiClient.patch<FeatureSettings>(
      '/users/me/feature-settings',
      data: data,
      decoder: _decode,
    );
  }

  static FeatureSettings _decode(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw StateError('Invalid feature settings response.');
    }
    return FeatureSettings.fromJson(raw);
  }
}

final featureSettingsRepositoryProvider = Provider<FeatureSettingsRepository>((
  ref,
) {
  return FeatureSettingsRepository(ref.watch(apiClientProvider));
});
