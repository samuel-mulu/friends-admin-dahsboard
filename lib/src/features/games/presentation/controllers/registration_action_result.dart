import '../../domain/cartela_availability.dart';

enum RegistrationLimitKind { bonus, bigGotd, normal }

/// Non-UI outcome from registration controller actions.
sealed class RegistrationActionResult {
  const RegistrationActionResult();
}

final class RegistrationActionSuccess extends RegistrationActionResult {
  const RegistrationActionSuccess({this.resolvedSessionId});

  final String? resolvedSessionId;
}

final class RegistrationActionIgnored extends RegistrationActionResult {
  const RegistrationActionIgnored();
}

final class RegistrationGuestRequired extends RegistrationActionResult {
  const RegistrationGuestRequired();
}

final class RegistrationInsufficientBalance extends RegistrationActionResult {
  const RegistrationInsufficientBalance({
    required this.maxAffordable,
    required this.limitKind,
  });

  final int? maxAffordable;
  final RegistrationLimitKind limitKind;
}

final class RegistrationCartelaUnavailable extends RegistrationActionResult {
  const RegistrationCartelaUnavailable();
}

final class RegistrationValidationError extends RegistrationActionResult {
  const RegistrationValidationError({this.message});

  final String? message;
}

final class RegistrationNetworkError extends RegistrationActionResult {
  const RegistrationNetworkError({required this.message});

  final String message;
}

final class RegistrationReserveFlushCancelled extends RegistrationActionResult {
  const RegistrationReserveFlushCancelled();
}

/// Input for toggling a cartela in bulk select mode.
class RegistrationCartelaSelectionInput {
  const RegistrationCartelaSelectionInput({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.availability,
  });

  final String cartelaId;
  final int cartelaNumber;
  final CartelaAvailability availability;
}
