import 'dart:convert';

import 'socket_payload_dartify_stub.dart'
    if (dart.library.js_interop) 'socket_payload_dartify_web.dart'
    as socket_dartify;

const _maxNormalizeDepth = 4;

Map<String, dynamic>? normalizeSocketPayload(dynamic payload) {
  return _normalizeSocketPayloadValue(payload, depth: 0);
}

Map<String, dynamic>? _normalizeSocketPayloadValue(
  dynamic payload, {
  required int depth,
}) {
  if (payload == null || depth > _maxNormalizeDepth) {
    return null;
  }

  if (payload is Map<String, dynamic>) {
    return payload;
  }

  if (payload is Map) {
    return Map<String, dynamic>.from(payload);
  }

  if (payload is List && payload.isNotEmpty) {
    return _normalizeSocketPayloadValue(payload.first, depth: depth + 1);
  }

  final fromJsonEncode = _normalizeFromJsonRoundTrip(payload);
  if (fromJsonEncode != null) {
    return fromJsonEncode;
  }

  final dartified = socket_dartify.dartifySocketPayload(payload);
  if (!identical(dartified, payload)) {
    return _normalizeSocketPayloadValue(dartified, depth: depth + 1);
  }

  return null;
}

Map<String, dynamic>? _normalizeFromJsonRoundTrip(dynamic payload) {
  try {
    final encoded = jsonEncode(payload);
    final decoded = jsonDecode(encoded);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
  } catch (_) {
    return null;
  }

  return null;
}

String? readSocketEntityId(Map<String, dynamic>? payload) {
  if (payload == null) {
    return null;
  }

  for (final key in const ['id', 'broadcastId']) {
    final value = payload[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }

  return null;
}

Map<String, dynamic>? normalizeSocketPayloadOrHandleInvalid(
  dynamic payload, {
  String? eventName,
  void Function(String message)? debugLog,
  void Function()? onInvalid,
}) {
  final normalized = normalizeSocketPayload(payload);
  if (normalized != null) {
    return normalized;
  }

  debugLog?.call(
    'Invalid socket payload'
    '${eventName == null ? '' : ' for $eventName'}: '
    '${payload.runtimeType}',
  );
  onInvalid?.call();
  return null;
}
