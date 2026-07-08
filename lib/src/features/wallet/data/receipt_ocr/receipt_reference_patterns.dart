import '../models/payment_provider.dart';
import 'receipt_ocr_result.dart';

class ReceiptReferencePatterns {
  // ─────────────────────── Reference patterns (unchanged for non-CBE) ───────────────
  static final RegExp _telebirrReferencePattern = RegExp(
    r'\bD[A-Z0-9]{8,15}\b',
  );
  static final RegExp _awashReferencePattern = RegExp(r'\b\d{12,18}\b');

  // CBE: labeled patterns (applied to uppercase-normalized text)
  static final List<RegExp> _cbeLabeledRefLabels = [
    RegExp(r'TRANSACTION\s*ID\s*[:=\s]\s*'),
    RegExp(r'REFERENCE\s*NO\.?\s*[:=\s]\s*'),
    RegExp(r'VAT\s*RECEIPT\s*NO\.?\s*[:=\s]\s*'),
  ];

  // CBE bare-FT fallback (no space, normalized uppercase text)
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

  // CBE receipt validation markers
  static const List<String> _cbeMarkers = [
    'COMMERCIAL BANK OF ETHIOPIA',
    'CBE',
    'CBETETAA',
  ];

  // ──────────────────────────────────── Public API ───────────────────────────────────

  static String? detectReference(PaymentProvider provider, String rawText) {
    final text = _normalize(rawText);
    if (text.isEmpty) return null;

    if (provider == PaymentProvider.cbe || provider == PaymentProvider.boa) {
      return _detectCbeFtReference(text)?.reference;
    }

    final match = switch (provider) {
      PaymentProvider.telebirr => _telebirrReferencePattern.firstMatch(text),
      PaymentProvider.awash => _awashReferencePattern.firstMatch(text),
      _ => null,
    };
    return match?.group(0);
  }

  static String? detectAmount(PaymentProvider provider, String rawText) {
    return _extractBestAmountCandidate(provider, rawText)?.normalizedAmount;
  }

  static ReceiptOcrResult parse(PaymentProvider provider, String rawText) {
    final normalized = _normalize(rawText);

    // CBE-only: validate the image is actually a CBE receipt.
    // If the text contains no CBE markers, return confidence 0.
    if (provider == PaymentProvider.cbe) {
      if (!_containsAny(normalized, _cbeMarkers)) {
        return ReceiptOcrResult(
          reference: null,
          amount: null,
          rawText: rawText,
          provider: provider.apiValue,
          confidence: 0.0,
        );
      }
    }

    // Reference
    bool referenceCorrected = false;
    String? reference;
    if (provider == PaymentProvider.cbe || provider == PaymentProvider.boa) {
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

  // ──────────────────────────── CBE reference detection ─────────────────────────────

  static _FtRefResult? _detectCbeFtReference(String normalizedText) {
    // 1. Try labeled patterns: "transaction ID:", "Reference No.", "VAT Receipt No."
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
        final corrected = _applyOcrCorrections(beforeCorrection);
        final wasCorrected = corrected != beforeCorrection;
        return _FtRefResult(reference: corrected, corrected: wasCorrected);
      }
    }

    // 2. Bare FT pattern fallback (already normalized uppercase)
    final match = _ftPatternBare.firstMatch(normalizedText);
    if (match != null) {
      final raw = match.group(0)!;
      final corrected = _applyOcrCorrections(raw);
      return _FtRefResult(
        reference: corrected,
        corrected: corrected != raw,
      );
    }

    return null;
  }

  /// Extracts an FT reference token from a ~45-char context window after the label.
  /// Handles one OCR-inserted space (e.g. "FT26174 PCT3Q").
  static String? _extractFtTokenFromContext(String context) {
    // First try: no spaces (clean OCR)
    final cleanMatch = RegExp(r'FT[A-Z0-9]{6,20}').firstMatch(context);
    if (cleanMatch != null) {
      final candidate = cleanMatch.group(0)!;
      if (_isValidFtReference(candidate)) return candidate;
    }

    // Second try: one OCR-inserted space splitting the token
    final splitMatch =
        RegExp(r'FT[A-Z0-9]{3,10}\s[A-Z0-9]{1,10}').firstMatch(context);
    if (splitMatch != null) {
      final candidate = splitMatch.group(0)!.replaceAll(' ', '');
      if (_isValidFtReference(candidate)) return candidate;
    }

    return null;
  }

  /// Apply OCR confusion corrections ONLY when a character is between two digits.
  /// Safe substitutions: I/l/L→1, O→0, S→5, B→8, Z→2
  /// Note: text is normalized to uppercase before this runs, so lowercase l
  /// will appear as L.
  static String _applyOcrCorrections(String input) {
    return input.replaceAllMapped(
      RegExp(r'(?<=[0-9])[IiLlOSBZ](?=[0-9])'),
      (m) => switch (m.group(0)!) {
        'I' || 'i' || 'L' || 'l' => '1',
        'O' => '0',
        'S' => '5',
        'B' => '8',
        'Z' => '2',
        _ => m.group(0)!,
      },
    );
  }

