import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/logging/app_logger.dart';

/// Bounded, PII-safe claim lifecycle traces for support correlation by UUID.
class BingoClaimDiagnostics {
  BingoClaimDiagnostics._();

  static const _maxEntries = 48;
  static final ListQueue<_BingoDiagEntry> _entries =
      ListQueue<_BingoDiagEntry>();

  static void record({
    required String event,
    required String claimAttemptId,
    String? sessionId,
    String? cartelaId,
    int? elapsedMs,
    int? statusCode,
    String? dioType,
    String? claimStatus,
    int? retryCount,
    String? state,
    String? detail,
  }) {
    final entry = _BingoDiagEntry(
      at: DateTime.now().toUtc(),
      event: event,
      claimAttemptId: claimAttemptId,
      sessionId: sessionId,
      cartelaId: cartelaId,
      elapsedMs: elapsedMs,
      statusCode: statusCode,
      dioType: dioType,
      claimStatus: claimStatus,
      retryCount: retryCount,
      state: state,
      detail: detail,
    );
    _entries.addLast(entry);
    while (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    final line = entry.format();
    AppLogger.debug('bingo_claim', line);
  }

  static String exportText({String? claimAttemptId}) {
    final rows = claimAttemptId == null
        ? _entries.toList(growable: false)
        : _entries
            .where((e) => e.claimAttemptId == claimAttemptId)
            .toList(growable: false);
    if (rows.isEmpty) {
      return 'No bingo claim diagnostics recorded.';
    }
    return rows.map((e) => e.format()).join('\n');
  }

  static Future<void> copyToClipboard({String? claimAttemptId}) {
    return Clipboard.setData(
      ClipboardData(text: exportText(claimAttemptId: claimAttemptId)),
    );
  }

  @visibleForTesting
  static void clearForTest() => _entries.clear();
}

class _BingoDiagEntry {
  _BingoDiagEntry({
    required this.at,
    required this.event,
    required this.claimAttemptId,
    this.sessionId,
    this.cartelaId,
    this.elapsedMs,
    this.statusCode,
    this.dioType,
    this.claimStatus,
    this.retryCount,
    this.state,
    this.detail,
  });

  final DateTime at;
  final String event;
  final String claimAttemptId;
  final String? sessionId;
  final String? cartelaId;
  final int? elapsedMs;
  final int? statusCode;
  final String? dioType;
  final String? claimStatus;
  final int? retryCount;
  final String? state;
  final String? detail;

  String format() {
    final parts = <String>[
      at.toIso8601String(),
      'event=$event',
      'claimAttemptId=$claimAttemptId',
      if (sessionId != null) 'sessionId=$sessionId',
      if (cartelaId != null) 'cartelaId=$cartelaId',
      if (elapsedMs != null) 'elapsedMs=$elapsedMs',
      if (statusCode != null) 'http=$statusCode',
      if (dioType != null) 'dio=$dioType',
      if (claimStatus != null) 'status=$claimStatus',
      if (retryCount != null) 'retry=$retryCount',
      if (state != null) 'state=$state',
      if (detail != null) 'detail=$detail',
    ];
    return parts.join(' ');
  }
}
