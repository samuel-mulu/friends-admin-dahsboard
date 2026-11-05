import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deposits/application/controllers/deposit_controller.dart';
import '../../withdrawals/application/controllers/withdraw_controller.dart';

/// Consumes a back action when deposit/withdraw is past provider selection.
///
/// Returns `true` when the provider-chooser step was restored (route stays).
bool tryConsumeWalletProviderStepBack({
  required ProviderContainer container,
  required String location,
}) {
  if (location == '/wallet/deposit') {
    final state = container.read(depositControllerProvider);
    if (!state.isChoosingProvider && state.provider != null) {
      container.read(depositControllerProvider.notifier).changeProvider();
      return true;
    }
    return false;
  }

  if (location == '/wallet/withdraw') {
    final state = container.read(withdrawControllerProvider);
    if (!state.isChoosingProvider && state.provider != null) {
      container.read(withdrawControllerProvider.notifier).changeProvider();
      return true;
    }
    return false;
  }

  return false;
}
