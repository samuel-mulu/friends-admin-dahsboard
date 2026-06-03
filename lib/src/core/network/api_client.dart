import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_token_storage.dart';
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
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ApiEnvelope<T>> postEnvelope<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(Object? rawData) decoder,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _decodeEnvelope(response.data, decoder);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
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
    required T Function(Object? rawData) decoder,
  }) async {
    final envelope = await postEnvelope<T>(
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

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(secureTokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
