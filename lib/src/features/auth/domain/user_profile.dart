import '../../wallet/data/models/wallet_model.dart';

enum UserRole {
  admin,
  player;

  factory UserRole.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'PLAYER':
        return UserRole.player;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported user role');
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.player:
        return 'Player';
    }
  }
}

enum UserStatus {
  active,
  blocked;

  factory UserStatus.fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'BLOCKED':
        return UserStatus.blocked;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported user status');
    }
  }

  String get label {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.blocked:
        return 'Blocked';
    }
  }
}

/// Server-synced preference for game push targeting.
enum GamePushMode {
  always,
  registeredOnly,
  off;

  factory GamePushMode.fromApi(String? value) {
    switch ((value ?? 'ALWAYS').toUpperCase()) {
      case 'REGISTERED_ONLY':
        return GamePushMode.registeredOnly;
      case 'OFF':
        return GamePushMode.off;
      case 'ALWAYS':
      default:
        return GamePushMode.always;
    }
  }

  String get apiValue {
    switch (this) {
      case GamePushMode.always:
        return 'ALWAYS';
      case GamePushMode.registeredOnly:
        return 'REGISTERED_ONLY';
      case GamePushMode.off:
        return 'OFF';
    }
  }

  String get label {
    switch (this) {
      case GamePushMode.always:
        return 'All game alerts';
      case GamePushMode.registeredOnly:
        return "Only when I'm playing";
      case GamePushMode.off:
        return 'Off';
    }
  }

  String get description {
    switch (this) {
      case GamePushMode.always:
        return 'Include registration open and big-game reminders.';
      case GamePushMode.registeredOnly:
        return 'Only alerts for games where you have a cartela.';
      case GamePushMode.off:
        return 'No game push notifications.';
    }
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.wallet,
    this.hasPassword = true,
    this.telegramLinked = false,
    this.telegramUsername,
    this.gamePushMode = GamePushMode.always,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WalletModel? wallet;
  final bool hasPassword;
  final bool telegramLinked;
  final String? telegramUsername;
  final GamePushMode gamePushMode;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: UserRole.fromApi(json['role'] as String),
      status: UserStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      wallet: json['wallet'] is Map<String, dynamic>
          ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
      hasPassword: json['hasPassword'] is bool
          ? json['hasPassword'] as bool
          : true,
      telegramLinked: json['telegramLinked'] is bool
          ? json['telegramLinked'] as bool
          : json['telegramId'] != null,
      telegramUsername: json['telegramUsername'] as String?,
      gamePushMode: GamePushMode.fromApi(json['gamePushMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hasPassword': hasPassword,
      'telegramLinked': telegramLinked,
      'gamePushMode': gamePushMode.apiValue,
      if (telegramUsername != null) 'telegramUsername': telegramUsername,
      if (wallet != null) 'wallet': wallet!.toJson(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    bool? hasPassword,
    bool? telegramLinked,
    String? telegramUsername,
    WalletModel? wallet,
    GamePushMode? gamePushMode,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber,
      role: role,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      wallet: wallet ?? this.wallet,
      hasPassword: hasPassword ?? this.hasPassword,
      telegramLinked: telegramLinked ?? this.telegramLinked,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      gamePushMode: gamePushMode ?? this.gamePushMode,
    );
  }
}
