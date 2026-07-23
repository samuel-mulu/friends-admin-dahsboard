import 'user_profile.dart';

class AuthSession {
  AuthSession({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.welcomeBonusCartelasAwarded = 0,
    this.welcomeBonusDeniedReason,
  });

  final String accessToken;
  final String? refreshToken;
  final UserProfile user;
  final int welcomeBonusCartelasAwarded;
  final String? welcomeBonusDeniedReason;

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.trim().isNotEmpty;

  bool get shouldShowWelcomeBonusDenied {
    final reason = welcomeBonusDeniedReason;
    return welcomeBonusCartelasAwarded <= 0 &&
        (reason == 'DEVICE_ALREADY_CLAIMED' || reason == 'USER_ALREADY_CLAIMED');
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final refreshToken = json['refreshToken'];
    final deniedReason = json['welcomeBonusDeniedReason'];
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: refreshToken is String && refreshToken.trim().isNotEmpty
          ? refreshToken
          : null,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      welcomeBonusCartelasAwarded:
          json['welcomeBonusCartelasAwarded'] as int? ?? 0,
      welcomeBonusDeniedReason: deniedReason is String && deniedReason.isNotEmpty
          ? deniedReason
          : null,
    );
  }

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    UserProfile? user,
    int? welcomeBonusCartelasAwarded,
    String? welcomeBonusDeniedReason,
    bool clearWelcomeBonusDeniedReason = false,
    bool preserveRefreshToken = true,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: preserveRefreshToken
          ? refreshToken ?? this.refreshToken
          : refreshToken,
      user: user ?? this.user,
      welcomeBonusCartelasAwarded:
          welcomeBonusCartelasAwarded ?? this.welcomeBonusCartelasAwarded,
      welcomeBonusDeniedReason: clearWelcomeBonusDeniedReason
          ? null
          : welcomeBonusDeniedReason ?? this.welcomeBonusDeniedReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      if (refreshToken != null && refreshToken!.trim().isNotEmpty)
        'refreshToken': refreshToken,
      'user': user.toJson(),
      'welcomeBonusCartelasAwarded': welcomeBonusCartelasAwarded,
      if (welcomeBonusDeniedReason != null)
        'welcomeBonusDeniedReason': welcomeBonusDeniedReason,
    };
  }
}
