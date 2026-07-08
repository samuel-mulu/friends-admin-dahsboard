enum AdminBroadcastCategory {
  dismissible,
  persistent,
  forced,
}

extension AdminBroadcastCategoryX on AdminBroadcastCategory {
  static AdminBroadcastCategory fromApi(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PERSISTENT':
        return AdminBroadcastCategory.persistent;
      case 'FORCED':
        return AdminBroadcastCategory.forced;
      case 'DISMISSIBLE':
      default:
        return AdminBroadcastCategory.dismissible;
    }
  }

  String get apiValue {
    switch (this) {
      case AdminBroadcastCategory.persistent:
        return 'PERSISTENT';
      case AdminBroadcastCategory.forced:
        return 'FORCED';
      case AdminBroadcastCategory.dismissible:
        return 'DISMISSIBLE';
    }
  }

  bool get canDismiss => this == AdminBroadcastCategory.dismissible;

  bool get isForced => this == AdminBroadcastCategory.forced;
}

class AdminBroadcastModel {
  const AdminBroadcastModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.category = AdminBroadcastCategory.dismissible,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final AdminBroadcastCategory category;

  bool get canDismiss => category.canDismiss;

  bool get isForced => category.isForced;

  factory AdminBroadcastModel.fromJson(Map<String, dynamic> json) {
    return AdminBroadcastModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: AdminBroadcastCategoryX.fromApi(json['category'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'category': category.apiValue,
    };
  }
}

class PlayerBroadcastsState {
  const PlayerBroadcastsState({
    this.inboxBroadcasts = const [],
    this.forcedBroadcast,
    this.unreadCount = 0,
  });

  final List<AdminBroadcastModel> inboxBroadcasts;
  final AdminBroadcastModel? forcedBroadcast;
  final int unreadCount;

  int get pinnedCount => inboxBroadcasts
      .where((item) => item.category == AdminBroadcastCategory.persistent)
      .length;

  factory PlayerBroadcastsState.fromResponse(PlayerBroadcastsResponse response) {
    return PlayerBroadcastsState.normalize(
      inboxBroadcasts: response.broadcasts,
      forcedBroadcast: response.forcedBroadcast,
      unreadCount: response.unreadCount,
    );
  }

  factory PlayerBroadcastsState.normalize({
    required List<AdminBroadcastModel> inboxBroadcasts,
    AdminBroadcastModel? forcedBroadcast,
    int? unreadCount,
  }) {
    final misplacedForced = inboxBroadcasts.where((item) => item.isForced).toList();
    final resolvedForced = forcedBroadcast ?? (misplacedForced.isNotEmpty
        ? misplacedForced.first
        : null);
    final resolvedInbox = inboxBroadcasts
        .where((item) => !item.isForced)
        .toList(growable: false);
    final resolvedUnread = unreadCount ??
        resolvedInbox
            .where((item) => item.category == AdminBroadcastCategory.dismissible)
            .length;

    return PlayerBroadcastsState(
      inboxBroadcasts: resolvedInbox,
      forcedBroadcast: resolvedForced,
      unreadCount: resolvedUnread,
    );
  }
}

class PlayerBroadcastsResponse {
  const PlayerBroadcastsResponse({
    required this.broadcasts,
    required this.unreadCount,
    this.forcedBroadcast,
  });

  final List<AdminBroadcastModel> broadcasts;
  final int unreadCount;
  final AdminBroadcastModel? forcedBroadcast;

  factory PlayerBroadcastsResponse.fromJson(Map<String, dynamic> json) {
    final rawBroadcasts = json['broadcasts'];
    final items = rawBroadcasts is List
        ? rawBroadcasts
              .whereType<Map>()
              .map(
                (item) => AdminBroadcastModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <AdminBroadcastModel>[];

    final rawForced = json['forcedBroadcast'];
    final forcedBroadcast = rawForced is Map
        ? AdminBroadcastModel.fromJson(Map<String, dynamic>.from(rawForced))
        : null;

    return PlayerBroadcastsResponse(
      broadcasts: items,
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount'] as int
          : items
                .where((item) => item.category == AdminBroadcastCategory.dismissible)
                .length,
      forcedBroadcast: forcedBroadcast,
    );
  }
}
