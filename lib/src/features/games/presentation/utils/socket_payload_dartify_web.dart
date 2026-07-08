import 'dart:js_util' as js_util;

/// Converts JS socket objects (e.g. LegacyJavaScriptObject) to Dart values on web.
Object? dartifySocketPayload(Object? payload) {
  if (payload == null) {
    return null;
  }

  try {
    final dartified = js_util.dartify(payload);
    if (dartified != null && !identical(dartified, payload)) {
      return dartified;
    }
  } catch (_) {
    // Fall through to manual key walk.
  }

  try {
    final keys = js_util.objectKeys(payload);
    if (keys.isEmpty) {
      return payload;
    }

    final map = <String, dynamic>{};
    for (final key in keys) {
      final keyStr = key.toString();
      final value = js_util.getProperty<dynamic>(payload, keyStr);
      map[keyStr] = js_util.dartify(value);
    }
    return map;
  } catch (_) {
    return payload;
  }
}
