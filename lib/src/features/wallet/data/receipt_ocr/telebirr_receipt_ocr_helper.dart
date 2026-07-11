import '../models/payment_provider.dart';
import 'receipt_ocr_result.dart';
import 'receipt_ocr_text_utils.dart';

/// Parses Telebirr app success-screen screenshots.
///
/// Expected layout:
/// - Amount as `-11.00 (ETB)` / `11.00 (ETB)` (whole-birr style)
/// - Reference after `Transaction Number:` starting with `D`, often far right
class TelebirrReceiptOcrHelper {
  const TelebirrReceiptOcrHelper._();

  static final RegExp _transactionNumberLabel = RegExp(
    r'TRANSACTION\s*NUMBER\s*[:\-]?\s*',
  );

  static final RegExp _dReference = RegExp(r'\bD[A-Z0-9]{7,15}\b');

  /// Display amount forms: `-11.00 (ETB)`, `11.00(ETB)`, `ETB 11`, `11 ETB`
  static final RegExp _parenEtbAmount = RegExp(
    r'(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*\(\s*ETB\s*\)',
  );
  static final RegExp _etbPrefix = RegExp(
    r'ETB\s*(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)',
  );
  static final RegExp _etbSuffix = RegExp(
    r'(-?\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*ETB\b',
  );

  static ReceiptOcrResult parse(String rawText) {
    final normalized = ReceiptOcrTextUtils.normalize(rawText);
    if (normalized.isEmpty) {
      return ReceiptOcrResult(
        reference: null,
        amount: null,
        rawText: rawText,
        provider: PaymentProvider.telebirr.apiValue,
        confidence: 0.0,
      );
    }

    final refResult = _detectReference(normalized);
    final amountResult = _detectAmount(normalized);

    final confidence = _calcConfidence(
      reference: refResult,
      amount: amountResult,
    );

    return ReceiptOcrResult(
      reference: refResult?.reference,
      amount: amountResult?.amount,
      rawText: rawText,
      provider: PaymentProvider.telebirr.apiValue,
      confidence: confidence,
    );
  }

  static _TelebirrRefResult? _detectReference(String normalized) {
    final labelMatch = _transactionNumberLabel.firstMatch(normalized);
    if (labelMatch != null) {
      // Wide window: label left, value far right on same line / nearby.
      final contextStart = labelMatch.end;
      final context = normalized.substring(
        contextStart,
        (contextStart + 120).clamp(0, normalized.length),
      );

      final labeled = _dReference.firstMatch(context);
      if (labeled != null) {
        final raw = labeled.group(0)!;
        final corrected = ReceiptOcrTextUtils.applyOcrCorrections(raw);
        return _TelebirrRefResult(
          reference: corrected,
          corrected: corrected != raw,
          fromLabeledNumber: true,
        );
      }
    }

    final bare = _dReference.firstMatch(normalized);
    if (bare != null) {
      final raw = bare.group(0)!;
      final corrected = ReceiptOcrTextUtils.applyOcrCorrections(raw);
      return _TelebirrRefResult(
        reference: corrected,
        corrected: corrected != raw,
        fromLabeledNumber: false,
      );
    }

    return null;
  }

  static _TelebirrAmountResult? _detectAmount(String normalized) {
    final candidates = <_TelebirrAmountResult>[];

    void addMatch(RegExp pattern, {required bool parenEtb}) {
      for (final match in pattern.allMatches(normalized)) {
        final raw = match.group(1);
        if (raw == null) continue;

        // Absolute value: Telebirr shows negative for outgoing transfers.
        final absRaw = raw.startsWith('-') ? raw.substring(1) : raw;
        final amount = ReceiptOcrTextUtils.normalizeAmount(absRaw);
        if (amount == null) continue;

        final start = match.start;
        final windowStart = (start - 30).clamp(0, normalized.length);
        final windowEnd = (match.end + 30).clamp(0, normalized.length);
        final window = normalized.substring(windowStart, windowEnd);

        if (ReceiptOcrTextUtils.containsAny(window, const [
          'SERVICE CHARGE',
          'SERVICE FEE',
          'VAT',
          'FEE',
          'CHARGE',
        ])) {
          continue;
        }

        final parsed = double.parse(amount);
        final isWholeBirr = parsed == parsed.roundToDouble();

        candidates.add(
          _TelebirrAmountResult(
            amount: amount,
            fromParenEtb: parenEtb,
            isWholeBirr: isWholeBirr,
            index: start,
          ),
        );
      }
    }

    addMatch(_parenEtbAmount, parenEtb: true);
    addMatch(_etbPrefix, parenEtb: false);
    addMatch(_etbSuffix, parenEtb: false);

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      // Prefer (ETB) display amount, then whole-birr, then earliest.
      final byParen = (b.fromParenEtb ? 1 : 0).compareTo(a.fromParenEtb ? 1 : 0);
      if (byParen != 0) return byParen;
      final byWhole = (b.isWholeBirr ? 1 : 0).compareTo(a.isWholeBirr ? 1 : 0);
      if (byWhole != 0) return byWhole;
      return a.index.compareTo(b.index);
    });

    return candidates.first;
  }

  static double _calcConfidence({
    required _TelebirrRefResult? reference,
    required _TelebirrAmountResult? amount,
  }) {
    if (reference == null && amount == null) return 0.0;

    // Strong screenshot layout: labeled D* + whole-birr (ETB) amount.
    if (reference != null &&
        amount != null &&
        reference.fromLabeledNumber &&
        (amount.fromParenEtb || amount.isWholeBirr)) {
      return reference.corrected ? 0.88 : 0.95;
    }

    if (reference != null && amount != null) {
      return reference.corrected ? 0.80 : 0.88;
    }

    // Labeled Transaction Number alone — pass UI threshold.
    if (reference != null && reference.fromLabeledNumber) {
      return reference.corrected ? 0.62 : 0.70;
    }

    // Whole-birr paren amount alone.
    if (amount != null && amount.fromParenEtb && amount.isWholeBirr) {
      return 0.65;
    }

    if (reference != null) {
      return 0.55;
    }

    if (amount != null && amount.isWholeBirr) {
      return 0.55;
    }

    return 0.30;
  }
}

class _TelebirrRefResult {
  const _TelebirrRefResult({
    required this.reference,
    required this.corrected,
    required this.fromLabeledNumber,
  });

  final String reference;
  final bool corrected;
  final bool fromLabeledNumber;
}

class _TelebirrAmountResult {
  const _TelebirrAmountResult({
    required this.amount,
    required this.fromParenEtb,
    required this.isWholeBirr,
    required this.index,
  });

  final String amount;
  final bool fromParenEtb;
  final bool isWholeBirr;
  final int index;
}
