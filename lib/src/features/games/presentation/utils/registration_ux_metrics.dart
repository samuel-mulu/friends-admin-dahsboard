import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';

/// Lightweight debug metrics for registration UX tuning (Phase 4).
abstract final class RegistrationUxMetrics {
  static const _scope = 'registration_ux';

  static int _modalOpenCount = 0;
  static int _reserveSuccessCount = 0;
  static int _reserveFailureCount = 0;
  static int _socketPatchCount = 0;
  static int _snapshotRefetchCount = 0;
  static int _bulkReserveFailureCount = 0;

  static void modalOpened() {
    _modalOpenCount++;
    _log('modal_opened total=$_modalOpenCount');
  }

  static void reserveSuccess({required Duration elapsed}) {
    _reserveSuccessCount++;
    _log(
      'reserve_success total=$_reserveSuccessCount elapsed_ms=${elapsed.inMilliseconds}',
    );
  }

  static void reserveFailure({String? reason}) {
    _reserveFailureCount++;
    _log(
      'reserve_failure total=$_reserveFailureCount reason=${reason ?? 'unknown'}',
    );
  }

  static void bulkReserveFailure({required int cartelaCount}) {
    _bulkReserveFailureCount++;
    _log(
      'bulk_reserve_failure total=$_bulkReserveFailureCount cartelas=$cartelaCount',
    );
  }

  static void socketPatchApplied({required int changeCount}) {
    _socketPatchCount += changeCount;
    _log(
      'socket_patch_applied changes=$changeCount total=$_socketPatchCount',
    );
  }

  static void snapshotRefetchScheduled({required String reason}) {
    _snapshotRefetchCount++;
    _log(
      'snapshot_refetch_scheduled total=$_snapshotRefetchCount reason=$reason',
    );
  }

  static void _log(String message) {
    if (kDebugMode) {
      AppLogger.debug(_scope, message);
    }
  }
}
