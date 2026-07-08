import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/current_game_operations_provider.dart';

bool isRegistrationClosedError(ApiException error) {
  return error.code == 'REGISTRATION_CLOSED' ||
      error.code == 'BIG_GAME_REGISTRATION_CLOSED' ||
      (error.message.toLowerCase().contains('registration') &&
          error.message.toLowerCase().contains('closed'));
}

bool isSessionNotReadyError(ApiException error) {
  return error.code == 'SESSION_NOT_READY';
}

String registrationWindowClosedMessage(BuildContext context, ApiException error) {
  final l10n = context.l10n;
  if (isSessionNotReadyError(error)) {
    return l10n.registrationClosedPreparing;
  }
  return l10n.registrationClosedPreparing;
}

Future<void> handleRegistrationWindowClosed(
  WidgetRef ref, {
  required BuildContext context,
  ApiException? error,
}) async {
  await ref.read(currentGameOperationsProvider.notifier).refresh();

  if (!context.mounted) {
    return;
  }

  final message = error == null
      ? context.l10n.registrationClosedPreparing
      : registrationWindowClosedMessage(context, error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<void> handleRegistrationApiError(
  WidgetRef ref, {
  required BuildContext context,
  required Object error,
}) async {
  if (error is! ApiException) {
    return;
  }

  if (!isRegistrationClosedError(error) && !isSessionNotReadyError(error)) {
    return;
  }

  await ref.read(currentGameOperationsProvider.notifier).refresh();

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(registrationWindowClosedMessage(context, error))),
  );
}
