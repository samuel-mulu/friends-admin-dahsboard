import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/registration_draft.dart';

enum RegisterStep { details, otp }

class RegisterStepNotifier extends Notifier<RegisterStep> {
  @override
  RegisterStep build() => RegisterStep.details;

  void showDetails() => state = RegisterStep.details;

  void showOtp() => state = RegisterStep.otp;
}

final registerStepProvider =
    NotifierProvider<RegisterStepNotifier, RegisterStep>(
      RegisterStepNotifier.new,
    );

class RegistrationDraftNotifier extends Notifier<RegistrationDraft?> {
  @override
  RegistrationDraft? build() => null;

  void save(RegistrationDraft draft) => state = draft;

  void clear() => state = null;
}

final registrationDraftProvider =
    NotifierProvider<RegistrationDraftNotifier, RegistrationDraft?>(
      RegistrationDraftNotifier.new,
    );

enum ForgotPasswordStep { phone, reset }

class ForgotPasswordStepNotifier extends Notifier<ForgotPasswordStep> {
  @override
  ForgotPasswordStep build() => ForgotPasswordStep.phone;

  void showPhone() => state = ForgotPasswordStep.phone;

  void showReset() => state = ForgotPasswordStep.reset;
}

final forgotPasswordStepProvider =
    NotifierProvider<ForgotPasswordStepNotifier, ForgotPasswordStep>(
      ForgotPasswordStepNotifier.new,
    );

class PasswordResetPhoneNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void save(String phoneNumber) => state = phoneNumber;

  void clear() => state = null;
}

final passwordResetPhoneProvider =
    NotifierProvider<PasswordResetPhoneNotifier, String?>(
      PasswordResetPhoneNotifier.new,
    );
