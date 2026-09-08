class AuthSessionDeviceMeta {
  const AuthSessionDeviceMeta({
    required this.platform,
    this.deviceLabel,
    this.userAgent,
  });

  final String platform;
  final String? deviceLabel;
  final String? userAgent;

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      if (deviceLabel != null && deviceLabel!.isNotEmpty)
        'deviceLabel': deviceLabel,
      if (userAgent != null && userAgent!.isNotEmpty) 'userAgent': userAgent,
    };
  }
}

class AuthDeviceSession {
  AuthDeviceSession({
    required this.id,
    required this.isCurrent,
    this.deviceId,
    this.platform,
    this.deviceLabel,
    this.userAgent,
    this.lastUsedAt,
    this.createdAt,
  });

  final String id;
  final bool isCurrent;
  final String? deviceId;
  final String? platform;
  final String? deviceLabel;
  final String? userAgent;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  factory AuthDeviceSession.fromJson(Map<String, dynamic> json) {
    return AuthDeviceSession(
      id: json['id'] as String,
      isCurrent: json['isCurrent'] == true,
      deviceId: json['deviceId'] as String?,
      platform: json['platform'] as String?,
      deviceLabel: json['deviceLabel'] as String?,
      userAgent: json['userAgent'] as String?,
      lastUsedAt: json['lastUsedAt'] is String
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  String get displayLabel {
    if (deviceLabel != null && deviceLabel!.trim().isNotEmpty) {
      return deviceLabel!.trim();
    }
    if (platform != null && platform!.trim().isNotEmpty) {
      return platform!.trim();
    }
    return 'Unknown device';
  }
}
