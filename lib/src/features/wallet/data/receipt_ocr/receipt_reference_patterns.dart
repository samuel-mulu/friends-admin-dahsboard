import '../models/payment_provider.dart';
import 'cbe_receipt_ocr_helper.dart';
import 'receipt_ocr_result.dart';
import 'receipt_ocr_text_utils.dart';
import 'telebirr_receipt_ocr_helper.dart';

class ReceiptReferencePatterns {
  // ─────────────────────── Reference patterns (Awash / BOA fallback) ───────────────
  static final RegExp _awashReferencePattern = RegExp(r'\b\d{12,18}\b');

  // CBE/BOA shared FT detection (BOA still uses this path)
  static final List<RegExp> _cbeLabeledRefLabels = [
    RegExp(r'TRANSACTION\s*ID\s*[:=\s]\s*'),
    RegExp(r'REFERENCE\s*NO\.?\s*[:=\s]\s*'),
    RegExp(r'VAT\s*RECEIPT\s*NO\.?\s*[:=\s]\s*'),
  ];

  static final RegExp _ftPatternBare = RegExp(r'\bFT[A-Z0-9]{6,20}\b');

  // ─────────────────────────────── Amount patterns ──────────────────────────────────
  static final RegExp _amountPrefixPattern = RegExp(
    r'ETB\s*(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)',
  );
  static final RegExp _amountSuffixPattern = RegExp(
    r'(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*ETB\b',
  );
  static final RegExp _labeledAmountPattern = RegExp(
    r'(TRANSFERRED AMOUNT|SETTLED AMOUNT|TOTAL AMOUNT DEBITED|TOTAL DEBITED|TOTAL PAID AMOUNT|TOTAL PAID|TOTAL AMOUNT|TOTAL|AMOUNT)\s*[:\-]?\s*(?:ETB\s*)?(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)',
  );

  // ──────────────────────────────────── Public API ───────────────────────────────────

  static String? detectReference(PaymentProvider provider, String rawText) {
    if (provider == PaymentProvider.cbe) {
      return CbeReceiptOcrHelper.parse(rawText).reference;
    }
    if (provider == PaymentProvider.telebirr) {
      return TelebirrReceiptOcrHelper.parse(rawText).reference;
    }

    final text = ReceiptOcrTextUtils.normalize(rawText);
    if (text.isEmpty) return null;

    if (provider == PaymentProvider.boa) {
      return _detectCbeFtReference(text)?.reference;
    }

    final match = switch (provider) {
      PaymentProvider.awash => _awashReferencePattern.firstMatch(text),
      _ => null,
    };
    return match?.group(0);
  }

  static String? detectAmount(PaymentProvider provider, String rawText) {
    if (provider == PaymentProvider.cbe) {
      return CbeReceiptOcrHelper.parse(rawText).amount;
    }
    if (provider == PaymentProvider.telebirr) {
      return TelebirrReceiptOcrHelper.parse(rawText).amount;
    }
    return _extractBestAmountCandidate(provider, rawText)?.normalizedAmount;
  }

  static ReceiptOcrResult parse(PaymentProvider provider, String rawText) {
    if (provider == PaymentProvider.cbe) {
      return CbeReceiptOcrHelper.parse(rawText);
    }
    if (provider == PaymentProvider.telebirr) {
      return TelebirrReceiptOcrHelper.parse(rawText);
    }

    final normalized = ReceiptOcrTextUtils.normalize(rawText);

    // Reference (BOA / Awash)
    bool referenceCorrected = false;
    String? reference;
    if (provider == PaymentProvider.boa) {
      final refResult = _detectCbeFtReference(normalized);
      reference = refResult?.reference;
      referenceCorrected = refResult?.corrected ?? false;
    } else {
      reference = detectReference(provider, rawText);
    }

    // Amount
    final best = _extractBestAmountCandidate(provider, rawText);
    final amount = best?.normalizedAmount;
    final amountLineType = best?.lineType;

    final confidence = _calcConfidence(
      amount: amount,
      amountLineType: amountLineType,
      reference: reference,
      referenceCorrected: referenceCorrected,
    );

    return ReceiptOcrResult(
      reference: reference,
      amount: amount,
      rawText: rawText,
      provider: provider.apiValue,
      confidence: confidence,
    );
  }

