class FeatureSettings {
  const FeatureSettings({
    this.autoMarkGranted = false,
    this.autoBingoGranted = false,
    this.autoMarkEnabled = false,
    this.autoBingoEnabled = false,
    this.effectiveAutoMark = false,
    this.effectiveAutoBingo = false,
    this.featureSettingsVersion = 0,
    this.updatedAt,
  });

  final bool autoMarkGranted;
  final bool autoBingoGranted;
  final bool autoMarkEnabled;
  final bool autoBingoEnabled;
  final bool effectiveAutoMark;
  final bool effectiveAutoBingo;
  final int featureSettingsVersion;
  final DateTime? updatedAt;

  bool get hasAnyGrant => autoMarkGranted || autoBingoGranted;

  factory FeatureSettings.fromJson(Map<String, dynamic> json) {
    return FeatureSettings(
      autoMarkGranted: json['autoMarkGranted'] == true,
      autoBingoGranted: json['autoBingoGranted'] == true,
      autoMarkEnabled: json['autoMarkEnabled'] == true,
      autoBingoEnabled: json['autoBingoEnabled'] == true,
      effectiveAutoMark: json['effectiveAutoMark'] == true,
      effectiveAutoBingo: json['effectiveAutoBingo'] == true,
      featureSettingsVersion: _readVersion(json['featureSettingsVersion']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  FeatureSettings copyWith({
    bool? autoMarkGranted,
    bool? autoBingoGranted,
    bool? autoMarkEnabled,
    bool? autoBingoEnabled,
    bool? effectiveAutoMark,
    bool? effectiveAutoBingo,
    int? featureSettingsVersion,
    DateTime? updatedAt,
  }) {
    return FeatureSettings(
      autoMarkGranted: autoMarkGranted ?? this.autoMarkGranted,
      autoBingoGranted: autoBingoGranted ?? this.autoBingoGranted,
      autoMarkEnabled: autoMarkEnabled ?? this.autoMarkEnabled,
      autoBingoEnabled: autoBingoEnabled ?? this.autoBingoEnabled,
      effectiveAutoMark: effectiveAutoMark ?? this.effectiveAutoMark,
      effectiveAutoBingo: effectiveAutoBingo ?? this.effectiveAutoBingo,
      featureSettingsVersion:
          featureSettingsVersion ?? this.featureSettingsVersion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns [incoming] only when its version is strictly newer.
  static FeatureSettings? takeIfNewer({
    required FeatureSettings current,
    required FeatureSettings incoming,
  }) {
    if (incoming.featureSettingsVersion < current.featureSettingsVersion) {
      return null;
    }
    if (incoming.featureSettingsVersion > current.featureSettingsVersion) {
      return incoming;
    }
    // Same version: accept equal snapshot (idempotent), ignore only if identical.
    return incoming;
  }

  static int _readVersion(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return 0;
  }

  static DateTime? _readDateTime(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

class FeatureSettingsUiState {
  const FeatureSettingsUiState({
    this.settings = const FeatureSettings(),
    this.autoMarkPending = false,
    this.autoBingoPending = false,
  });

  final FeatureSettings settings;
  final bool autoMarkPending;
  final bool autoBingoPending;

  bool get showAutoMark => settings.autoMarkGranted;
  bool get showAutoBingo => settings.autoBingoGranted;

  FeatureSettingsUiState copyWith({
    FeatureSettings? settings,
    bool? autoMarkPending,
    bool? autoBingoPending,
  }) {
    return FeatureSettingsUiState(
      settings: settings ?? this.settings,
      autoMarkPending: autoMarkPending ?? this.autoMarkPending,
      autoBingoPending: autoBingoPending ?? this.autoBingoPending,
    );
  }
}
