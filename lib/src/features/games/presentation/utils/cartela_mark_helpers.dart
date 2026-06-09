const bingoColumnHeaders = ['B', 'I', 'N', 'G', 'O'];

String manualMarkKey(String header, String value) => '$header:$value';

bool isManuallyMarkedCell({
  required Set<String> manualMarkedNumbers,
  required String header,
  required String value,
}) {
  return value == 'FREE' ||
      manualMarkedNumbers.contains(manualMarkKey(header, value));
}

Set<String> toggleManualMarkedNumber({
  required Set<String> manualMarkedNumbers,
  required String header,
  required String value,
}) {
  if (value == 'FREE') {
    return manualMarkedNumbers;
  }

  final key = manualMarkKey(header, value);
  final next = Set<String>.from(manualMarkedNumbers);
  if (next.contains(key)) {
    next.remove(key);
  } else {
    next.add(key);
  }

  return next;
}