  // ──────────────────────────── BOA FT reference detection ──────────────────────────

  static _FtRefResult? _detectCbeFtReference(String normalizedText) {
    for (final labelPattern in _cbeLabeledRefLabels) {
      final labelMatch = labelPattern.firstMatch(normalizedText);
      if (labelMatch == null) continue;

      final contextStart = labelMatch.end;
      final context = normalizedText.substring(
        contextStart,
        (contextStart + 45).clamp(0, normalizedText.length),
      );

      final token = _extractFtTokenFromContext(context);
      if (token != null) {
        final beforeCorrection = token.replaceAll(' ', '').toUpperCase();
        final corrected = ReceiptOcrTextUtils.applyOcrCorrections(
          beforeCorrection,
        );
        final wasCorrected = corrected != beforeCorrection;
        return _FtRefResult(reference: corrected, corrected: wasCorrected);
      }
    }

    final match = _ftPatternBare.firstMatch(normalizedText);
    if (match != null) {
      final raw = match.group(0)!;
      final corrected = ReceiptOcrTextUtils.applyOcrCorrections(raw);
      return _FtRefResult(reference: corrected, corrected: corrected != raw);
    }

    return null;
  }

  static String? _extractFtTokenFromContext(String context) {
    final cleanMatch = RegExp(r'FT[A-Z0-9]{6,20}').firstMatch(context);
    if (cleanMatch != null) {
      final candidate = cleanMatch.group(0)!;
      if (_isValidFtReference(candidate)) return candidate;
    }

    final splitMatch = RegExp(
      r'FT[A-Z0-9]{3,10}\s[A-Z0-9]{1,10}',
    ).firstMatch(context);
    if (splitMatch != null) {
      final candidate = splitMatch.group(0)!.replaceAll(' ', '');
      if (_isValidFtReference(candidate)) return candidate;
    }

    return null;
  }

  static bool _isValidFtReference(String candidate) {
    return candidate.startsWith('FT') &&
        candidate.length >= 8 &&
        candidate.length <= 25 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(candidate);
  }

  // ───────────────────────────────── Amount extraction (Awash/BOA) ──────────────────

  static _AmountCandidate? _extractBestAmountCandidate(
    PaymentProvider provider,
    String rawText,
  ) {
    final candidates = _extractAmountCandidates(provider, rawText);
    if (candidates.isEmpty) return null;

    candidates.sort((left, right) {
      final byPriority = right.priority.compareTo(left.priority);
      if (byPriority != 0) return byPriority;
      return left.index.compareTo(right.index);
    });

    return candidates.first;
  }

  static List<_AmountCandidate> _extractAmountCandidates(
    PaymentProvider provider,
    String rawText,
  ) {
    final lines = rawText.split(RegExp(r'[\r\n]+'));
    final candidates = <_AmountCandidate>[];

    for (var index = 0; index < lines.length; index += 1) {
      final normalizedLine = ReceiptOcrTextUtils.normalize(lines[index]);
      if (normalizedLine.isEmpty) continue;

      final lineType = _classifyAmountLine(normalizedLine);
      if (lineType == _AmountLineType.ignore) continue;

      final values = <String>{};
      for (final match in _labeledAmountPattern.allMatches(normalizedLine)) {
        final value = match.group(2);
        if (value != null && value.isNotEmpty) values.add(value);
      }
      for (final match in _amountPrefixPattern.allMatches(normalizedLine)) {
        final value = match.group(1);
        if (value != null && value.isNotEmpty) values.add(value);
      }
      for (final match in _amountSuffixPattern.allMatches(normalizedLine)) {
        final value = match.group(1);
        if (value != null && value.isNotEmpty) values.add(value);
      }

      if (values.isEmpty) continue;

      final priority = _priorityForLine(provider, lineType);
      if (priority <= 0) continue;

      for (final rawValue in values) {
        final normalized = ReceiptOcrTextUtils.normalizeAmount(rawValue);
        if (normalized == null) continue;
        candidates.add(
          _AmountCandidate(
            normalizedAmount: normalized,
            lineType: lineType,
            priority: priority,
            index: index,
          ),
        );
      }
    }

    return candidates;
  }

