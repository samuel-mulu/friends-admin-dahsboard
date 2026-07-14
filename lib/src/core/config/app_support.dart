/// Support contact details and legal copy shown in the app drawer.
abstract final class AppSupport {
  static const contactTitle = 'Contact us';
  static const termsTitle = 'Terms and conditions';

  /// Display format shown in the drawer and support modals.
  static const supportPhoneDisplays = ['0961355799', '0952723287'];

  static String get supportPhoneDisplay => supportPhoneDisplays.join(' / ');

  /// Dialable phone URIs (Ethiopia +251).
  static const supportPhoneUris = [
    'tel:+251961355799',
    'tel:+251952723287',
  ];

  /// Telegram handle without @.
  static const telegramUsername = 'friendsbingo';

  static Uri get telegramUri => Uri.parse('https://t.me/$telegramUsername');

  static const developerName = '2ms developers';
  static const developerTelegramUsername = 'samimulu1';

  static Uri get developerTelegramUri =>
      Uri.parse('https://t.me/$developerTelegramUsername');

  static const termsBody = '''
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
''';
}
