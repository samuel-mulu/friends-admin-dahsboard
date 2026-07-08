import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';

void main() {
  test('ApiException extracts backend error code from the response envelope', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/deposits'),
      response: Response(
        requestOptions: RequestOptions(path: '/deposits'),
        statusCode: 409,
        data: {
          'success': false,
          'error': {
            'statusCode': 409,
            'code': 'ALREADY_USED',
            'message': 'This receipt has already been used.',
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final apiException = ApiException.fromDioException(exception);

    expect(apiException.code, 'ALREADY_USED');
    expect(apiException.message, 'This receipt has already been used.');
    expect(apiException.statusCode, 409);
  });

  test('ApiException.fromCaughtError normalizes non-Dio web errors', () {
    final apiException = ApiException.fromCaughtError(
      StateError('web transport failure'),
    );

    expect(apiException.message, 'Something went wrong.');
    expect(apiException.statusCode, isNull);
  });
}
