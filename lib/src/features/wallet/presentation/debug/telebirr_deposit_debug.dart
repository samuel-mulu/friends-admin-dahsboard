import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';

/// Opt-in console tracing for Telebirr deposit verification on device.
///
/// Enable when running locally or on a device:
/// ```bash
/// flutter run \
///   --dart-define=API_BASE_URL=https://friendsbingo.onrender.com \
///   --dart-define=DEBUG=true
/// ```
///
/// Also enabled by `TELEBIRR_DEPOSIT_DEBUG=true` or `REALTIME_DEBUG=true` in
/// debug builds.
class TelebirrDepositDebug {
  TelebirrDepositDebug._();

  static const _debugEnabled = bool.fromEnvironment('DEBUG');
  static const _telebirrEnabled = bool.fromEnvironment(
    'TELEBIRR_DEPOSIT_DEBUG',
  );
  static const _realtimeEnabled = bool.fromEnvironment('REALTIME_DEBUG');

  static bool get isEnabled =>
      kDebugMode && (_debugEnabled || _telebirrEnabled || _realtimeEnabled);

  static void log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('Telebirr deposit', message);
  }

  static void preview({
    required String transactionRef,
    required String status,
    String? settledAmount,
    String? totalPaidAmount,
    String? creditedPartyName,
    String? creditedPartyAccountNo,
    String? transactionStatus,
    String? message,
  }) {
    if (!isEnabled) {
      return;
    }

    log(
      'preview ref=${maskRef(transactionRef)} status=$status '
      'hasSettled=${settledAmount != null} hasTotalPaid=${totalPaidAmount != null} '
      'hasReceiverName=${creditedPartyName?.isNotEmpty == true} '
      'hasReceiverAccount=${creditedPartyAccountNo?.isNotEmpty == true} '
      'receiptStatus=${transactionStatus ?? 'unknown'} '
      'hasMessage=${message?.isNotEmpty == true}',
    );
  }

  static void checkRefRequest({
    required String transactionRef,
    required String amount,
    required String receiptParseStatus,
    Map<String, dynamic>? clientReceipt,
  }) {
    if (!isEnabled) {
      return;
    }

    log(
      'check-ref request ref=${maskRef(transactionRef)} amountSet=${amount.isNotEmpty} '
      'receiptParseStatus=$receiptParseStatus hasClientReceipt=${clientReceipt != null}',
    );
  }

  static void checkRefResponse({
    required String code,
    required String message,
  }) {
    if (!isEnabled) {
      return;
    }

    log('check-ref response code=$code hasMessage=${message.isNotEmpty}');
  }

  static void createRequest({
    required String transactionRef,
    required String amount,
    required String receiptParseStatus,
    Map<String, dynamic>? clientReceipt,
  }) {
    if (!isEnabled) {
      return;
    }

    log(
      'create request ref=${maskRef(transactionRef)} amountSet=${amount.isNotEmpty} '
      'receiptParseStatus=$receiptParseStatus hasClientReceipt=${clientReceipt != null}',
    );
  }

  static void createResponse({
    required String depositId,
    required String status,
    String? rejectionReason,
  }) {
    if (!isEnabled) {
      return;
    }

    log(
      'create response id=${AppLogger.shortIdentifier(depositId)} status=$status '
      'hasRejectionReason=${rejectionReason?.isNotEmpty == true}',
    );
  }

  static void error(String stage, Object error) {
    if (!isEnabled) {
      return;
    }

    log('$stage error=$error');
  }

  static String maskRef(String transactionRef) {
    return AppLogger.maskIdentifier(transactionRef, suffixLength: 4);
  }
}
