import 'dart:js_interop';

/// Converts JS socket objects to Dart values on web using modern dart:js_interop.
Object? dartifySocketPayload(Object? payload) {
  if (payload == null) {
    return null;
  }

  if (payload.isA<JSAny>()) {
    try {
      final dartified = (payload as JSAny).dartify();
      if (dartified != null && !identical(dartified, payload)) {
        return dartified;
      }
    } catch (_) {
      return payload;
    }
  }

  return payload;
}
