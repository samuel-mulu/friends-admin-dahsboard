/// Support contact details and legal copy shown in the app drawer.
abstract final class AppSupport {
  static const contactTitle = 'Contact us';
  static const termsTitle = 'Terms and conditions';

  static const developerName = '2ms developers';
  static const developerTelegramUsername = 'samimulu1';

  static Uri get developerTelegramUri =>
      Uri.parse('https://t.me/$developerTelegramUsername');
}

/// Dynamic Contact Us / Terms content from the API, with local fallbacks.
class AppSupportConfig {
  const AppSupportConfig({
    required this.phoneNumber1,
    required this.phoneNumber2,
    required this.telegramUsername,
    required this.termsBody,
  });

  static const fallback = AppSupportConfig(
    phoneNumber1: '0961355799',
    phoneNumber2: '0983299318',
    telegramUsername: 'friendschewata',
    termsBody: '''
Friends Bingo – Terms and Conditions

1. Eligibility
You must meet the legal age and local requirements to play bingo games and use wallet features in your region.

2. Accounts
You are responsible for keeping your login details secure. One account per player unless approved by support.

3. Wallet and payments
Deposits and withdrawals are processed according to admin verification rules. Incorrect payment details may delay payouts.

4. Gameplay
Cartela registration, live calls, and bingo claims follow the active game rules shown before each round. Invalid claims may be rejected.

5. Fair play
Abuse, automation, collusion, or attempts to manipulate game outcomes may result in account suspension.

6. Support
For help, contact us using the phone number or Telegram link in the app menu.

7. Changes
These terms may be updated. Continued use of the app means you accept the latest version.
''',
  );

  final String phoneNumber1;
  final String phoneNumber2;
  final String telegramUsername;
  final String termsBody;

  List<String> get supportPhoneDisplays {
    return [
      if (phoneNumber1.trim().isNotEmpty) phoneNumber1.trim(),
      if (phoneNumber2.trim().isNotEmpty) phoneNumber2.trim(),
    ];
  }

  List<String> get supportPhoneUris =>
      supportPhoneDisplays.map(toTelUri).toList(growable: false);

  String get supportPhoneDisplay => supportPhoneDisplays.join(' / ');

  Uri get telegramUri => Uri.parse('https://t.me/$telegramUsername');

  factory AppSupportConfig.fromJson(Map<String, dynamic> json) {
    final telegram = (json['telegramUsername'] as String? ?? '').trim().replaceFirst(RegExp(r'^@+'), '');
    return AppSupportConfig(
      phoneNumber1:
          (json['phoneNumber1'] as String? ?? fallback.phoneNumber1).trim(),
      phoneNumber2:
          (json['phoneNumber2'] as String? ?? fallback.phoneNumber2).trim(),
      telegramUsername:
          telegram.isEmpty ? fallback.telegramUsername : telegram,
      termsBody: (json['termsBody'] as String? ?? fallback.termsBody).trim().isEmpty
          ? fallback.termsBody
          : (json['termsBody'] as String).trim(),
    );
  }

  /// Dialable phone URI (Ethiopia +251 when local format is used).
  static String toTelUri(String display) {
    final digits = display.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'tel:';
    }
    if (digits.startsWith('251') && digits.length >= 12) {
      return 'tel:+$digits';
    }
    if (digits.startsWith('0') && digits.length >= 10) {
      return 'tel:+251${digits.substring(1)}';
    }
    if (digits.length == 9) {
      return 'tel:+251$digits';
    }
    return 'tel:+$digits';
  }
}
