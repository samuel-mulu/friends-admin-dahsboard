import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/application/controllers/deposit_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/presentation/deposit_in_flow_back.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';

void main() {
  test('tryDepositInFlowBack returns to choosing provider when selected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(depositControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.telebirr);
    expect(
      container.read(depositControllerProvider).isChoosingProvider,
      isFalse,
    );

    expect(tryDepositInFlowBack(container), isTrue);
    expect(
      container.read(depositControllerProvider).isChoosingProvider,
      isTrue,
    );
    expect(
      container.read(depositControllerProvider).provider,
      PaymentProvider.telebirr,
    );
  });

  test('tryDepositInFlowBack is false while already choosing provider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(depositControllerProvider).isChoosingProvider,
      isTrue,
    );
    expect(tryDepositInFlowBack(container), isFalse);
  });
}
