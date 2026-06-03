class ApiEnvelope<T> {
  ApiEnvelope({
    required this.success,
    required this.data,
    this.meta,
    this.timestamp,
    this.path,
  });

  final bool success;
  final T data;
  final Map<String, dynamic>? meta;
  final DateTime? timestamp;
  final String? path;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw) decoder,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] == true,
      data: decoder(json['data']),
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null,
      timestamp: json['timestamp'] is String
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      path: json['path'] as String?,
    );
  }
}
