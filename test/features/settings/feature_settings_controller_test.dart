import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/settings/domain/feature_settings.dart';

void main() {
  group('FeatureSettings visibility', () {
    test('no grants hides both switches', () {
      const ui = FeatureSettingsUiState();
      expect(ui.showAutoMark, isFalse);
      expect(ui.showAutoBingo, isFalse);
      expect(ui.settings.hasAnyGrant, isFalse);
    });

    test('Auto Mark grant only shows Mark switch', () {
      const ui = FeatureSettingsUiState(
        settings: FeatureSettings(autoMarkGranted: true),
      );
      expect(ui.showAutoMark, isTrue);
      expect(ui.showAutoBingo, isFalse);
      expect(ui.settings.autoMarkEnabled, isFalse);
    });

    test('Auto Bingo grant only shows Bingo switch', () {
      const ui = FeatureSettingsUiState(
        settings: FeatureSettings(autoBingoGranted: true),
      );
      expect(ui.showAutoMark, isFalse);
      expect(ui.showAutoBingo, isTrue);
      expect(ui.settings.autoBingoEnabled, isFalse);
    });

    test('both grants show both switches initially OFF', () {
      const ui = FeatureSettingsUiState(
        settings: FeatureSettings(
          autoMarkGranted: true,
          autoBingoGranted: true,
        ),
      );
      expect(ui.showAutoMark, isTrue);
      expect(ui.showAutoBingo, isTrue);
      expect(ui.settings.autoMarkEnabled, isFalse);
      expect(ui.settings.autoBingoEnabled, isFalse);
    });
  });

  group('FeatureSettings.takeIfNewer', () {
    test('rejects older versions (out-of-order socket)', () {
      const current = FeatureSettings(
        autoMarkGranted: true,
        autoMarkEnabled: true,
        featureSettingsVersion: 5,
      );
      const older = FeatureSettings(
        autoMarkGranted: false,
        autoMarkEnabled: false,
        featureSettingsVersion: 4,
      );

      expect(
        FeatureSettings.takeIfNewer(current: current, incoming: older),
        isNull,
      );
    });

    test('accepts newer revocation and forces effective OFF', () {
      const current = FeatureSettings(
        autoMarkGranted: true,
        autoMarkEnabled: true,
        effectiveAutoMark: true,
        featureSettingsVersion: 2,
      );
      const revoked = FeatureSettings(
        autoMarkGranted: false,
        autoMarkEnabled: false,
        effectiveAutoMark: false,
        featureSettingsVersion: 3,
      );

      final accepted = FeatureSettings.takeIfNewer(
        current: current,
        incoming: revoked,
      );
      expect(accepted, isNotNull);
      expect(accepted!.autoMarkGranted, isFalse);
      expect(accepted.autoMarkEnabled, isFalse);
      expect(accepted.effectiveAutoMark, isFalse);
      expect(accepted.featureSettingsVersion, 3);
    });

    test('accepts equal version idempotently', () {
      const current = FeatureSettings(
        autoBingoGranted: true,
        autoBingoEnabled: true,
        featureSettingsVersion: 8,
      );
      const same = FeatureSettings(
        autoBingoGranted: true,
        autoBingoEnabled: true,
        featureSettingsVersion: 8,
      );

      expect(
        FeatureSettings.takeIfNewer(current: current, incoming: same),
        same,
      );
    });
  });

  group('FeatureSettings.fromJson', () {
    test('defaults missing keys to false / zero', () {
      final settings = FeatureSettings.fromJson(const {});
      expect(settings.autoMarkGranted, isFalse);
      expect(settings.autoBingoGranted, isFalse);
      expect(settings.autoMarkEnabled, isFalse);
      expect(settings.autoBingoEnabled, isFalse);
      expect(settings.featureSettingsVersion, 0);
    });

    test('parses independent grants and prefs', () {
      final settings = FeatureSettings.fromJson(const {
        'autoMarkGranted': true,
        'autoBingoGranted': false,
        'autoMarkEnabled': true,
        'autoBingoEnabled': true,
        'effectiveAutoMark': true,
        'effectiveAutoBingo': false,
        'featureSettingsVersion': 11,
      });

      expect(settings.autoMarkGranted, isTrue);
      expect(settings.autoBingoGranted, isFalse);
      expect(settings.autoMarkEnabled, isTrue);
      expect(settings.effectiveAutoMark, isTrue);
      expect(settings.effectiveAutoBingo, isFalse);
      expect(settings.featureSettingsVersion, 11);
    });
  });

  group('pending UI state', () {
    test('pending flags disable only the in-flight switch', () {
      const ui = FeatureSettingsUiState(
        settings: FeatureSettings(
          autoMarkGranted: true,
          autoBingoGranted: true,
        ),
        autoMarkPending: true,
      );

      expect(ui.autoMarkPending, isTrue);
      expect(ui.autoBingoPending, isFalse);
      expect(ui.showAutoMark, isTrue);
      expect(ui.showAutoBingo, isTrue);
    });
  });
}
