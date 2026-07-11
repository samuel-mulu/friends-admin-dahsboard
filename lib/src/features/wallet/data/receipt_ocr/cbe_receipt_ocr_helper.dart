import '../models/payment_provider.dart';
import 'receipt_ocr_result.dart';
import 'receipt_ocr_text_utils.dart';

/// Parses Commercial Bank of Ethiopia app success-screen screenshots.
///
/// Expected layout:
/// - Amount in `ETB <n> has been debited ...`
/// - Reference after `transaction ID:` / `ID:` starting with `FT`
class CbeReceiptOcrHelper {
  const CbeReceiptOcrHelper._();

  static const List<String> _markers = [
    'COMMERCIAL BANK OF ETHIOPIA',
    'CBE',
    'CBETETAA',
  ];

  static final List<RegExp> _labeledIdPatterns = [
    RegExp(r'TRANSACTION\s*ID\s*[:=\s]\s*'),
    RegExp(r'(?<![A-Z])ID\s*[:=\s]\s*'),
    RegExp(r'REFERENCE\s*NO\.?\s*[:=\s]\s*'),
    RegExp(r'VAT\s*RECEIPT\s*NO\.?\s*[:=\s]\s*'),
  ];

  static final RegExp _ftBare = RegExp(r'\bFT[A-Z0-9]{6,20}\b');
  static final RegExp _ftClean = RegExp(r'FT[A-Z0-9]{6,20}');
  static final RegExp _ftSplit = RegExp(r'FT[A-Z0-9]{3,10}\s[A-Z0-9]{1,10}');

  /// `ETB 60.0 has been debited` — transfer amount, not fee total.
  static final RegExp _debitAmountPattern = RegExp(
    r'ETB\s*(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)\s+HAS\s+BEEN\s+DEBITED',
  );

  static final RegExp _etbPrefix = RegExp(
    r'ETB\s*(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)',
  );

  static ReceiptOcrResult parse(String rawText) {
    final normalized = ReceiptOcrTextUtils.normalize(rawText);
    if (normalized.isEmpty) {
      return _empty(rawText);
    }

    final hasMarker = ReceiptOcrTextUtils.containsAny(normalized, _markers);
    if (!hasMarker) {
      // Still try FT + debit patterns — cropped screenshots may omit branding.
      // But keep confidence low unless layout matches strongly.
    }

    final refResult = _detectReference(normalized);
    final amountResult = _detectAmount(normalized);
    final layoutMatched =
        (refResult?.fromLabeledId ?? false) ||
        amountResult?.fromDebitSentence == true ||
        (hasMarker && refResult != null);

    if (!hasMarker && refResult == null && amountResult == null) {
      return ReceiptOcrResult(
        reference: null,
        amount: null,
        rawText: rawText,
        provider: PaymentProvider.cbe.apiValue,
        confidence: 0.0,
      );
    }

    // Without CBE markers and without a clear FT/debit layout, reject.
    if (!hasMarker && !layoutMatched) {
      return ReceiptOcrResult(
        reference: refResult?.reference,
        amount: amountResult?.amount,
        rawText: rawText,
        provider: PaymentProvider.cbe.apiValue,
        confidence: 0.0,
      );
    }

    final confidence = _calcConfidence(
      hasMarker: hasMarker,
      reference: refResult,
      amount: amountResult,
      layoutMatched: layoutMatched,
    );

    return ReceiptOcrResult(
      reference: refResult?.reference,
      amount: amountResult?.amount,
      rawText: rawText,
      provider: PaymentProvider.cbe.apiValue,
      confidence: confidence,
    );
  }

  static _CbeRefResult? _detectReference(String normalized) {
    for (final labelPattern in _labeledIdPatterns) {
      final labelMatch = labelPattern.firstMatch(normalized);
      if (labelMatch == null) continue;

      final contextStart = labelMatch.end;
      final context = normalized.substring(
        contextStart,
        (contextStart + 50).clamp(0, normalized.length),
      );

      final token = _extractFtFromContext(context);
      if (token != null) {
        final corrected = ReceiptOcrTextUtils.applyOcrCorrections(token);
        return _CbeRefResult(
          reference: corrected,
          corrected: corrected != token,
          fromLabeledId: true,
        );
      }
    }

    final bare = _ftBare.firstMatch(normalized);
    if (bare != null) {
      final raw = bare.group(0)!;
      final corrected = ReceiptOcrTextUtils.applyOcrCorrections(raw);
      if (_isValidFt(corrected)) {
        return _CbeRefResult(
          reference: corrected,
          corrected: corrected != raw,
          fromLabeledId: false,
        );
      }
    }

    return null;
  }

