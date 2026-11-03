import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationCashbackCelebrationState {
  const RegistrationCashbackCelebrationState({
    this.amount,
    this.sessionQualifyingCount,
    this.eventId = 0,
  });

  final String? amount;
  final int? sessionQualifyingCount;
  final int eventId;

  bool get isVisible =>
      amount != null &&
      amount!.isNotEmpty &&
      sessionQualifyingCount != null &&
      sessionQualifyingCount! > 0;
}

class RegistrationCashbackCelebrationNotifier
    extends Notifier<RegistrationCashbackCelebrationState> {
  @override
  RegistrationCashbackCelebrationState build() {
    return const RegistrationCashbackCelebrationState();
  }

  void showFromSocket({
    required String amount,
    required int sessionQualifyingCount,
  }) {
    state = RegistrationCashbackCelebrationState(
      amount: amount,
      sessionQualifyingCount: sessionQualifyingCount,
      eventId: state.eventId + 1,
    );
  }

  void dismiss() {
    state = const RegistrationCashbackCelebrationState();
  }
}

final registrationCashbackCelebrationProvider = NotifierProvider<
    RegistrationCashbackCelebrationNotifier,
    RegistrationCashbackCelebrationState>(
  RegistrationCashbackCelebrationNotifier.new,
);
