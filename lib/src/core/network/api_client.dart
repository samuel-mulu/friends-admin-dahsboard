import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';
import '../../features/auth/session/session_manager.dart';
import 'api_envelope.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiEnvelope<T>> getEnvelope<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? rawData) decoder,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );

      return _decodeEnvelope(response.data, decoder);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ApiException.fromCaughtError(error), stackTrace);
    }
  }

  Future<ApiEnvelope<T>> postEnvelope<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Duration? receiveTimeout,
    required T Function(Object? rawData) decoder,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: receiveTimeout == null
            ? null
            : Options(receiveTimeout: receiveTimeout),
      );

      return _decodeEnvelope(response.data, decoder);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ApiException.fromCaughtError(error), stackTrace);
    }
  }

  Future<ApiEnvelope<T>> deleteEnvelope<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? rawData) decoder,
  }) async {
    try {
      final response = await _dio.delete<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _decodeEnvelope(response.data, decoder);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(ApiException.fromCaughtError(error), stackTrace);
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? rawData) decoder,
  }) async {
    final envelope = await getEnvelope<T>(
      path,
      queryParameters: queryParameters,
      decoder: decoder,
    );

    return envelope.data;
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Duration? receiveTimeout,
    required T Function(Object? rawData) decoder,
  }) async {
    final envelope = await postEnvelope<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      receiveTimeout: receiveTimeout,
      decoder: decoder,
    );

    return envelope.data;
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? rawData) decoder,
  }) async {
    final envelope = await deleteEnvelope<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
    );

    return envelope.data;
  }

  ApiEnvelope<T> _decodeEnvelope<T>(
    Object? rawResponse,
    T Function(Object? rawData) decoder,
  ) {
    if (rawResponse is! Map<String, dynamic>) {
      throw ApiException(message: 'Unexpected server response.');
    }

    final envelope = ApiEnvelope<T>.fromJson(rawResponse, decoder);

    if (!envelope.success) {
      throw ApiException(message: 'Request failed.');
    }

    return envelope;
  }
}

BaseOptions _baseOptions(AppConfig config) {
  return BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );
}

final rawDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(_baseOptions(config));
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  final sessionManager = ref.read(sessionManagerProvider.notifier);
  final dio = Dio(_baseOptions(ref.watch(appConfigProvider)));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await sessionManager.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final requestOptions = error.requestOptions;
        final isRefreshRequest = requestOptions.path.endsWith('/auth/refresh');
        final wasRetried = requestOptions.extra['didRefreshRetry'] == true;

        if (statusCode != 401 || isRefreshRequest || wasRetried) {
          handler.next(error);
          return;
        }

        final refreshSucceeded = await sessionManager.refreshSession();
        if (!refreshSucceeded) {
          handler.next(error);
          return;
        }

        final nextToken = await tokenStorage.readAccessToken();
        if (nextToken == null || nextToken.isEmpty) {
          handler.next(error);
          return;
        }

        requestOptions.headers['Authorization'] = 'Bearer $nextToken';
        requestOptions.extra['didRefreshRetry'] = true;

        try {
          final response = await dio.fetch<Object?>(requestOptions);
          handler.resolve(response);
        } catch (retryError, stackTrace) {
          if (retryError is DioException) {
            handler.next(retryError);
            return;
          }
          Error.throwWithStackTrace(retryError, stackTrace);
        }
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
