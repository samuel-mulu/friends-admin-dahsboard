import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  factory ApiException.fromDioException(DioException exception) {
    final responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'];

      if (error is Map<String, dynamic>) {
        return ApiException(
          message: _extractMessage(error['message']),
          statusCode:
              error['statusCode'] as int? ?? exception.response?.statusCode,
          details: error['details'],
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

  bool get isConnectivityFailure =>
      statusCode == null &&
      message == 'Could not reach the server. Please try again.';

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message)';
  }
}