  static String? _extractFtFromContext(String context) {
    final clean = _ftClean.firstMatch(context);
    if (clean != null) {
      final candidate = clean.group(0)!;
      if (_isValidFt(candidate)) return candidate;
    }

    final split = _ftSplit.firstMatch(context);
    if (split != null) {
      final candidate = split.group(0)!.replaceAll(' ', '');
      if (_isValidFt(candidate)) return candidate;
    }

    return null;
  }

  static bool _isValidFt(String candidate) {
    return candidate.startsWith('FT') &&
        candidate.length >= 8 &&
        candidate.length <= 25 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(candidate);
  }

  static _CbeAmountResult? _detectAmount(String normalized) {
    // Prefer debit-sentence amount even when fees appear later on same blob.
    final debitMatch = _debitAmountPattern.firstMatch(normalized);
    if (debitMatch != null) {
      final amount = ReceiptOcrTextUtils.normalizeAmount(debitMatch.group(1)!);
      if (amount != null) {
        return _CbeAmountResult(amount: amount, fromDebitSentence: true);
      }
    }

    // Fallback: first ETB amount that is not clearly a fee fragment alone.
    // Skip tiny fee-like amounts only when they sit next to fee keywords
    // without a debit sentence (handled above).
    for (final match in _etbPrefix.allMatches(normalized)) {
      final raw = match.group(1)!;
      final amount = ReceiptOcrTextUtils.normalizeAmount(raw);
      if (amount == null) continue;

      final start = match.start;
      final windowStart = (start - 40).clamp(0, normalized.length);
      final windowEnd = (match.end + 40).clamp(0, normalized.length);
      final window = normalized.substring(windowStart, windowEnd);

      final isFeeContext = ReceiptOcrTextUtils.containsAny(window, const [
        'SERVICE CHARGE',
        'SERVICE FEE',
        'DISASTER RECOVERY',
        'VAT (',
        'VAT(',
      ]);
      final isTotalDebited = window.contains('TOTAL AMOUNT DEBITED') ||
          window.contains('TOTAL DEBITED');

      if (isFeeContext) continue;
      if (isTotalDebited) continue;

      return _CbeAmountResult(amount: amount, fromDebitSentence: false);
    }

    return null;
  }

  static double _calcConfidence({
    required bool hasMarker,
    required _CbeRefResult? reference,
    required _CbeAmountResult? amount,
    required bool layoutMatched,
  }) {
    if (reference == null && amount == null) return 0.0;

    // Strong screenshot layout: labeled FT + debit amount.
    if (reference != null &&
        amount != null &&
        (reference.fromLabeledId || hasMarker) &&
        amount.fromDebitSentence) {
      return reference.corrected ? 0.88 : 0.95;
    }

    // Both fields with known layout signals.
    if (reference != null && amount != null && layoutMatched) {
      return reference.corrected ? 0.82 : 0.90;
    }

    // Labeled ID alone (crop / partial OCR) — still pass UI threshold.
    if (reference != null && reference.fromLabeledId) {
      return reference.corrected ? 0.62 : 0.70;
    }

    // Debit amount alone on a CBE-marked receipt.
    if (amount != null && amount.fromDebitSentence && hasMarker) {
      return 0.65;
    }

    // Bare FT + amount without strong labels.
    if (reference != null && amount != null) {
      return 0.70;
    }

    // Bare FT only.
    if (reference != null && hasMarker) {
      return 0.55;
    }

    return layoutMatched ? 0.50 : 0.20;
  }

  static ReceiptOcrResult _empty(String rawText) {
    return ReceiptOcrResult(
      reference: null,
      amount: null,
      rawText: rawText,
      provider: PaymentProvider.cbe.apiValue,
      confidence: 0.0,
    );
  }
}

class _CbeRefResult {
  const _CbeRefResult({
    required this.reference,
    required this.corrected,
    required this.fromLabeledId,
  });

  final String reference;
  final bool corrected;
  final bool fromLabeledId;
}

class _CbeAmountResult {
  const _CbeAmountResult({
    required this.amount,
    required this.fromDebitSentence,
  });

  final String amount;
  final bool fromDebitSentence;
}
