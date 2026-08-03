const kDefaultCbeReceiptBaseUrl = 'https://mbreciept.cbe.com.et/receipt';

final RegExp _cbeReceiptReferencePattern = RegExp(r'^[A-Za-z0-9-]{6,120}$');

bool isReceiptUrlInput(String input) {
  final uri = Uri.tryParse(input.trim());
  return uri != null &&
      (uri.scheme.toLowerCase() == 'https' ||
          uri.scheme.toLowerCase() == 'http') &&
      uri.host.isNotEmpty;
}

/// Returns the canonical reference used for duplicate checks and persistence.
///
/// New CBE mobile receipt tokens are case-sensitive, while legacy FT
/// references are conventionally uppercase. Full URLs are accepted only when
/// they match the configured CBE receipt origin and base path.
String? normalizeCbeManualReceiptReference(
  String input, {
  String receiptBaseUrl = kDefaultCbeReceiptBaseUrl,
}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final reference = isReceiptUrlInput(trimmed)
      ? _extractReferenceFromOfficialUrl(trimmed, receiptBaseUrl)
      : trimmed;
  if (reference == null || !_cbeReceiptReferencePattern.hasMatch(reference)) {
    return null;
  }

  return reference.toUpperCase().startsWith('FT')
      ? reference.toUpperCase()
      : reference;
}

String? _extractReferenceFromOfficialUrl(String input, String receiptBaseUrl) {
  final uri = Uri.tryParse(input);
  final baseUri = Uri.tryParse(receiptBaseUrl.trim());
  if (uri == null || baseUri == null) {
    return null;
  }

  if (!_sameOrigin(uri, baseUri)) {
    return null;
  }

  for (final key in const ['id', 'token', 'reference', 'ref']) {
    final value = uri.queryParameters[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  final baseSegments = baseUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  final candidateSegments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (!_startsWithSegments(candidateSegments, baseSegments)) {
    return null;
  }

  if (candidateSegments.length > baseSegments.length) {
    return candidateSegments[baseSegments.length].trim();
  }

  return null;
}

bool _sameOrigin(Uri candidate, Uri base) {
  int effectivePort(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }
    return uri.scheme.toLowerCase() == 'https' ? 443 : 80;
  }

  return candidate.scheme.toLowerCase() == base.scheme.toLowerCase() &&
      candidate.host.toLowerCase() == base.host.toLowerCase() &&
      effectivePort(candidate) == effectivePort(base);
}

bool _startsWithSegments(List<String> value, List<String> prefix) {
  if (value.length < prefix.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index++) {
    if (value[index].toLowerCase() != prefix[index].toLowerCase()) {
      return false;
    }
  }
  return true;
}
