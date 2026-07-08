import '../../../../core/network/api_exception.dart';
import '../debug/live_realtime_debug.dart';

/// Logs structured context for live-screen API failures (including Dio 400).
void logLiveApiFailure(
  Object error, {
  required String method,
  required String endpoint,
  String? sessionId,
  Object? requestPayload,
}) {
  if (error is! ApiException) {
    LiveRealtimeDebug.apiFailure(
      method: method,
      endpoint: endpoint,
      sessionId: sessionId,
      statusCode: null,
      message: error.toString(),
      responseBody: null,
      requestPayload: requestPayload,
    );
    return;
  }

  LiveRealtimeDebug.apiFailure(
    method: method,
    endpoint: endpoint,
    sessionId: sessionId,
    statusCode: error.statusCode,
    message: error.message,
    responseBody: error.details ?? error.message,
    requestPayload: requestPayload,
  );
}
