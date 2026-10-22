import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';

const bingoColumnHeaders = ['B', 'I', 'N', 'G', 'O'];

String manualMarkKey(String header, String value) => '$header:$value';

Set<String> normalizeManualMarkedNumbers(Set<String> manualMarkedNumbers) {
  return manualMarkedNumbers.where((key) => key.contains(':')).toSet();
}

Set<String> markKeysOnCartela(GameCartelaModel cartela) {
  final keys = <String>{};
  for (
    var columnIndex = 0;
    columnIndex < cartela.cartela.columns.length;
    columnIndex++
  ) {
    if (columnIndex >= bingoColumnHeaders.length) {
      continue;
    }

    final header = bingoColumnHeaders[columnIndex];
    for (final value in cartela.cartela.columns[columnIndex]) {
      if (value == 'FREE') {
        continue;
      }
      keys.add(manualMarkKey(header, value));
    }
  }
  return keys;
}

bool isManuallyMarkedCell({
  required Set<String> manualMarkedNumbers,
  required String header,
  required String value,
}) {
  return value == 'FREE' ||
      normalizeManualMarkedNumbers(
        manualMarkedNumbers,
      ).contains(manualMarkKey(header, value));
}

bool isLastManuallyMarkedCell({
  required String? lastManualMarkedKey,
  required String header,
  required String value,
}) {
  if (value == 'FREE' || lastManualMarkedKey == null) {
    return false;
  }
  return lastManualMarkedKey == manualMarkKey(header, value);
}

/// Toggles a shared mark (`B:5`) that appears on every cartela with that number.
Set<String> toggleManualMarkedNumber({
  required Set<String> manualMarkedNumbers,
  required String header,
  required String value,
}) {
  if (value == 'FREE') {
    return manualMarkedNumbers;
  }

  final key = manualMarkKey(header, value);
  final next = Set<String>.from(
    normalizeManualMarkedNumbers(manualMarkedNumbers),
  );
  if (next.contains(key)) {
    next.remove(key);
  } else {
    next.add(key);
  }

  return next;
}

String? resolveLastManualMarkedKey({
  required String? currentLastMarkedKey,
  required Set<String> nextMarks,
  required String toggledKey,
}) {
  final normalizedMarks = normalizeManualMarkedNumbers(nextMarks);

  if (!normalizedMarks.contains(toggledKey)) {
    return currentLastMarkedKey == toggledKey ? null : currentLastMarkedKey;
  }

  return toggledKey;
}

/// Returns shared marks that exist on this cartela board.
Set<String> manualMarksForCartela({
  required GameCartelaModel cartela,
  required Set<String> manualMarkedNumbers,
}) {
  final globalMarks = normalizeManualMarkedNumbers(manualMarkedNumbers);
  return globalMarks.intersection(markKeysOnCartela(cartela));
}

String? lastManualMarkedKeyForCartela({
  required String? lastManualMarkedKey,
  required GameCartelaModel cartela,
}) {
  if (lastManualMarkedKey == null) {
    return null;
  }

  final marksOnCartela = manualMarksForCartela(
    cartela: cartela,
    manualMarkedNumbers: {lastManualMarkedKey},
  );
  return marksOnCartela.contains(lastManualMarkedKey)
      ? lastManualMarkedKey
      : null;
}

/// Clears shared marks for numbers that appear on this cartela.
Set<String> clearManualMarksForCartela({
  required Set<String> manualMarkedNumbers,
  required GameCartelaModel cartela,
}) {
  final globalMarks = normalizeManualMarkedNumbers(manualMarkedNumbers);
  return globalMarks.difference(markKeysOnCartela(cartela));
}

/// Mark keys (`B:5`) for authoritative called numbers only.
Set<String> calledNumberMarkKeys(
  Iterable<CalledNumberModel> calledNumbers,
) {
  final keys = <String>{};
  for (final call in calledNumbers) {
    keys.add(manualMarkKey(call.letter, call.number.toString()));
  }
  return keys;
}

/// Visual cartela marks: always include manual marks; when
/// [effectiveAutoMark] is true, also include marks derived from
/// authoritative [calledNumbers]. Auto-derived marks are never persisted.
Set<String> visualMarkedNumbers({
  required Set<String> manualMarkedNumbers,
  required Iterable<CalledNumberModel> calledNumbers,
  required bool effectiveAutoMark,
}) {
  final manual = normalizeManualMarkedNumbers(manualMarkedNumbers);
  if (!effectiveAutoMark) {
    return manual;
  }

  final marks = Set<String>.from(manual);
  for (final call in calledNumbers) {
    marks.add(manualMarkKey(call.letter, call.number.toString()));
  }
  return marks;
}

Set<String> reviewMarksIncludingCalled({
  required Set<String> manualMarkedNumbers,
  required List<CalledNumberModel> calledNumbers,
}) {
  return visualMarkedNumbers(
    manualMarkedNumbers: manualMarkedNumbers,
    calledNumbers: calledNumbers,
    effectiveAutoMark: true,
  );
}
