import 'live_called_numbers_controller.dart';
import 'live_countdown_controller.dart';
import 'live_game_host.dart';
import 'live_realtime_controller.dart';
import 'live_registration_controller.dart';
import 'live_review_controller.dart';
import 'live_transition_controller.dart';
import 'missed_preview_controller.dart';
import '../utils/next_ball_stale_guard.dart';

/// Owns the six live-screen controllers with a single dispose entry point.
class LiveGameControllers {
  LiveGameControllers(
    LiveGameHost host, {
    NextBallStaleGuard? nextBallStaleGuard,
  })  : transition = LiveTransitionController(host),
        countdown = LiveCountdownController(
          host,
          nextBallStaleGuard: nextBallStaleGuard,
        ),
        realtime = LiveRealtimeController(host),
        review = LiveReviewController(host),
        registration = LiveRegistrationController(host),
        calledNumbers = LiveCalledNumbersController(host),
        missedPreview = MissedPreviewController(host);

  final LiveTransitionController transition;
  final LiveCountdownController countdown;
  final LiveRealtimeController realtime;
  final LiveReviewController review;
  final LiveRegistrationController registration;
  final LiveCalledNumbersController calledNumbers;
  final MissedPreviewController missedPreview;

  void dispose() {
    transition.dispose();
    countdown.dispose();
    realtime.dispose();
    review.dispose();
    registration.dispose();
    calledNumbers.dispose();
    missedPreview.dispose();
  }
}
