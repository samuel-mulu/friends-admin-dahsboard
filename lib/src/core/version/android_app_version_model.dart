class AndroidAppVersionModel {
  const AndroidAppVersionModel({
    required this.version,
    required this.versionCode,
    required this.minimumVersionCode,
    required this.downloadUrl,
    required this.sha256,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  final String version;
  final int versionCode;
  final int minimumVersionCode;
  final String downloadUrl;
  final String sha256;
  final String releaseNotes;
  final bool forceUpdate;

  factory AndroidAppVersionModel.fromJson(Map<String, dynamic> json) {
    return AndroidAppVersionModel(
      version: json['version'] as String? ?? '',
      versionCode: _requireInt(json['versionCode']),
      minimumVersionCode: _requireInt(json['minimumVersionCode']),
      downloadUrl: json['downloadUrl'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      forceUpdate: json['forceUpdate'] == true ||
          (json['forceUpdate'] is String &&
              (json['forceUpdate'] as String).toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'versionCode': versionCode,
      'minimumVersionCode': minimumVersionCode,
      'downloadUrl': downloadUrl,
      'sha256': sha256,
      'releaseNotes': releaseNotes,
      'forceUpdate': forceUpdate,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AndroidAppVersionModel &&
            version == other.version &&
            versionCode == other.versionCode &&
            minimumVersionCode == other.minimumVersionCode &&
            downloadUrl == other.downloadUrl &&
            sha256 == other.sha256 &&
            releaseNotes == other.releaseNotes &&
            forceUpdate == other.forceUpdate;
  }

  @override
  int get hashCode => Object.hash(
    version,
    versionCode,
    minimumVersionCode,
    downloadUrl,
    sha256,
    releaseNotes,
    forceUpdate,
  );

  static int _requireInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.parse(value);
    }
    throw FormatException('Expected integer, got $value');
  }
}
