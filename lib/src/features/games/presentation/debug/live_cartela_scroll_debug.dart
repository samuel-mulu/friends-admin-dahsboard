import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';

/// Opt-in tracing for live cartela scroll / rebuild jank.
///
/// In `.env` set `CARTELA_SCROLL_DEBUG=true`, then:
/// `flutter run --dart-define-from-file=.env`
///
/// Watch console for tag `[CartelaScroll]`. On scroll end you get a summary
/// of full-screen rebuilds vs grid-only updates during that gesture.
class LiveCartelaScrollDebug {
  LiveCartelaScrollDebug._();

  static bool get isEnabled {
    if (!kDebugMode) {
      return false;
    }
    try {
      final config = AppConfig.fromEnvironment();
      return config.cartelaScrollDebug || config.realtimeDebug;
    } catch (_) {
      return false;
    }
  }

  static int _fullScreenRebuilds = 0;
  static int _gridRevisions = 0;
  static int _playListBuilds = 0;
  static int _sortEvalRuns = 0;
  static int _sortEvalSkipped = 0;
  static int _calledNumbersDirty = 0;
  static int _scrollUpdates = 0;
  static bool _inScrollGesture = false;
  static DateTime? _lastScrollUpdateLogAt;

  static void _log(String message) {
    if (!isEnabled) {
      return;
    }
    AppLogger.debug('CartelaScroll', message);
  }

  /// Ad-hoc trace line (same as internal [_log]).
  static void log(String message) => _log(message);

  static void fullScreenRebuild({String? reason}) {
    if (!isEnabled) {
      return;
    }
    if (_inScrollGesture) {
      _fullScreenRebuilds++;
    }
    final suffix = reason == null ? '' : ' reason=$reason';
    _log('full_screen_setState$suffix (duringScroll=$_inScrollGesture)');
  }

  static void calledNumbersDirty({
    required int calledCount,
    int? latestBall,
    required bool autoMark,
    required bool fullGrid,
  }) {
    if (!isEnabled) {
      return;
    }
    if (_inScrollGesture) {
      _calledNumbersDirty++;
    }
    _log(
      'called_numbers_dirty called=$calledCount ball=${latestBall ?? '-'} '
      'autoMark=$autoMark fullGrid=$fullGrid duringScroll=$_inScrollGesture',
    );
  }

  static void sortEval({required bool signatureChanged, required int cartelaCount}) {
    if (!isEnabled) {
      return;
    }
    if (signatureChanged) {
      _sortEvalRuns++;
      _log('sort_eval ran cartelas=$cartelaCount');
    } else {
      _sortEvalSkipped++;
    }
  }

  static void storeGridUpdate({
    required int gridRevision,
    int? ballNumber,
    required bool fullGrid,
    required int tilesBumped,
  }) {
    if (!isEnabled) {
      return;
    }
    if (_inScrollGesture) {
      _gridRevisions++;
    }
    _log(
      'grid_update rev=$gridRevision ball=${ballNumber ?? '-'} '
      'fullGrid=$fullGrid tilesBumped=$tilesBumped duringScroll=$_inScrollGesture',
    );
  }

  static void playListBuild({required int cartelaCount, required String source}) {
    if (!isEnabled) {
      return;
    }
    _playListBuilds++;
    _log(
      'play_list_build cartelas=$cartelaCount source=$source '
      'totalBuilds=$_playListBuilds duringScroll=$_inScrollGesture',
    );
  }

  static void scrollStart() {
    if (!isEnabled) {
      return;
    }
    _inScrollGesture = true;
    _fullScreenRebuilds = 0;
    _gridRevisions = 0;
    _calledNumbersDirty = 0;
    _scrollUpdates = 0;
    _log('scroll_start');
  }

  static void scrollUpdate({required double pixels, required double maxExtent}) {
    if (!isEnabled || !_inScrollGesture) {
      return;
    }
    _scrollUpdates++;
    final now = DateTime.now();
    if (_lastScrollUpdateLogAt != null &&
        now.difference(_lastScrollUpdateLogAt!) <
            const Duration(milliseconds: 400)) {
      return;
    }
    _lastScrollUpdateLogAt = now;
    _log(
      'scroll_update px=${pixels.toStringAsFixed(0)} '
      'max=${maxExtent.toStringAsFixed(0)} updates=$_scrollUpdates',
    );
  }

  static void scrollEnd() {
    if (!isEnabled) {
      return;
    }
    _log(
      'scroll_end summary: fullScreenRebuilds=$_fullScreenRebuilds '
      'gridUpdates=$_gridRevisions calledDirty=$_calledNumbersDirty '
      'scrollUpdates=$_scrollUpdates '
      '(lifetime playListBuilds=$_playListBuilds sortEval=$_sortEvalRuns '
      'sortSkipped=$_sortEvalSkipped)',
    );
    _inScrollGesture = false;
    _lastScrollUpdateLogAt = null;
  }

  static void deferredSortApplied() {
    _log('deferred_sort_order_applied');
  }

  static void sortDisplayDeferred() {
    _log('sort_display_deferred until scroll idle');
  }
}
