enum SupportCategory {
  feedback('FEEDBACK'),
  complaint('COMPLAINT'),
  advice('ADVICE'),
  other('OTHER');

  const SupportCategory(this.apiValue);

  final String apiValue;

  static SupportCategory fromApi(String value) {
    return SupportCategory.values.firstWhere(
      (category) => category.apiValue == value,
      orElse: () => SupportCategory.other,
    );
  }
}

enum SupportStatus {
  open('OPEN'),
  replied('REPLIED'),
  closed('CLOSED');

  const SupportStatus(this.apiValue);

  final String apiValue;

  static SupportStatus fromApi(String value) {
    return SupportStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => SupportStatus.open,
    );
  }
}

class SupportMessageModel {
  SupportMessageModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.message,
    required this.status,
    required this.adminReply,
    required this.repliedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final SupportCategory category;
  final String message;
  final SupportStatus status;
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAdminReply =>
      adminReply != null && adminReply!.trim().isNotEmpty;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: SupportCategory.fromApi(json['category'] as String),
      message: json['message'] as String,
      status: SupportStatus.fromApi(json['status'] as String),
      adminReply: json['adminReply'] as String?,
      repliedAt: json['repliedAt'] == null
          ? null
          : DateTime.parse(json['repliedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// API returns newest first; chat UI shows oldest at top, newest at bottom.
List<SupportMessageModel> chronologicalSupportMessages(
  List<SupportMessageModel> items,
) {
  return items.reversed.toList(growable: false);
}
