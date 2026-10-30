import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/controllers/deposit_controller.dart';

/// When a payment provider is already selected, back should return to the
/// provider list on the same deposit screen — not leave `/wallet/deposit`.
///
/// Returns `true` if the back action was consumed.
bool tryDepositInFlowBack(ProviderContainer container) {
  final state = container.read(depositControllerProvider);
  if (state.isChoosingProvider || state.provider == null) {
    return false;
  }
  container.read(depositControllerProvider.notifier).changeProvider();
  return true;
}
