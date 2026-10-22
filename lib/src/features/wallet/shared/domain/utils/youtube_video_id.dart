/// Extracts an 11-character YouTube video id from a full URL or raw id.
String? youtubeVideoIdFromUrl(String? input) {
  final trimmed = input?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  if (RegExp(r'^[\w-]{11}$').hasMatch(trimmed)) {
    return trimmed;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return null;
  }

  if (uri.host.contains('youtu.be')) {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return _validId(id);
  }

  final v = uri.queryParameters['v'];
  if (v != null) {
    return _validId(v);
  }

  final segments = uri.pathSegments;
  for (var i = 0; i < segments.length - 1; i++) {
    if (segments[i] == 'embed' ||
        segments[i] == 'shorts' ||
        segments[i] == 'live') {
      return _validId(segments[i + 1]);
    }
  }

  return null;
}

String? _validId(String value) {
  final id = value.trim();
  return RegExp(r'^[\w-]{11}$').hasMatch(id) ? id : null;
}
