import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
    this.reason,
  });

  static const rateLimitMessage =
      'Too many attempts. Please wait a moment.';
  static const userBlockedCode = 'USER_BLOCKED';

  final String message;
  final int? statusCode;
  final String? code;
  final Object? details;
  final String? reason;

  factory ApiException.fromCaughtError(Object error) {
    if (error is ApiException) {
      return error;
    }
    if (error is DioException) {
      return ApiException.fromDioException(error);
    }
    return ApiException(message: 'Something went wrong.');
  }

  factory ApiException.fromDioException(DioException exception) {
    final responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'];

      if (error is Map<String, dynamic>) {
        return ApiException(
          message: _extractMessage(error['message']),
          statusCode:
              error['statusCode'] as int? ?? exception.response?.statusCode,
          code: error['code'] as String?,
          details: error['details'],
          reason: _extractReason(error),
        );
      }
    }

    if (exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'Could not reach the server. Please try again.',
      );
    }

    return ApiException(
      message: exception.response?.statusMessage ?? 'Something went wrong.',
      statusCode: exception.response?.statusCode,
    );
  }

  static String _extractMessage(Object? rawMessage) {
    if (rawMessage is List) {
      return rawMessage.whereType<String>().join(', ');
    }

    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage;
    }

    return 'Something went wrong.';
  }

  static String? _extractReason(Map<String, dynamic> error) {
    final topLevel = error['reason'];
    if (topLevel is String && topLevel.trim().isNotEmpty) {
      return topLevel.trim();
    }

    final details = error['details'];
    if (details is Map) {
      final nested = details['reason'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }

    return null;
  }

  bool get isConnectivityFailure =>
      statusCode == null &&
      message == 'Could not reach the server. Please try again.';

  bool get isRateLimited => statusCode == 429;

  bool get isUserBlocked =>
      code == userBlockedCode ||
      (statusCode == 403 &&
          message.toLowerCase().contains('account is blocked'));

  String get displayMessage =>
      isRateLimited ? rateLimitMessage : message;

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, code: $code, message: $message)';
  }
}
