import 'package:flutter/foundation.dart';

import '../data/models/game_model.dart';
import '../data/models/registration_state_model.dart';
import '../../../core/logging/app_logger.dart';

class RegistrationCartelaChange {
  const RegistrationCartelaChange({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.owner,
    this.actorUserId,
    this.expiresAt,
  });

  final String cartelaId;
  final int cartelaNumber;
  final String owner;
  final String? actorUserId;
  final DateTime? expiresAt;

  factory RegistrationCartelaChange.fromSocketJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final owner = _resolveOwner(
      owner: json['owner'] as String? ?? 'OTHER',
      actorUserId: json['actorUserId'] as String?,
      currentUserId: currentUserId,
    );

    return RegistrationCartelaChange(
      cartelaId: json['cartelaId'] as String,
      cartelaNumber: json['cartelaNumber'] as int,
      owner: owner,
      actorUserId: json['actorUserId'] as String?,
      expiresAt: json['expiresAt'] is String
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  RegisteredCartelaSummary? toSummary() {
    if (owner == 'AVAILABLE') {
      return null;
    }

    return RegisteredCartelaSummary(
      cartelaId: cartelaId,
      cartelaNumber: cartelaNumber,
      owner: owner,
      status: owner.startsWith('RESERVED') ? 'RESERVED' : 'REGISTERED',
      expiresAt: expiresAt,
    );
  }
}

String _resolveOwner({
  required String owner,
  required String? actorUserId,
  required String? currentUserId,
}) {
  if (owner == 'AVAILABLE') {
    return 'AVAILABLE';
  }

  if (actorUserId != null &&
      currentUserId != null &&
      actorUserId == currentUserId) {
    if (owner == 'RESERVED_OTHER' || owner == 'RESERVED_ME') {
      return 'RESERVED_ME';
    }
    if (owner == 'OTHER' || owner == 'ME') {
      return 'ME';
    }
  }

  if (owner == 'RESERVED_ME' && actorUserId != currentUserId) {
    return 'RESERVED_OTHER';
  }

  if (owner == 'ME' && actorUserId != currentUserId) {
    return 'OTHER';
  }

  return owner;
}

/// Result of parsing socket/API cartela change payloads.
class ParsedRegistrationCartelaChanges {
  const ParsedRegistrationCartelaChanges({
    required this.valid,
    required this.hasMalformed,
  });