  static _AmountLineType _classifyAmountLine(String normalizedLine) {
    if (ReceiptOcrTextUtils.containsAny(normalizedLine, const [
      'SERVICE CHARGE',
      'SERVICE FEE',
      'CHARGE',
      'FEE',
      'VAT',
      'DISASTER RECOVERY',
    ])) {
      return _AmountLineType.ignore;
    }

    if (ReceiptOcrTextUtils.containsAny(normalizedLine, const [
      'TRANSFERRED AMOUNT',
      'TRANSFER AMOUNT',
    ])) {
      return _AmountLineType.transferred;
    }

    if (normalizedLine.contains('HAS BEEN DEBITED')) {
      return _AmountLineType.debitedStatement;
    }

    if (ReceiptOcrTextUtils.containsAny(normalizedLine, const [
      'SETTLED AMOUNT',
    ])) {
      return _AmountLineType.settled;
    }

    if (ReceiptOcrTextUtils.containsAny(normalizedLine, const [
      'TOTAL AMOUNT DEBITED',
      'TOTAL DEBITED',
    ])) {
      return _AmountLineType.totalDebited;
    }
    if (ReceiptOcrTextUtils.containsAny(normalizedLine, const [
      'TOTAL PAID AMOUNT',
      'TOTAL PAID',
    ])) {
      return _AmountLineType.totalPaid;
    }

    if (ReceiptOcrTextUtils.containsAny(normalizedLine, const ['AMOUNT'])) {
      return _AmountLineType.amount;
    }

    if (normalizedLine.contains('ETB')) {
      return _AmountLineType.genericEtb;
    }

    return _AmountLineType.unknown;
  }

  static int _priorityForLine(
    PaymentProvider provider,
    _AmountLineType lineType,
  ) {
    return switch (lineType) {
      _AmountLineType.ignore => 0,
      _AmountLineType.transferred => switch (provider) {
        PaymentProvider.cbe => 120,
        PaymentProvider.telebirr => 115,
        PaymentProvider.awash => 110,
        PaymentProvider.boa => 110,
      },
      _AmountLineType.debitedStatement => switch (provider) {
        PaymentProvider.cbe => 110,
        _ => 80,
      },
      _AmountLineType.settled => switch (provider) {
        PaymentProvider.telebirr => 112,
        _ => 102,
      },
      _AmountLineType.amount => switch (provider) {
        PaymentProvider.awash => 110,
        PaymentProvider.boa => 110,
        PaymentProvider.telebirr => 105,
        PaymentProvider.cbe => 100,
      },
      _AmountLineType.totalDebited => 50,
      _AmountLineType.totalPaid => 45,
      _AmountLineType.genericEtb => 30,
      _AmountLineType.unknown => 10,
    };
  }

  static double _calcConfidence({
    required String? amount,
    required _AmountLineType? amountLineType,
    required String? reference,
    required bool referenceCorrected,
  }) {
    final amountScore = amount == null
        ? 0.0
        : switch (amountLineType) {
            _AmountLineType.transferred => 0.70,
            _AmountLineType.debitedStatement => 0.70,
            _AmountLineType.settled => 0.68,
            _AmountLineType.amount => 0.62,
            _AmountLineType.totalDebited => 0.20,
            _AmountLineType.totalPaid => 0.20,
            _ => 0.15,
          };

    final refScore = reference == null
        ? 0.0
        : referenceCorrected
        ? 0.15
        : 0.50;

    return (amountScore + refScore).clamp(0.0, 1.0);
  }
}

enum _AmountLineType {
  transferred,
  debitedStatement,
  settled,
  amount,
  totalDebited,
  totalPaid,
  genericEtb,
  ignore,
  unknown,
}

class _AmountCandidate {
  const _AmountCandidate({
    required this.normalizedAmount,
    required this.lineType,
    required this.priority,
    required this.index,
  });

  final String normalizedAmount;
  final _AmountLineType lineType;
  final int priority;
  final int index;
}

class _FtRefResult {
  const _FtRefResult({required this.reference, required this.corrected});

  final String reference;
  final bool corrected;
}
