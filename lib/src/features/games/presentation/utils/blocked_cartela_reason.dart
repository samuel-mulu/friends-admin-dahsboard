import '../../../../core/utils/l10n.dart';
import 'package:flutter/widgets.dart';

String blockedCartelaReasonMessage(
  BuildContext context, {
  String? reasonCode,
  String? serverReason,
}) {
  final l10n = context.l10n;
  switch (reasonCode) {
    case 'INVALID_LATE_CLAIM':
      return l10n.cartelaBlockedReasonLate;
    case 'INVALID_PATTERN':
      return l10n.cartelaBlockedReasonPattern;
    default:
      final trimmed = serverReason?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
      return l10n.cartelaBlockedReasonGeneric;
  }
}