  final List<RegistrationCartelaChange> valid;
  final bool hasMalformed;
}

bool isValidRegistrationCartelaChangeJson(Map<String, dynamic> json) {
  final cartelaId = json['cartelaId'];
  final cartelaNumber = json['cartelaNumber'];
  final owner = json['owner'];

  if (cartelaId is! String || cartelaId.isEmpty) {
    return false;
  }
  if (cartelaNumber is! num) {
    return false;
  }
  if (owner is! String || owner.isEmpty) {
    return false;
  }

  return true;
}

ParsedRegistrationCartelaChanges parseAndValidateRegistrationCartelaChanges(
  Object? rawChanges, {
  String? currentUserId,
}) {
  if (rawChanges is! List) {
    return ParsedRegistrationCartelaChanges(
      valid: const [],
      hasMalformed: rawChanges != null,
    );
  }

  final valid = <RegistrationCartelaChange>[];
  var hasMalformed = false;

  for (final item in rawChanges) {
    if (item is! Map<String, dynamic>) {
      hasMalformed = true;
      continue;
    }
    if (!isValidRegistrationCartelaChangeJson(item)) {
      hasMalformed = true;
      if (kDebugMode) {
        AppLogger.debug(
          'registration_patch',
          'ignored malformed cartela change payload',
        );
      }
      continue;
    }

    valid.add(
      RegistrationCartelaChange.fromSocketJson(
        item,
        currentUserId: currentUserId,
      ),
    );
  }

  return ParsedRegistrationCartelaChanges(
    valid: valid,
    hasMalformed: hasMalformed,
  );
}

int _ownerPriority(String owner) {
  return switch (owner) {
    'ME' || 'OTHER' => 3,
    'RESERVED_ME' || 'RESERVED_OTHER' => 2,
    _ => 0,
  };
}

/// Merges one snapshot summary with a confirmed realtime patch.
RegisteredCartelaSummary? mergeCartelaSummaryWithPatch({
  RegisteredCartelaSummary? base,
  RegisteredCartelaSummary? patch,
}) {
  return _mergeSummaryWithPatch(base: base, patch: patch);
}

RegisteredCartelaSummary? _mergeSummaryWithPatch({
  RegisteredCartelaSummary? base,
  RegisteredCartelaSummary? patch,
}) {
  if (patch == null) {
    return base;
  }
  if (base == null) {
    return patch;
  }

  if (_ownerPriority(patch.owner) >= _ownerPriority(base.owner)) {
    return patch;
  }

  return base;
}

/// Merges canonical registration snapshot with confirmed session patches.
List<RegisteredCartelaSummary> mergeRegistrationStateWithPatches({
  required RegistrationStateResponse? snapshot,
  required Map<String, RegisteredCartelaSummary> patches,
  required Set<String> removedCartelaIds,
  required String sessionId,
}) {
  if (snapshot != null && snapshot.sessionId != sessionId) {
    return const [];
  }

  final base = snapshot == null
      ? const <RegisteredCartelaSummary>[]
      : _mergeRegisteredAndReservedSummaries(
          snapshot.registeredCartelasSummary,
          snapshot.reservedCartelasSummary,
        );

  return mergeRegistrationSummariesWithPatches(
    base: base,
    patches: patches,
    removedCartelaIds: removedCartelaIds,
  );
}

List<RegisteredCartelaSummary> _mergeRegisteredAndReservedSummaries(
  List<RegisteredCartelaSummary> registered,
  List<RegisteredCartelaSummary> reserved,
) {
  final merged = <String, RegisteredCartelaSummary>{};
  for (final summary in registered) {
    merged[summary.cartelaId] = summary;
  }
  for (final summary in reserved) {
    final mergedSummary = _mergeSummaryWithPatch(
      base: merged[summary.cartelaId],
      patch: summary,
    );
    if (mergedSummary != null) {
      merged[summary.cartelaId] = mergedSummary;
    }
  }
  return merged.values.toList(growable: false);
}

List<RegisteredCartelaSummary> mergeRegistrationSummariesWithPatches({
  required List<RegisteredCartelaSummary> base,
  required Map<String, RegisteredCartelaSummary> patches,
  required Set<String> removedCartelaIds,
}) {
  final merged = <String, RegisteredCartelaSummary>{
    for (final item in base) item.cartelaId: item,
  };

  for (final entry in patches.entries) {
    if (removedCartelaIds.contains(entry.key)) {
      continue;
    }
    final mergedSummary = _mergeSummaryWithPatch(
      base: merged[entry.key],
      patch: entry.value,
    );
    if (mergedSummary != null) {
      merged[entry.key] = mergedSummary;
    } else {
      merged.remove(entry.key);
    }
  }

  for (final cartelaId in removedCartelaIds) {
    merged.remove(cartelaId);
  }

  return merged.values.toList(growable: false);
}

void reconcileRegistrationPatches({
  required Map<String, RegisteredCartelaSummary> patches,
  required Set<String> removedCartelaIds,
  required List<RegisteredCartelaSummary> confirmed,
}) {
  final confirmedById = {
    for (final item in confirmed) item.cartelaId: item,
  };

  for (final cartelaId in confirmedById.keys) {
    removedCartelaIds.remove(cartelaId);
  }

  for (final entry in confirmedById.entries) {
    final patch = patches[entry.key];
    if (patch == null) {
      continue;
    }

    if (_summaryMatchesPatch(entry.value, patch)) {
      patches.remove(entry.key);
    }
  }

  removedCartelaIds.removeWhere((cartelaId) => !confirmedById.containsKey(cartelaId));
}

bool _summaryMatchesPatch(
  RegisteredCartelaSummary confirmed,
  RegisteredCartelaSummary patch,
) {
  if (confirmed.owner != patch.owner) {
    return false;
  }

  if (patch.isReservedByMe || patch.isReservedByOther) {
    if (confirmed.expiresAt == null || patch.expiresAt == null) {
      return confirmed.owner == patch.owner;
    }

    return confirmed.expiresAt!.difference(patch.expiresAt!).inSeconds.abs() <= 1;
  }

  return true;
}

List<RegistrationCartelaChange> parseRegistrationCartelaChanges(
  Object? rawChanges, {
  String? currentUserId,
}) {
  return parseAndValidateRegistrationCartelaChanges(
    rawChanges,
    currentUserId: currentUserId,
  ).valid;
}
