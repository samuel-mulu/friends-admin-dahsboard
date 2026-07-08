import '../../../../../l10n/app_localizations.dart';
import '../../data/models/payment_provider.dart';

class DepositGuideStep {
  const DepositGuideStep({required this.imageAsset, required this.label});

  final String imageAsset;
  final String Function(AppLocalizations l10n) label;
}

String depositGuideAssetPath(PaymentProvider provider, int step) {
  final folder = switch (provider) {
    PaymentProvider.telebirr => 'telebirr',
    PaymentProvider.cbe => 'cbe',
    PaymentProvider.awash => 'awash',
    PaymentProvider.boa => 'boa',
  };
  final extension = switch (provider) {
    PaymentProvider.awash => 'png',
    PaymentProvider.telebirr ||
    PaymentProvider.cbe ||
    PaymentProvider.boa => 'webp',
  };
  return 'assets/deposit_guides/$folder/step_$step.$extension';
}

List<DepositGuideStep> depositGuideStepsFor(PaymentProvider provider) {
  return switch (provider) {
    PaymentProvider.telebirr => [
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 1),
        label: (l10n) => l10n.depositGuideTelebirrStep1,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 2),
        label: (l10n) => l10n.depositGuideTelebirrStep2,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 3),
        label: (l10n) => l10n.depositGuideTelebirrStep3,
      ),
    ],
    PaymentProvider.cbe => [
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 1),
        label: (l10n) => l10n.depositGuideCbeStep1,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 2),
        label: (l10n) => l10n.depositGuideCbeStep2,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 3),
        label: (l10n) => l10n.depositGuideCbeStep3,
      ),
    ],
    PaymentProvider.awash => [
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 1),
        label: (l10n) => l10n.depositGuideAwashStep1,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 2),
        label: (l10n) => l10n.depositGuideAwashStep2,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 3),
        label: (l10n) => l10n.depositGuideAwashStep3,
      ),
    ],
    PaymentProvider.boa => [
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 1),
        label: (l10n) => l10n.depositGuideBoaStep1,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 2),
        label: (l10n) => l10n.depositGuideBoaStep2,
      ),
      DepositGuideStep(
        imageAsset: depositGuideAssetPath(provider, 3),
        label: (l10n) => l10n.depositGuideBoaStep3,
      ),
    ],
  };
}
