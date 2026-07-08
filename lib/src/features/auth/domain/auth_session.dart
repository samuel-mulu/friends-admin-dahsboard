import 'user_profile.dart';

class AuthSession {
  AuthSession({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final UserProfile user;

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.trim().isNotEmpty;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final refreshToken = json['refreshToken'];
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: refreshToken is String && refreshToken.trim().isNotEmpty
          ? refreshToken
          : null,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    UserProfile? user,
    bool preserveRefreshToken = true,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: preserveRefreshToken
          ? refreshToken ?? this.refreshToken
          : refreshToken,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      if (refreshToken != null && refreshToken!.trim().isNotEmpty)
        'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}