  static bool _isValidFtReference(String candidate) {
    return candidate.startsWith('FT') &&
        candidate.length >= 8 &&
        candidate.length <= 25 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(candidate);
  }

  // ───────────────────────────────── Amount extraction ──────────────────────────────

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
      final normalizedLine = _normalize(lines[index]);
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
        final normalized = _normalizeAmount(rawValue);
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
    // --- Ignore fee/tax lines (checked first) ---
    if (_containsAny(normalizedLine, const [
      'SERVICE CHARGE',
      'SERVICE FEE',
      'CHARGE',
      'FEE',
      'VAT',
      'DISASTER RECOVERY',
    ])) {
      return _AmountLineType.ignore;
    }

    // --- Priority 1: Transferred Amount label ---
    if (_containsAny(normalizedLine, const [
      'TRANSFERRED AMOUNT',
      'TRANSFER AMOUNT',
    ])) {
      return _AmountLineType.transferred;
    }

    // --- Priority 2: "ETB XX.X has been debited" (CBE app screenshot) ---
    if (normalizedLine.contains('HAS BEEN DEBITED')) {
      return _AmountLineType.debitedStatement;
    }

    if (_containsAny(normalizedLine, const ['SETTLED AMOUNT'])) {
      return _AmountLineType.settled;
    }

    // --- Low-priority total lines (include bank fees, never first choice) ---
    if (_containsAny(normalizedLine, const [
      'TOTAL AMOUNT DEBITED',
      'TOTAL DEBITED',
    ])) {
      return _AmountLineType.totalDebited;
    }
    if (_containsAny(normalizedLine, const [
      'TOTAL PAID AMOUNT',
      'TOTAL PAID',
    ])) {
      return _AmountLineType.totalPaid;
    }

    // --- Priority 3: Generic "Amount" label ---
    if (_containsAny(normalizedLine, const ['AMOUNT'])) {
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
      // Priority 1: explicit "Transferred Amount" label
      _AmountLineType.transferred => switch (provider) {
        PaymentProvider.cbe => 120,
        PaymentProvider.telebirr => 115,
        PaymentProvider.awash => 110,
        PaymentProvider.boa => 110,
      },
      // Priority 2 (CBE): "ETB XX.X has been debited" in the summary sentence
      _AmountLineType.debitedStatement => switch (provider) {
        PaymentProvider.cbe => 110,
        _ => 80,
      },
      _AmountLineType.settled => switch (provider) {
        PaymentProvider.telebirr => 112,
        _ => 102,
      },
      // Priority 3: generic "Amount" label
      _AmountLineType.amount => switch (provider) {
        PaymentProvider.awash => 110,
        PaymentProvider.boa => 110,
        PaymentProvider.telebirr => 105,
        PaymentProvider.cbe => 100,
      },
      // Low priority: these include bank fees — only used if nothing better exists
      _AmountLineType.totalDebited => 50,
      _AmountLineType.totalPaid => 45,
      _AmountLineType.genericEtb => 30,
      _AmountLineType.unknown => 10,
    };
  }

  // ─────────────────────────────────── Confidence ───────────────────────────────────

  static double _calcConfidence({
    required String? amount,
    required _AmountLineType? amountLineType,
    required String? reference,
    required bool referenceCorrected,
  }) {
    // Amount score based on source quality.
    // High-quality single-field result scores ≥ 0.60 so the UI can pre-fill.
    // "Total Amount Debited" scores very low because it includes bank fees.
    final amountScore = amount == null
        ? 0.0
        : switch (amountLineType) {
            _AmountLineType.transferred => 0.70,
            _AmountLineType.debitedStatement => 0.70,
            _AmountLineType.settled => 0.68,
            _AmountLineType.amount => 0.62,
            // totalDebited/totalPaid include fees — very low confidence
            _AmountLineType.totalDebited => 0.20,
            _AmountLineType.totalPaid => 0.20,
            _ => 0.15,
          };

    // Reference score.
    // Clean + good amount → 0.70 + 0.50 = 1.20 → clamped to 1.0 ✓
    // Corrected + good amount → 0.70 + 0.15 = 0.85 ✓
    final refScore = reference == null
        ? 0.0
        : referenceCorrected
        ? 0.15
        : 0.50;

    return (amountScore + refScore).clamp(0.0, 1.0);
  }

  // ───────────────────────────────────── Helpers ────────────────────────────────────

  static String? _normalizeAmount(String rawValue) {
    final sanitized = rawValue.replaceAll(',', '').trim();
    if (sanitized.isEmpty) return null;

    final parsed = double.tryParse(sanitized);
    if (parsed == null || parsed <= 0 || parsed >= 100000) return null;

    return parsed.toStringAsFixed(2);
  }

  static String _normalize(String rawText) {
    return rawText.toUpperCase().replaceAll('\u00A0', ' ').trim();
  }

  static bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) return true;
    }
    return false;
  }
}

// ─────────────────────────────────── Internal types ───────────────────────────────

enum _AmountLineType {
  transferred,
  debitedStatement, // "ETB XX.X has been debited" — CBE app screenshot line
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
