import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';
import 'app_localizations_ti.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('om'),
    Locale('ti'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Friends Bingo-online'**
  String get appTitle;

  /// Greeting prefix in app bar
  ///
  /// In en, this message translates to:
  /// **'Hi, '**
  String get appBarHi;

  /// Tooltip for the shell header master refresh icon
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get appBarRefreshTooltip;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhone;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'091*******'**
  String get loginPhoneHint;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get loginCreateAccount;

  /// No description provided for @registerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerFullName;

  /// No description provided for @registerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerFullNameHint;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPassword;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPassword;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a verification code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get forgotPasswordBackToSignIn;

  /// No description provided for @otpVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get otpVerifyPhone;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}.'**
  String otpSentTo(String phone);

  /// No description provided for @otpCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get otpCreateAccount;

  /// No description provided for @otpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendCode;

  /// No description provided for @otpResendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendInSeconds(int seconds);

  /// No description provided for @otpResendInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Resend in {minutes} min'**
  String otpResendInMinutes(int minutes);

  /// No description provided for @otpResendInMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {minutes}m {seconds}s'**
  String otpResendInMinutesSeconds(int minutes, int seconds);

  /// No description provided for @otpBackToDetails.
  ///
  /// In en, this message translates to:
  /// **'Back to details'**
  String get otpBackToDetails;

  /// No description provided for @otpEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code.'**
  String get otpEnterCode;

  /// No description provided for @otpSmsBanner.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your phone by SMS.'**
  String get otpSmsBanner;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSmsSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the SMS code sent to {phone}.'**
  String resetPasswordSmsSentTo(String phone);

  /// No description provided for @resetPasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordNewPassword;

  /// No description provided for @resetPasswordConfirmNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get resetPasswordConfirmNew;

  /// No description provided for @resetPasswordConfirmNewHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get resetPasswordConfirmNewHint;

  /// No description provided for @resetPasswordUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetPasswordUpdate;

  /// No description provided for @resetPasswordBackToPhone.
  ///
  /// In en, this message translates to:
  /// **'Back to phone number'**
  String get resetPasswordBackToPhone;

  /// No description provided for @validatorPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get validatorPhoneRequired;

  /// No description provided for @validatorPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get validatorPhoneInvalid;

  /// No description provided for @validatorPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get validatorPasswordLength;

  /// No description provided for @validatorFullNameLength.
  ///
  /// In en, this message translates to:
  /// **'Full name must be at least 3 characters.'**
  String get validatorFullNameLength;

  /// No description provided for @validatorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validatorPasswordMismatch;

  /// No description provided for @validatorAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required.'**
  String get validatorAmountRequired;

  /// No description provided for @validatorAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get validatorAmountInvalid;

  /// No description provided for @validatorAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get validatorAmountPositive;

  /// No description provided for @validatorDepositAmountMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum deposit is {amount} ETB.'**
  String validatorDepositAmountMin(String amount);

  /// No description provided for @validatorDepositAmountMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum deposit is {amount} ETB.'**
  String validatorDepositAmountMax(String amount);

  /// No description provided for @validatorWithdrawAmountMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal is {amount} ETB.'**
  String validatorWithdrawAmountMin(String amount);

  /// No description provided for @validatorWithdrawAmountMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum withdrawal is {amount} ETB.'**
  String validatorWithdrawAmountMax(String amount);

  /// No description provided for @depositAmountRangeHelper.
  ///
  /// In en, this message translates to:
  /// **'Deposit between {min} and {max} ETB.'**
  String depositAmountRangeHelper(String min, String max);

  /// No description provided for @withdrawAmountRangeHelper.
  ///
  /// In en, this message translates to:
  /// **'Withdraw between {min} and {max} ETB. This amount will be locked until admin processes your request.'**
  String withdrawAmountRangeHelper(String min, String max);

  /// No description provided for @validatorTransactionRef.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid transaction reference.'**
  String get validatorTransactionRef;

  /// No description provided for @dashboardHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String dashboardHello(String name);

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the live game, register your cartelas there, and keep an eye on your wallet from one place.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardOpenLiveGame.
  ///
  /// In en, this message translates to:
  /// **'Open live game'**
  String get dashboardOpenLiveGame;

  /// No description provided for @dashboardRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get dashboardRole;

  /// No description provided for @dashboardStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get dashboardStatus;

  /// No description provided for @dashboardWalletSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Wallet snapshot'**
  String get dashboardWalletSnapshot;

  /// No description provided for @dashboardAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance: {amount} ETB'**
  String dashboardAvailableBalance(String amount);

  /// No description provided for @dashboardLockedBalance.
  ///
  /// In en, this message translates to:
  /// **'Locked balance: {amount} ETB'**
  String dashboardLockedBalance(String amount);

  /// No description provided for @dashboardOpenWallet.
  ///
  /// In en, this message translates to:
  /// **'Open wallet'**
  String get dashboardOpenWallet;

  /// No description provided for @dashboardWalletLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading wallet...'**
  String get dashboardWalletLoading;

  /// No description provided for @dashboardWalletUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Wallet unavailable right now.'**
  String get dashboardWalletUnavailable;

  /// No description provided for @dashboardWhatIsNext.
  ///
  /// In en, this message translates to:
  /// **'What is next'**
  String get dashboardWhatIsNext;

  /// No description provided for @dashboardWhatIsNextBody.
  ///
  /// In en, this message translates to:
  /// **'Next steps can plug live called numbers, bingo claims, deposits, and withdrawals into this same foundation.'**
  String get dashboardWhatIsNextBody;

  /// No description provided for @walletAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get walletAvailableBalance;

  /// No description provided for @walletLockedBalance.
  ///
  /// In en, this message translates to:
  /// **'Locked balance'**
  String get walletLockedBalance;

  /// No description provided for @walletFreezBalance.
  ///
  /// In en, this message translates to:
  /// **'Freez balance'**
  String get walletFreezBalance;

  /// No description provided for @walletTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total wallet'**
  String get walletTotalBalance;

  /// No description provided for @walletTotalEqualsHint.
  ///
  /// In en, this message translates to:
  /// **'Available + Locked = Total wallet'**
  String get walletTotalEqualsHint;

  /// No description provided for @welcomeBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome bonus'**
  String get welcomeBonusTitle;

  /// No description provided for @welcomeBonusBody.
  ///
  /// In en, this message translates to:
  /// **'You have {count} bonus cartelas for normal games. Each one registers 1 normal-game cartela without using your ETB balance. Big GOTD and Big Game use wallet money. Bonus cartelas are not withdrawable.'**
  String welcomeBonusBody(int count);

  /// No description provided for @walletBonusCartelasLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus cartelas (normal games)'**
  String get walletBonusCartelasLabel;

  /// No description provided for @registrationBonusBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus: {count}'**
  String registrationBonusBalanceLabel(int count);

  /// No description provided for @walletDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get walletDeposit;

  /// No description provided for @walletWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletWithdraw;

  /// No description provided for @walletTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletTransactionHistory;

  /// No description provided for @walletTransactionHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review every wallet ledger movement.'**
  String get walletTransactionHistorySubtitle;

  /// No description provided for @walletDepositHistory.
  ///
  /// In en, this message translates to:
  /// **'Deposit history'**
  String get walletDepositHistory;

  /// No description provided for @walletDepositHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track verification progress and retry when needed.'**
  String get walletDepositHistorySubtitle;

  /// No description provided for @walletWithdrawalHistory.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal history'**
  String get walletWithdrawalHistory;

  /// No description provided for @walletWithdrawalHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow request, approval, and payout statuses.'**
  String get walletWithdrawalHistorySubtitle;

  /// No description provided for @walletCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load wallet details.'**
  String get walletCouldNotLoad;

  /// No description provided for @walletTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get walletTryAgain;

  /// No description provided for @depositScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositScreenTitle;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get depositAmount;

  /// No description provided for @depositFtNumber.
  ///
  /// In en, this message translates to:
  /// **'FT number'**
  String get depositFtNumber;

  /// No description provided for @depositReceiptId.
  ///
  /// In en, this message translates to:
  /// **'Receipt ID'**
  String get depositReceiptId;

  /// No description provided for @depositReceiptCode.
  ///
  /// In en, this message translates to:
  /// **'Receipt code'**
  String get depositReceiptCode;

  /// No description provided for @depositReceiptCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid receipt code (6-20 letters and numbers).'**
  String get depositReceiptCodeInvalid;

  /// No description provided for @depositReceiptUrlNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Enter the receipt code only, not the full URL.'**
  String get depositReceiptUrlNotAllowed;

  /// No description provided for @depositSuccessApproved.
  ///
  /// In en, this message translates to:
  /// **'Deposit successful. Wallet updated.'**
  String get depositSuccessApproved;

  /// No description provided for @depositReceiptDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This receipt has already been used.'**
  String get depositReceiptDuplicate;

  /// No description provided for @depositReceiptInvalid.
  ///
  /// In en, this message translates to:
  /// **'Receipt could not be verified.'**
  String get depositReceiptInvalid;

  /// No description provided for @depositAmountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Amount does not match this receipt. Enter the settled amount shown on the receipt.'**
  String get depositAmountMismatch;

  /// No description provided for @depositAmountMismatchSettled.
  ///
  /// In en, this message translates to:
  /// **'This receipt settled amount is {settledAmount} ETB. Enter that amount—not the total paid amount (Telebirr fees are not deposited).'**
  String depositAmountMismatchSettled(String settledAmount);

  /// No description provided for @depositReceiverMismatch.
  ///
  /// In en, this message translates to:
  /// **'This receipt was not paid to Friends Bingo.'**
  String get depositReceiverMismatch;

  /// No description provided for @depositDevHelper.
  ///
  /// In en, this message translates to:
  /// **'Development / test helper'**
  String get depositDevHelper;

  /// No description provided for @depositDevReference.
  ///
  /// In en, this message translates to:
  /// **'Development test reference: {ref}'**
  String depositDevReference(String ref);

  /// No description provided for @depositUseTestRef.
  ///
  /// In en, this message translates to:
  /// **'Use test reference'**
  String get depositUseTestRef;

  /// No description provided for @depositSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit deposit'**
  String get depositSubmit;

  /// No description provided for @depositGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to deposit'**
  String get depositGuideTitle;

  /// No description provided for @depositGuideTelebirrStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Telebirr and send money to Friends Bingo'**
  String get depositGuideTelebirrStep1;

  /// No description provided for @depositGuideTelebirrStep2.
  ///
  /// In en, this message translates to:
  /// **'Open the receipt and copy the transaction number'**
  String get depositGuideTelebirrStep2;

  /// No description provided for @depositGuideTelebirrStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter the settled amount and receipt code below'**
  String get depositGuideTelebirrStep3;

  /// No description provided for @depositGuideCbeStep1.
  ///
  /// In en, this message translates to:
  /// **'Open CBE mobile banking and transfer to Friends Bingo'**
  String get depositGuideCbeStep1;

  /// No description provided for @depositGuideCbeStep2.
  ///
  /// In en, this message translates to:
  /// **'Copy the FT reference number from the receipt'**
  String get depositGuideCbeStep2;

  /// No description provided for @depositGuideCbeStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter the exact amount and reference below'**
  String get depositGuideCbeStep3;

  /// No description provided for @depositGuideAwashStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Awash mobile banking and send payment'**
  String get depositGuideAwashStep1;

  /// No description provided for @depositGuideAwashStep2.
  ///
  /// In en, this message translates to:
  /// **'Copy the payment reference number'**
  String get depositGuideAwashStep2;

  /// No description provided for @depositGuideAwashStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter the exact amount and reference below'**
  String get depositGuideAwashStep3;

  /// No description provided for @depositGuideBoaStep1.
  ///
  /// In en, this message translates to:
  /// **'Open BOA mobile banking and send payment'**
  String get depositGuideBoaStep1;

  /// No description provided for @depositGuideBoaStep2.
  ///
  /// In en, this message translates to:
  /// **'Copy the payment reference number'**
  String get depositGuideBoaStep2;

  /// No description provided for @depositGuideBoaStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter the exact amount and reference below'**
  String get depositGuideBoaStep3;

  /// No description provided for @depositVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your payment…'**
  String get depositVerifying;

  /// No description provided for @depositApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit approved'**
  String get depositApprovedTitle;

  /// No description provided for @depositRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit failed'**
  String get depositRejectedTitle;

  /// No description provided for @depositTryAgain.
  ///
  /// In en, this message translates to:
  /// **'You can correct the details and try again.'**
  String get depositTryAgain;

  /// No description provided for @depositSelectProvider.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get depositSelectProvider;

  /// No description provided for @depositSendToAccount.
  ///
  /// In en, this message translates to:
  /// **'Send to this account'**
  String get depositSendToAccount;

  /// No description provided for @depositSendToAccounts.
  ///
  /// In en, this message translates to:
  /// **'Send to these accounts'**
  String get depositSendToAccounts;

  /// No description provided for @depositTelebirrAccount1.
  ///
  /// In en, this message translates to:
  /// **'Account 1'**
  String get depositTelebirrAccount1;

  /// No description provided for @depositTelebirrAccount2.
  ///
  /// In en, this message translates to:
  /// **'Account 2'**
  String get depositTelebirrAccount2;

  /// No description provided for @depositShowInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get depositShowInstructions;

  /// No description provided for @depositReceiptReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'I have checked the amount and reference number from my transaction'**
  String get depositReceiptReviewLabel;

  /// No description provided for @depositCopyAccount.
  ///
  /// In en, this message translates to:
  /// **'Copy account'**
  String get depositCopyAccount;

  /// No description provided for @depositAccountCopied.
  ///
  /// In en, this message translates to:
  /// **'Account copied'**
  String get depositAccountCopied;

  /// No description provided for @depositGuideImageMissing.
  ///
  /// In en, this message translates to:
  /// **'Screenshot coming soon'**
  String get depositGuideImageMissing;

  /// No description provided for @depositGuideTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to enlarge'**
  String get depositGuideTapToExpand;

  /// No description provided for @walletQuickDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add funds instantly via mobile money or bank transfer'**
  String get walletQuickDeposit;

  /// No description provided for @depositLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest deposit'**
  String get depositLatest;

  /// No description provided for @depositSubmittedStatus.
  ///
  /// In en, this message translates to:
  /// **'Deposit submitted. Status: {status}.'**
  String depositSubmittedStatus(String status);

  /// No description provided for @depositCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit deposit.'**
  String get depositCouldNotSubmit;

  /// No description provided for @depositReceiptScan.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get depositReceiptScan;

  /// No description provided for @depositReceiptScreenshotHelperPrefix.
  ///
  /// In en, this message translates to:
  /// **'Can be filled from a '**
  String get depositReceiptScreenshotHelperPrefix;

  /// No description provided for @depositReceiptScreenshotHelperLink.
  ///
  /// In en, this message translates to:
  /// **'screenshot'**
  String get depositReceiptScreenshotHelperLink;

  /// No description provided for @depositReceiptScreenshotHelperSuffix.
  ///
  /// In en, this message translates to:
  /// **'. Please review before submitting.'**
  String get depositReceiptScreenshotHelperSuffix;

  /// No description provided for @depositReceiptScanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt detected. Please review before submitting.'**
  String get depositReceiptScanSuccess;

  /// No description provided for @depositReceiptScanPartial.
  ///
  /// In en, this message translates to:
  /// **'Some details detected. Please review.'**
  String get depositReceiptScanPartial;

  /// No description provided for @depositReceiptScanFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not read receipt. Please type manually.'**
  String get depositReceiptScanFailure;

  /// No description provided for @depositProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String depositProvider(String provider);

  /// No description provided for @depositAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String depositAmountLabel(String amount);

  /// No description provided for @depositReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {ref}'**
  String depositReference(String ref);

  /// No description provided for @depositCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String depositCreated(String date);

  /// No description provided for @depositRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String depositRejectionReason(String reason);

  /// No description provided for @depositHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit history'**
  String get depositHistoryTitle;

  /// No description provided for @depositHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deposits yet'**
  String get depositHistoryEmpty;

  /// No description provided for @depositHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your deposit requests will appear here.'**
  String get depositHistoryEmptyMessage;

  /// No description provided for @depositHistoryCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load deposit history.'**
  String get depositHistoryCouldNotLoad;

  /// No description provided for @depositRetryVerification.
  ///
  /// In en, this message translates to:
  /// **'Retry verification'**
  String get depositRetryVerification;

  /// No description provided for @depositRetried.
  ///
  /// In en, this message translates to:
  /// **'Verification retried. Status: {status}.'**
  String depositRetried(String status);

  /// No description provided for @depositRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not retry verification.'**
  String get depositRetryFailed;

  /// No description provided for @depositAmountRow.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String depositAmountRow(String amount);

  /// No description provided for @depositRefRow.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref}'**
  String depositRefRow(String ref);

  /// No description provided for @depositCreatedRow.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String depositCreatedRow(String date);

  /// No description provided for @depositReasonRow.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String depositReasonRow(String reason);

  /// No description provided for @withdrawScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawScreenTitle;

  /// No description provided for @withdrawAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get withdrawAmount;

  /// No description provided for @withdrawSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit withdrawal'**
  String get withdrawSubmit;

  /// No description provided for @withdrawLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest withdrawal'**
  String get withdrawLatest;

  /// No description provided for @withdrawSubmittedStatus.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal submitted. Status: {status}.'**
  String withdrawSubmittedStatus(String status);

  /// No description provided for @withdrawCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit withdrawal.'**
  String get withdrawCouldNotSubmit;

  /// No description provided for @withdrawStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String withdrawStatusLabel(String status);

  /// No description provided for @withdrawProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String withdrawProviderLabel(String provider);

  /// No description provided for @withdrawAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String withdrawAmountLabel(String amount);

  /// No description provided for @withdrawPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String withdrawPhoneLabel(String phone);

  /// No description provided for @withdrawAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String withdrawAccountLabel(String account);

  /// No description provided for @withdrawCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String withdrawCreatedLabel(String date);

  /// No description provided for @withdrawNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String withdrawNoteLabel(String note);

  /// No description provided for @withdrawHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal history'**
  String get withdrawHistoryTitle;

  /// No description provided for @withdrawHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No withdrawals yet'**
  String get withdrawHistoryEmpty;

  /// No description provided for @withdrawHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal requests will appear here.'**
  String get withdrawHistoryEmptyMessage;

  /// No description provided for @withdrawHistoryCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load withdrawal history.'**
  String get withdrawHistoryCouldNotLoad;

  /// No description provided for @withdrawSelectProvider.
  ///
  /// In en, this message translates to:
  /// **'Payout method'**
  String get withdrawSelectProvider;

  /// No description provided for @withdrawMaxWithdrawableHint.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw up to your available balance. The rest stays usable for cartelas.'**
  String get withdrawMaxWithdrawableHint;

  /// No description provided for @withdrawLockedFundsHint.
  ///
  /// In en, this message translates to:
  /// **'Locked funds are reserved for pending withdrawal requests.'**
  String get withdrawLockedFundsHint;

  /// No description provided for @withdrawAmountLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'This amount will be locked until admin processes your request.'**
  String get withdrawAmountLockedHelper;

  /// No description provided for @withdrawAmountExceedsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds your available balance.'**
  String get withdrawAmountExceedsAvailable;

  /// No description provided for @withdrawPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal submitted'**
  String get withdrawPendingTitle;

  /// No description provided for @withdrawPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending admin review. The amount is locked until approved or rejected.'**
  String get withdrawPendingMessage;

  /// No description provided for @withdrawApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal approved'**
  String get withdrawApprovedTitle;

  /// No description provided for @withdrawApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your payout has been approved and sent.'**
  String get withdrawApprovedMessage;

  /// No description provided for @withdrawRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal rejected'**
  String get withdrawRejectedTitle;

  /// No description provided for @withdrawRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal was rejected. Locked funds were returned to your balance.'**
  String get withdrawRejectedMessage;

  /// No description provided for @withdrawStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get withdrawStatusPendingReview;

  /// No description provided for @withdrawStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get withdrawStatusApproved;

  /// No description provided for @withdrawStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get withdrawStatusRejected;

  /// No description provided for @withdrawStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get withdrawStatusFailed;

  /// No description provided for @withdrawStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get withdrawStatusRefunded;

  /// No description provided for @walletLockedBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Includes funds reserved for pending withdrawals.'**
  String get walletLockedBalanceHint;

  /// No description provided for @withdrawRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal requests'**
  String get withdrawRequestsTitle;

  /// No description provided for @withdrawTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get withdrawTabAll;

  /// No description provided for @withdrawTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get withdrawTabPending;

  /// No description provided for @withdrawTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get withdrawTabCompleted;

  /// No description provided for @withdrawTabRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get withdrawTabRejected;

  /// No description provided for @withdrawTableDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get withdrawTableDate;

  /// No description provided for @withdrawTableAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get withdrawTableAmount;

  /// No description provided for @withdrawTableProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get withdrawTableProvider;

  /// No description provided for @withdrawTableStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get withdrawTableStatus;

  /// No description provided for @withdrawPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending withdrawal requests.'**
  String get withdrawPendingEmpty;

  /// No description provided for @withdrawCompletedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed withdrawals yet.'**
  String get withdrawCompletedEmpty;

  /// No description provided for @withdrawRejectedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rejected withdrawals.'**
  String get withdrawRejectedEmpty;

  /// No description provided for @txHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet transactions'**
  String get txHistoryTitle;

  /// No description provided for @txHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get txHistoryEmpty;

  /// No description provided for @txHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your wallet ledger will show up here after deposits, entries, and withdrawals.'**
  String get txHistoryEmptyMessage;

  /// No description provided for @txHistoryShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total} transactions'**
  String txHistoryShowing(int count, int total);

  /// No description provided for @txHistoryWalletActivity.
  ///
  /// In en, this message translates to:
  /// **'Wallet activity'**
  String get txHistoryWalletActivity;

  /// No description provided for @txWithdrawRequestLockedNote.
  ///
  /// In en, this message translates to:
  /// **'Moved to locked balance pending approval.'**
  String get txWithdrawRequestLockedNote;

  /// No description provided for @txHistoryBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Bal: {amount}'**
  String txHistoryBalanceAfter(String amount);

  /// No description provided for @txHistoryCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load transaction history.'**
  String get txHistoryCouldNotLoad;

  /// No description provided for @gameHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Game history'**
  String get gameHistoryTitle;

  /// No description provided for @gameHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finished games yet.'**
  String get gameHistoryEmpty;

  /// No description provided for @gameHistoryCards.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String gameHistoryCards(int count);

  /// No description provided for @gameHistoryLoadingAttended.
  ///
  /// In en, this message translates to:
  /// **'Loading your games...'**
  String get gameHistoryLoadingAttended;

  /// No description provided for @gameHistoryEmptyAttended.
  ///
  /// In en, this message translates to:
  /// **'No finished games you joined yet.'**
  String get gameHistoryEmptyAttended;

  /// No description provided for @gameHistoryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Game details'**
  String get gameHistoryDetailTitle;

  /// No description provided for @gameHistoryPrizePool.
  ///
  /// In en, this message translates to:
  /// **'Prize pool'**
  String get gameHistoryPrizePool;

  /// No description provided for @gameHistoryYourWinnings.
  ///
  /// In en, this message translates to:
  /// **'You won {amount}'**
  String gameHistoryYourWinnings(String amount);

  /// No description provided for @gameHistoryYourCartelas.
  ///
  /// In en, this message translates to:
  /// **'Your cartelas'**
  String get gameHistoryYourCartelas;

  /// No description provided for @gameHistorySessionWinners.
  ///
  /// In en, this message translates to:
  /// **'Session winners'**
  String get gameHistorySessionWinners;

  /// No description provided for @gameHistoryMyCartelaCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of yours'**
  String gameHistoryMyCartelaCount(int count);

  /// No description provided for @gameHistoryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get gameHistoryLoadMore;

  /// No description provided for @gameHistoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get gameHistoryRetry;

  /// No description provided for @gameStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Game stats'**
  String get gameStatsLabel;

  /// No description provided for @gameHideStats.
  ///
  /// In en, this message translates to:
  /// **'Hide game stats'**
  String get gameHideStats;

  /// No description provided for @gameShowStats.
  ///
  /// In en, this message translates to:
  /// **'Show game stats'**
  String get gameShowStats;

  /// No description provided for @gameEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get gameEntryLabel;

  /// No description provided for @gamePrizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Prize'**
  String get gamePrizeLabel;

  /// No description provided for @gameRegLabel.
  ///
  /// In en, this message translates to:
  /// **'Reg'**
  String get gameRegLabel;

  /// No description provided for @gameCalledLabel.
  ///
  /// In en, this message translates to:
  /// **'Called'**
  String get gameCalledLabel;

  /// No description provided for @gameNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get gameNowPlaying;

  /// No description provided for @gameNextGame.
  ///
  /// In en, this message translates to:
  /// **'Next game'**
  String get gameNextGame;

  /// No description provided for @liveCalledNumbersLabel.
  ///
  /// In en, this message translates to:
  /// **'Called numbers'**
  String get liveCalledNumbersLabel;

  /// No description provided for @liveNextRoundSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get liveNextRoundSectionTitle;

  /// No description provided for @liveJoinCurrentRoundSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Join current round'**
  String get liveJoinCurrentRoundSectionTitle;

  /// No description provided for @liveMissedCurrentRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Current round in play'**
  String get liveMissedCurrentRoundTitle;

  /// No description provided for @liveNextQueuedPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Next queued play'**
  String get liveNextQueuedPlayLabel;

  /// No description provided for @liveRegisteredCartelasLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered cartelas'**
  String get liveRegisteredCartelasLabel;

  /// No description provided for @liveRegisteredCartelasEmpty.
  ///
  /// In en, this message translates to:
  /// **'None yet — pick numbers below.'**
  String get liveRegisteredCartelasEmpty;

  /// No description provided for @liveMissedRoundHelper.
  ///
  /// In en, this message translates to:
  /// **'You missed the current game. Register for the next round.'**
  String get liveMissedRoundHelper;

  /// No description provided for @liveMissedRoundYouMissedGame.
  ///
  /// In en, this message translates to:
  /// **'You missed this round.'**
  String get liveMissedRoundYouMissedGame;

  /// No description provided for @liveMissedRoundOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live & next round'**
  String get liveMissedRoundOverviewTitle;

  /// No description provided for @liveMissedRoundCollapsedMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed · {gameName}'**
  String liveMissedRoundCollapsedMissed(String gameName);

  /// No description provided for @liveMissedRoundCollapsedNextReady.
  ///
  /// In en, this message translates to:
  /// **'Next ready · {gameName} · register now'**
  String liveMissedRoundCollapsedNextReady(String gameName);

  /// No description provided for @liveMissedRoundRegisterBridge.
  ///
  /// In en, this message translates to:
  /// **'Register cartelas now for the next game and play next round.'**
  String get liveMissedRoundRegisterBridge;

  /// No description provided for @liveJoinCurrentRoundGameLive.
  ///
  /// In en, this message translates to:
  /// **'{gameName} is live now'**
  String liveJoinCurrentRoundGameLive(String gameName);

  /// No description provided for @liveNextGameBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'NEXT GAME'**
  String get liveNextGameBannerTitle;

  /// No description provided for @liveMissedRoundBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soon starts the next game'**
  String get liveMissedRoundBannerSubtitle;

  /// No description provided for @liveNextGameLabel.
  ///
  /// In en, this message translates to:
  /// **'Next game'**
  String get liveNextGameLabel;

  /// No description provided for @registrationStartsAfterCurrentGame.
  ///
  /// In en, this message translates to:
  /// **'Registration open - starts after current game'**
  String get registrationStartsAfterCurrentGame;

  /// No description provided for @liveJoinCurrentRoundHelper.
  ///
  /// In en, this message translates to:
  /// **'Registration is still open for this live round. Taken and reserved cartelas are locked automatically.'**
  String get liveJoinCurrentRoundHelper;

  /// No description provided for @liveAddMoreCartelasHelper.
  ///
  /// In en, this message translates to:
  /// **'Registration is still open. You can add more cartelas while the round is active.'**
  String get liveAddMoreCartelasHelper;

  /// No description provided for @liveAddMoreCartelasTitle.
  ///
  /// In en, this message translates to:
  /// **'Add more cartelas'**
  String get liveAddMoreCartelasTitle;

  /// No description provided for @liveNextRoundRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Next round registration'**
  String get liveNextRoundRegistrationTitle;

  /// No description provided for @gameRuleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Game rule'**
  String get gameRuleDetailTitle;

  /// No description provided for @gameRulePatternSample.
  ///
  /// In en, this message translates to:
  /// **'Sample winning pattern'**
  String get gameRulePatternSample;

  /// No description provided for @gameNextGameHide.
  ///
  /// In en, this message translates to:
  /// **'Hide next game'**
  String get gameNextGameHide;

  /// No description provided for @gameNextGameShow.
  ///
  /// In en, this message translates to:
  /// **'Show next game'**
  String get gameNextGameShow;

  /// No description provided for @leaveLiveGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave live game?'**
  String get leaveLiveGameTitle;

  /// No description provided for @leaveLiveGameMessage.
  ///
  /// In en, this message translates to:
  /// **'Your game will continue on the server. Your marked cells will be saved on this device.'**
  String get leaveLiveGameMessage;

  /// No description provided for @leaveLiveGameStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get leaveLiveGameStay;

  /// No description provided for @leaveLiveGameLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveLiveGameLeave;

  /// No description provided for @confirmBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Go back?'**
  String get confirmBackTitle;

  /// No description provided for @confirmBackMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave this page?'**
  String get confirmBackMessage;

  /// No description provided for @confirmBackStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get confirmBackStay;

  /// No description provided for @confirmBackLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get confirmBackLeave;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit app?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Your game will continue. You can return anytime.'**
  String get exitAppMessage;

  /// No description provided for @exitAppStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get exitAppStay;

  /// No description provided for @exitAppExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitAppExit;

  /// No description provided for @developerModeBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Security check'**
  String get developerModeBlockedTitle;

  /// No description provided for @developerModeBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Developer options are turned on. Turn them off in your phone settings to use Friends Bingo.'**
  String get developerModeBlockedMessage;

  /// No description provided for @developerModeOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get developerModeOpenSettings;

  /// No description provided for @developerModeCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get developerModeCloseApp;

  /// No description provided for @winningCartelasTitle.
  ///
  /// In en, this message translates to:
  /// **'Winning cartelas'**
  String get winningCartelasTitle;

  /// No description provided for @winningCartelasTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a cartela to view the full winning pattern.'**
  String get winningCartelasTapHint;

  /// No description provided for @winningCartelasYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get winningCartelasYou;

  /// No description provided for @winningCartelasPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get winningCartelasPlayer;

  /// No description provided for @winningCartelasPrize.
  ///
  /// In en, this message translates to:
  /// **'Prize: {amount} ETB'**
  String winningCartelasPrize(String amount);

  /// No description provided for @winningCartelasDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Winning cartela #{number}'**
  String winningCartelasDetailTitle(int number);

  /// No description provided for @winningCartelasSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe or tap a number to see each winner'**
  String get winningCartelasSwipeHint;

  /// No description provided for @winningCartelasWinningBall.
  ///
  /// In en, this message translates to:
  /// **'Winning ball: {ball}'**
  String winningCartelasWinningBall(String ball);

  /// No description provided for @winningCartelasAllWinners.
  ///
  /// In en, this message translates to:
  /// **'Winners'**
  String get winningCartelasAllWinners;

  /// No description provided for @winningCartelasPreviousWinner.
  ///
  /// In en, this message translates to:
  /// **'Previous winner'**
  String get winningCartelasPreviousWinner;

  /// No description provided for @winningCartelasNextWinner.
  ///
  /// In en, this message translates to:
  /// **'Next winner'**
  String get winningCartelasNextWinner;

  /// No description provided for @cartelaOutcomeValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get cartelaOutcomeValid;

  /// No description provided for @cartelaOutcomeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get cartelaOutcomeInvalid;

  /// No description provided for @cartelaOutcomeRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get cartelaOutcomeRegistered;

  /// No description provided for @cartelaOutcomeNoWin.
  ///
  /// In en, this message translates to:
  /// **'No win'**
  String get cartelaOutcomeNoWin;

  /// No description provided for @cartelaBlockedInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Why is this cartela blocked?'**
  String get cartelaBlockedInfoTooltip;

  /// No description provided for @cartelaBlockedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cartela #{number} blocked'**
  String cartelaBlockedDialogTitle(int number);

  /// No description provided for @cartelaBlockedDialogOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get cartelaBlockedDialogOk;

  /// No description provided for @cartelaBlockedReasonLate.
  ///
  /// In en, this message translates to:
  /// **'You missed the winning call. This cartela has been blocked.'**
  String get cartelaBlockedReasonLate;

  /// No description provided for @cartelaBlockedReasonPattern.
  ///
  /// In en, this message translates to:
  /// **'Your claim did not match the game rule.'**
  String get cartelaBlockedReasonPattern;

  /// No description provided for @cartelaBlockedReasonGeneric.
  ///
  /// In en, this message translates to:
  /// **'This cartela has been blocked.'**
  String get cartelaBlockedReasonGeneric;

  /// No description provided for @gameLabel.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameLabel;

  /// No description provided for @connectionOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get connectionOnline;

  /// No description provided for @connectionReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get connectionReconnecting;

  /// No description provided for @connectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get connectionOffline;

  /// No description provided for @registrationTapHintGuest.
  ///
  /// In en, this message translates to:
  /// **'Sign up to register cartelas'**
  String get registrationTapHintGuest;

  /// No description provided for @registrationTapHintSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap numbers to select · Review when ready'**
  String get registrationTapHintSelect;

  /// No description provided for @registrationTapHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Tap a number to preview and register'**
  String get registrationTapHintDefault;

  /// No description provided for @registrationClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get registrationClear;

  /// No description provided for @registrationReview.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String registrationReview(int count);

  /// No description provided for @registrationSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s left'**
  String registrationSecondsLeft(int seconds);

  /// No description provided for @registrationUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String registrationUpTo(int max);

  /// No description provided for @registrationLeft.
  ///
  /// In en, this message translates to:
  /// **' left'**
  String get registrationLeft;

  /// No description provided for @registrationOpenBanner.
  ///
  /// In en, this message translates to:
  /// **'REGISTRATION OPEN'**
  String get registrationOpenBanner;

  /// No description provided for @registrationOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration open'**
  String get registrationOpenLabel;

  /// No description provided for @registrationClosesIn.
  ///
  /// In en, this message translates to:
  /// **'Registration closes in {seconds}s'**
  String registrationClosesIn(int seconds);

  /// No description provided for @registrationClosesInDuration.
  ///
  /// In en, this message translates to:
  /// **'Registration closes in {duration}'**
  String registrationClosesInDuration(String duration);

  /// No description provided for @registrationClosedPreparing.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get registrationClosedPreparing;

  /// No description provided for @preparingGameNoCartelas.
  ///
  /// In en, this message translates to:
  /// **'Cartela registration is closed. The live round will begin shortly.'**
  String get preparingGameNoCartelas;

  /// No description provided for @preparingGameCartelasRegistered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cartela registered. The live round will begin shortly.} other{{count} cartelas registered. The live round will begin shortly.}}'**
  String preparingGameCartelasRegistered(int count);

  /// No description provided for @liveNoGameTitle.
  ///
  /// In en, this message translates to:
  /// **'No games in queue'**
  String get liveNoGameTitle;

  /// No description provided for @liveNoGameMessage.
  ///
  /// In en, this message translates to:
  /// **'No game is open right now. Pull down to refresh when the next round starts.'**
  String get liveNoGameMessage;

  /// No description provided for @gameCheckingTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking bingo claim'**
  String get gameCheckingTitle;

  /// No description provided for @gameCheckingMessage.
  ///
  /// In en, this message translates to:
  /// **'A bingo claim is being checked. Hold on — do not mark new numbers yet.'**
  String get gameCheckingMessage;

  /// No description provided for @calledNumbersDrawnCount.
  ///
  /// In en, this message translates to:
  /// **'Drawn: {count}'**
  String calledNumbersDrawnCount(int count);

  /// No description provided for @calledNumbersBallOrder.
  ///
  /// In en, this message translates to:
  /// **'#{order}'**
  String calledNumbersBallOrder(int order);

  /// No description provided for @calledNumbersSyncLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get calledNumbersSyncLive;

  /// No description provided for @calledNumbersSyncCatchingUp.
  ///
  /// In en, this message translates to:
  /// **'Catching up…'**
  String get calledNumbersSyncCatchingUp;

  /// No description provided for @calledNumbersSyncHelp.
  ///
  /// In en, this message translates to:
  /// **'Called numbers are synced from the server. A short delay on slow networks is normal.'**
  String get calledNumbersSyncHelp;

  /// No description provided for @calledNumbersSyncHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Called numbers sync'**
  String get calledNumbersSyncHelpTitle;

  /// No description provided for @calledNumbersSyncReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get calledNumbersSyncReconnecting;

  /// No description provided for @calledNumbersRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh called numbers'**
  String get calledNumbersRefreshTooltip;

  /// No description provided for @cartelaMarkColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green marks'**
  String get cartelaMarkColorGreen;

  /// No description provided for @cartelaMarkColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red marks'**
  String get cartelaMarkColorRed;

  /// No description provided for @cartelaMarkColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow marks'**
  String get cartelaMarkColorYellow;

  /// No description provided for @cartelaMarkColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue marks'**
  String get cartelaMarkColorBlue;

  /// No description provided for @cartelaMarkColorMenu.
  ///
  /// In en, this message translates to:
  /// **'Mark color'**
  String get cartelaMarkColorMenu;

  /// No description provided for @cartelaClearMarks.
  ///
  /// In en, this message translates to:
  /// **'Clear marks'**
  String get cartelaClearMarks;

  /// No description provided for @calledNumbersNextBallIn.
  ///
  /// In en, this message translates to:
  /// **'Next ball · {seconds}s'**
  String calledNumbersNextBallIn(int seconds);

  /// No description provided for @calledNumbersNextBallLabel.
  ///
  /// In en, this message translates to:
  /// **'Next ball'**
  String get calledNumbersNextBallLabel;

  /// No description provided for @calledNumbersFirstBallLabel.
  ///
  /// In en, this message translates to:
  /// **'First ball'**
  String get calledNumbersFirstBallLabel;

  /// No description provided for @calledNumbersWaitingFirstBallIn.
  ///
  /// In en, this message translates to:
  /// **'Waiting for first ball · {seconds}s'**
  String calledNumbersWaitingFirstBallIn(int seconds);

  /// No description provided for @calledNumbersCallingNext.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get calledNumbersCallingNext;

  /// No description provided for @calledNumbersSyncingNextBall.
  ///
  /// In en, this message translates to:
  /// **'Syncing next ball…'**
  String get calledNumbersSyncingNextBall;

  /// No description provided for @calledNumbersDrawLabel.
  ///
  /// In en, this message translates to:
  /// **'Draw #{order}'**
  String calledNumbersDrawLabel(int order);

  /// No description provided for @calledNumbersSyncingMissed.
  ///
  /// In en, this message translates to:
  /// **'Syncing missed numbers…'**
  String get calledNumbersSyncingMissed;

  /// No description provided for @calledNumbersWaitingNextBall.
  ///
  /// In en, this message translates to:
  /// **'Waiting for next ball…'**
  String get calledNumbersWaitingNextBall;

  /// No description provided for @calledNumbersAllBallsDrawn.
  ///
  /// In en, this message translates to:
  /// **'All balls drawn'**
  String get calledNumbersAllBallsDrawn;

  /// No description provided for @calledNumbersWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Numbers will appear here'**
  String get calledNumbersWillAppear;

  /// No description provided for @calledNumbersCheckingBingo.
  ///
  /// In en, this message translates to:
  /// **'Checking bingo…'**
  String get calledNumbersCheckingBingo;

  /// No description provided for @calledNumbersClaimHoldNote.
  ///
  /// In en, this message translates to:
  /// **'New numbers will appear after your claim is processed.'**
  String get calledNumbersClaimHoldNote;

  /// No description provided for @registrationSignUpToPlay.
  ///
  /// In en, this message translates to:
  /// **'Sign up to play'**
  String get registrationSignUpToPlay;

  /// No description provided for @bulkReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your cartelas'**
  String get bulkReviewTitle;

  /// No description provided for @bulkRegisteringTitle.
  ///
  /// In en, this message translates to:
  /// **'Registering cartelas'**
  String get bulkRegisteringTitle;

  /// No description provided for @bulkCartelasTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} cartelas · {total} total'**
  String bulkCartelasTotal(int count, String total);

  /// No description provided for @bulkPerCartela.
  ///
  /// In en, this message translates to:
  /// **'{fee} per cartela'**
  String bulkPerCartela(String fee);

  /// No description provided for @bulkConfirmNumbers.
  ///
  /// In en, this message translates to:
  /// **'Confirm the numbers above, then register them together.'**
  String get bulkConfirmNumbers;

  /// No description provided for @bulkStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting registration...'**
  String get bulkStarting;

  /// No description provided for @bulkProgress.
  ///
  /// In en, this message translates to:
  /// **'Registering {completed} of {total} cartelas...'**
  String bulkProgress(int completed, int total);

  /// No description provided for @bulkCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bulkCancel;

  /// No description provided for @bulkRegister.
  ///
  /// In en, this message translates to:
  /// **'Register {count}'**
  String bulkRegister(int count);

  /// No description provided for @bulkRegistering.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get bulkRegistering;

  /// No description provided for @bulkCouldNotRegister.
  ///
  /// In en, this message translates to:
  /// **'Could not register selected cartelas. Please try again.'**
  String get bulkCouldNotRegister;

  /// No description provided for @bulkTakenNumbers.
  ///
  /// In en, this message translates to:
  /// **'Could not register selected cartelas. {numbers} already taken.'**
  String bulkTakenNumbers(String numbers);

  /// No description provided for @winnerBannerSyncingTitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing live game…'**
  String get winnerBannerSyncingTitle;

  /// No description provided for @winnerBannerSyncingMessage.
  ///
  /// In en, this message translates to:
  /// **'Updating the live round from the server.'**
  String get winnerBannerSyncingMessage;

  /// No description provided for @winnerBannerWindowOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Winner window open'**
  String get winnerBannerWindowOpenTitle;

  /// No description provided for @winnerBannerWindowOpenMessage.
  ///
  /// In en, this message translates to:
  /// **'Other players can still claim during the winner window.'**
  String get winnerBannerWindowOpenMessage;

  /// No description provided for @winnerBannerYouWonTitle.
  ///
  /// In en, this message translates to:
  /// **'You Won!'**
  String get winnerBannerYouWonTitle;

  /// No description provided for @winnerBannerWonWithPayout.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You won {amount} ETB. Next registration opens shortly.'**
  String winnerBannerWonWithPayout(String amount);

  /// No description provided for @winnerBannerWonNoPayout.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your cartela won. Prize is being updated. Next registration opens shortly.'**
  String get winnerBannerWonNoPayout;

  /// No description provided for @winnerBannerFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Finished'**
  String get winnerBannerFinishedTitle;

  /// No description provided for @winnerBannerFinishedMessage.
  ///
  /// In en, this message translates to:
  /// **'This game is finished. Better luck next time! Next registration opens shortly.'**
  String get winnerBannerFinishedMessage;

  /// No description provided for @winnerBannerNoPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'No Players Joined'**
  String get winnerBannerNoPlayersTitle;

  /// No description provided for @winnerBannerNoPlayersMessage.
  ///
  /// In en, this message translates to:
  /// **'No players joined this round. Next round starting…'**
  String get winnerBannerNoPlayersMessage;

  /// No description provided for @winnerBannerCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Cancelled'**
  String get winnerBannerCancelledTitle;

  /// No description provided for @winnerBannerCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This game was cancelled. Entry fees were refunded. Next round starting…'**
  String get winnerBannerCancelledMessage;

  /// No description provided for @drawerSignInToPlay.
  ///
  /// In en, this message translates to:
  /// **'Sign in to play and register cartelas'**
  String get drawerSignInToPlay;

  /// No description provided for @drawerSounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get drawerSounds;

  /// No description provided for @soundSettingsDeviceOnly.
  ///
  /// In en, this message translates to:
  /// **'These settings are saved on this device only.'**
  String get soundSettingsDeviceOnly;

  /// No description provided for @soundMaster.
  ///
  /// In en, this message translates to:
  /// **'Game sounds'**
  String get soundMaster;

  /// No description provided for @soundCalledNumber.
  ///
  /// In en, this message translates to:
  /// **'Called number'**
  String get soundCalledNumber;

  /// No description provided for @soundGameStart.
  ///
  /// In en, this message translates to:
  /// **'Game start'**
  String get soundGameStart;

  /// No description provided for @soundWinnerWindow.
  ///
  /// In en, this message translates to:
  /// **'Winner window'**
  String get soundWinnerWindow;

  /// No description provided for @soundValidBingo.
  ///
  /// In en, this message translates to:
  /// **'Valid bingo'**
  String get soundValidBingo;

  /// No description provided for @soundVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get soundVibrate;

  /// No description provided for @drawerBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get drawerBalance;

  /// No description provided for @drawerJoinTheGame.
  ///
  /// In en, this message translates to:
  /// **'Join the game'**
  String get drawerJoinTheGame;

  /// No description provided for @drawerJoinTheGameBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account to register cartelas and manage your wallet.'**
  String get drawerJoinTheGameBody;

  /// No description provided for @drawerLiveGame.
  ///
  /// In en, this message translates to:
  /// **'Live Game'**
  String get drawerLiveGame;

  /// No description provided for @drawerWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get drawerWallet;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @drawerHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get drawerHistory;

  /// No description provided for @drawerTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get drawerTransactionHistory;

  /// No description provided for @drawerGameHistory.
  ///
  /// In en, this message translates to:
  /// **'Game history'**
  String get drawerGameHistory;

  /// No description provided for @drawerAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get drawerAppVersion;

  /// No description provided for @drawerAppVersionUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get drawerAppVersionUpToDate;

  /// No description provided for @drawerAppVersionUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get drawerAppVersionUpdateAvailable;

  /// No description provided for @drawerAppVersionUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get drawerAppVersionUpdateRequired;

  /// No description provided for @drawerAppVersionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get drawerAppVersionChecking;

  /// No description provided for @drawerAppVersionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Installed: {version}'**
  String drawerAppVersionCurrent(String version);

  /// No description provided for @noUpdateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'No updates'**
  String get noUpdateAvailableTitle;

  /// No description provided for @noUpdateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'You already have the latest version installed.'**
  String get noUpdateAvailableBody;

  /// No description provided for @noUpdateAvailableOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get noUpdateAvailableOk;

  /// No description provided for @updateCheckFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateCheckFailedTitle;

  /// No description provided for @updateCheckFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the update server. Check your internet connection and try again.'**
  String get updateCheckFailedBody;

  /// No description provided for @updateStatusDetail.
  ///
  /// In en, this message translates to:
  /// **'Installed build {installedBuild}. Server latest build {serverBuild} ({serverVersion}).'**
  String updateStatusDetail(
    int installedBuild,
    int serverBuild,
    String serverVersion,
  );

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update immediately'**
  String get updateRequiredTitle;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @updateVersionInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get updateVersionInstalled;

  /// No description provided for @updateVersionMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get updateVersionMinimum;

  /// No description provided for @updateVersionLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get updateVersionLatest;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.'**
  String updateAvailableMessage(String version);

  /// No description provided for @updateRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This app version is no longer supported. Please update to version {version} to continue.'**
  String updateRequiredMessage(String version);

  /// No description provided for @updateLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Update link is unavailable.'**
  String get updateLinkUnavailable;

  /// No description provided for @guestPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to register this cartela'**
  String get guestPromptTitle;

  /// No description provided for @guestPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign up or sign in to pick cartela numbers and join the game.'**
  String get guestPromptMessage;

  /// No description provided for @guestPromoModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestPromoModeLabel;

  /// No description provided for @guestPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch the live draw, join the next round'**
  String get guestPromoTitle;

  /// No description provided for @guestPromoMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch numbers land in real time, then sign in or create your account to lock cartelas before the next queued play starts.'**
  String get guestPromoMessage;

  /// No description provided for @guestPromoFooter.
  ///
  /// In en, this message translates to:
  /// **'Fast signup. Next-round access. Live bingo energy.'**
  String get guestPromoFooter;

  /// No description provided for @guestPromoRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Row line'**
  String get guestPromoRowLabel;

  /// No description provided for @guestPromoRowHelper.
  ///
  /// In en, this message translates to:
  /// **'A full row closes first.'**
  String get guestPromoRowHelper;

  /// No description provided for @guestPromoColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Column line'**
  String get guestPromoColumnLabel;

  /// No description provided for @guestPromoColumnHelper.
  ///
  /// In en, this message translates to:
  /// **'Then a full column lands cleanly.'**
  String get guestPromoColumnHelper;

  /// No description provided for @guestPromoDiagonalLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagonal bingo'**
  String get guestPromoDiagonalLabel;

  /// No description provided for @guestPromoDiagonalHelper.
  ///
  /// In en, this message translates to:
  /// **'Finally the diagonal completes bingo.'**
  String get guestPromoDiagonalHelper;

  /// No description provided for @guestPromoWinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get guestPromoWinnerLabel;

  /// No description provided for @guestPromoCongratsTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get guestPromoCongratsTitle;

  /// No description provided for @guestPromoCongratsAmountWon.
  ///
  /// In en, this message translates to:
  /// **'{amount} won'**
  String guestPromoCongratsAmountWon(String amount);

  /// No description provided for @guestPromoCongratsReceived.
  ///
  /// In en, this message translates to:
  /// **'You received {amount} by CBE Bank.'**
  String guestPromoCongratsReceived(String amount);

  /// No description provided for @guestPromoCongratsWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Sign in or sign up to withdraw.'**
  String get guestPromoCongratsWithdraw;

  /// No description provided for @drawerTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get drawerTheme;

  /// No description provided for @drawerThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get drawerThemeLight;

  /// No description provided for @drawerThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get drawerThemeDark;

  /// No description provided for @drawerThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get drawerThemeAuto;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogout;

  /// No description provided for @drawerJoinGame.
  ///
  /// In en, this message translates to:
  /// **'Join the game'**
  String get drawerJoinGame;

  /// No description provided for @drawerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account to register cartelas and manage your wallet.'**
  String get drawerCreateAccount;

  /// No description provided for @gameStats.
  ///
  /// In en, this message translates to:
  /// **'Game stats'**
  String get gameStats;

  /// No description provided for @gameStatsHide.
  ///
  /// In en, this message translates to:
  /// **'Hide game stats'**
  String get gameStatsHide;

  /// No description provided for @gameStatsShow.
  ///
  /// In en, this message translates to:
  /// **'Show game stats'**
  String get gameStatsShow;

  /// No description provided for @gameInfoEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get gameInfoEntry;

  /// No description provided for @gameInfoPrize.
  ///
  /// In en, this message translates to:
  /// **'Prize'**
  String get gameInfoPrize;

  /// No description provided for @gameInfoReg.
  ///
  /// In en, this message translates to:
  /// **'Reg'**
  String get gameInfoReg;

  /// No description provided for @gameInfoCalled.
  ///
  /// In en, this message translates to:
  /// **'Called'**
  String get gameInfoCalled;

  /// No description provided for @gameInfoGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameInfoGame;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get statusReconnecting;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @gameHintGuest.
  ///
  /// In en, this message translates to:
  /// **'Sign up to register cartelas'**
  String get gameHintGuest;

  /// No description provided for @gameHintSelectMode.
  ///
  /// In en, this message translates to:
  /// **'Tap numbers to select · Review when ready'**
  String get gameHintSelectMode;

  /// No description provided for @gameHintSingleMode.
  ///
  /// In en, this message translates to:
  /// **'Tap to preview · Hold to select multiple'**
  String get gameHintSingleMode;

  /// No description provided for @gameClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get gameClear;

  /// No description provided for @gameReview.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String gameReview(int count);

  /// No description provided for @gameSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s left'**
  String gameSecondsLeft(int seconds);

  /// No description provided for @gameUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String gameUpTo(int max);

  /// No description provided for @gameBalanceLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get gameBalanceLeft;

  /// No description provided for @gameSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing live game…'**
  String get gameSyncing;

  /// No description provided for @gameSyncingMessage.
  ///
  /// In en, this message translates to:
  /// **'Updating the live round from the server.'**
  String get gameSyncingMessage;

  /// No description provided for @gameWinnerWindowOpen.
  ///
  /// In en, this message translates to:
  /// **'Winner window open'**
  String get gameWinnerWindowOpen;

  /// No description provided for @gameWinnerWindowMessage.
  ///
  /// In en, this message translates to:
  /// **'Other players can still claim during the winner window.'**
  String get gameWinnerWindowMessage;

  /// No description provided for @gameFinalizingWinners.
  ///
  /// In en, this message translates to:
  /// **'Finalizing winners…'**
  String get gameFinalizingWinners;

  /// No description provided for @gameFinalizingWinnersMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the server to finish this round and credit prizes.'**
  String get gameFinalizingWinnersMessage;

  /// No description provided for @gameFinalizingWinnersDelayed.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than usual. Pull to refresh or tap retry.'**
  String get gameFinalizingWinnersDelayed;

  /// No description provided for @gameStartingRound.
  ///
  /// In en, this message translates to:
  /// **'Starting round…'**
  String get gameStartingRound;

  /// No description provided for @gameStartingRoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the live session to open.'**
  String get gameStartingRoundMessage;

  /// No description provided for @gameOpeningNextRound.
  ///
  /// In en, this message translates to:
  /// **'Opening next round…'**
  String get gameOpeningNextRound;

  /// No description provided for @gameOpeningNextRoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the next registration to open.'**
  String get gameOpeningNextRoundMessage;

  /// No description provided for @gameResultsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading round results…'**
  String get gameResultsLoading;

  /// No description provided for @sessionResultsNoWinners.
  ///
  /// In en, this message translates to:
  /// **'No winners this round.'**
  String get sessionResultsNoWinners;

  /// No description provided for @gameAllNumbersCalled.
  ///
  /// In en, this message translates to:
  /// **'All numbers were called.'**
  String get gameAllNumbersCalled;

  /// No description provided for @gameNoWinnerNextRoundShortly.
  ///
  /// In en, this message translates to:
  /// **'Next game will open shortly.'**
  String get gameNoWinnerNextRoundShortly;

  /// No description provided for @calledNumbersCheckingCartela.
  ///
  /// In en, this message translates to:
  /// **'Checking cartela'**
  String get calledNumbersCheckingCartela;

  /// No description provided for @calledNumbersWinnerCartela.
  ///
  /// In en, this message translates to:
  /// **'Winner cartela'**
  String get calledNumbersWinnerCartela;

  /// No description provided for @calledNumbersBlockedCartela.
  ///
  /// In en, this message translates to:
  /// **'Blocked cartela'**
  String get calledNumbersBlockedCartela;

  /// No description provided for @gameYouWon.
  ///
  /// In en, this message translates to:
  /// **'You Won!'**
  String get gameYouWon;

  /// No description provided for @gameNextRegistration.
  ///
  /// In en, this message translates to:
  /// **'Next registration opens shortly.'**
  String get gameNextRegistration;

  /// No description provided for @gameWonAmount.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You won {amount} ETB.'**
  String gameWonAmount(String amount);

  /// No description provided for @gameWonPending.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your cartela won. Prize is being updated.'**
  String get gameWonPending;

  /// No description provided for @gameFinished.
  ///
  /// In en, this message translates to:
  /// **'Game Finished'**
  String get gameFinished;

  /// No description provided for @gameFinishedMessage.
  ///
  /// In en, this message translates to:
  /// **'This game is finished. Better luck next time! Next registration opens shortly.'**
  String get gameFinishedMessage;

  /// No description provided for @postGameSummaryNextRoundIn.
  ///
  /// In en, this message translates to:
  /// **'Continue in {seconds}s'**
  String postGameSummaryNextRoundIn(int seconds);

  /// No description provided for @postGameSummaryTapToViewWinner.
  ///
  /// In en, this message translates to:
  /// **'Tap to view winning cartela'**
  String get postGameSummaryTapToViewWinner;

  /// No description provided for @postGameSummaryNextGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get postGameSummaryNextGame;

  /// No description provided for @postGameSummaryOpeningNextRound.
  ///
  /// In en, this message translates to:
  /// **'Opening next round…'**
  String get postGameSummaryOpeningNextRound;

  /// No description provided for @finishedGamePrizeLine.
  ///
  /// In en, this message translates to:
  /// **'For this game the prize is {amount}'**
  String finishedGamePrizeLine(String amount);

  /// No description provided for @reviewModeWinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get reviewModeWinnerTitle;

  /// No description provided for @reviewModeWinnerCartela.
  ///
  /// In en, this message translates to:
  /// **'Cartela #{number}'**
  String reviewModeWinnerCartela(int number);

  /// No description provided for @reviewModeAdditionalWinners.
  ///
  /// In en, this message translates to:
  /// **'+{count} more winner(s)'**
  String reviewModeAdditionalWinners(int count);

  /// No description provided for @gameNoPlayers.
  ///
  /// In en, this message translates to:
  /// **'No Players Joined'**
  String get gameNoPlayers;

  /// No description provided for @gameNoPlayersMessage.
  ///
  /// In en, this message translates to:
  /// **'No players joined this round. Next round starting…'**
  String get gameNoPlayersMessage;

  /// No description provided for @gameCancelled.
  ///
  /// In en, this message translates to:
  /// **'Game Cancelled'**
  String get gameCancelled;

  /// No description provided for @gameCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This game was cancelled. Entry fees were refunded. Next round starting…'**
  String get gameCancelledMessage;

  /// No description provided for @bulkConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to preview · X to remove · Register when ready'**
  String get bulkConfirmHint;

  /// No description provided for @bulkRemoveCartela.
  ///
  /// In en, this message translates to:
  /// **'Remove cartela #{number}'**
  String bulkRemoveCartela(int number);

  /// No description provided for @bulkReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select at least one cartela to register.'**
  String get bulkReviewEmpty;

  /// No description provided for @bulkRegisterCount.
  ///
  /// In en, this message translates to:
  /// **'Register {count}'**
  String bulkRegisterCount(int count);

  /// No description provided for @bulkRegisterError.
  ///
  /// In en, this message translates to:
  /// **'Could not register selected cartelas. Please try again.'**
  String get bulkRegisterError;

  /// No description provided for @bulkRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not register selected cartelas.'**
  String get bulkRegisterFailed;

  /// No description provided for @bulkRegisterTaken.
  ///
  /// In en, this message translates to:
  /// **'Could not register selected cartelas. {numbers} already taken.'**
  String bulkRegisterTaken(String numbers);

  /// No description provided for @depositHistoryRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref}'**
  String depositHistoryRef(String ref);

  /// No description provided for @depositHistoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry verification'**
  String get depositHistoryRetry;

  /// No description provided for @depositHistoryRetriedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification retried. Status: {status}.'**
  String depositHistoryRetriedStatus(String status);

  /// No description provided for @depositHistoryCouldNotRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not retry verification.'**
  String get depositHistoryCouldNotRetry;

  /// No description provided for @withdrawHistoryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String withdrawHistoryPhone(String phone);

  /// No description provided for @withdrawHistoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account: {account}'**
  String withdrawHistoryAccount(String account);

  /// No description provided for @withdrawHistoryNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String withdrawHistoryNote(String note);

  /// No description provided for @drawerBigGame.
  ///
  /// In en, this message translates to:
  /// **'Big Game'**
  String get drawerBigGame;

  /// No description provided for @bigGameNoScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'No Big Game scheduled yet.'**
  String get bigGameNoScheduledTitle;

  /// No description provided for @bigGameNoScheduledBody.
  ///
  /// In en, this message translates to:
  /// **'Check back soon.'**
  String get bigGameNoScheduledBody;

  /// No description provided for @bigGameScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Big Game Scheduled'**
  String get bigGameScheduledTitle;

  /// No description provided for @bigGameRegistrationOpensIn.
  ///
  /// In en, this message translates to:
  /// **'Registration opens in:'**
  String get bigGameRegistrationOpensIn;

  /// No description provided for @bigGameRegistrationOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Big Game Registration Open'**
  String get bigGameRegistrationOpenTitle;

  /// No description provided for @bigGamePlayStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Play starts in:'**
  String get bigGamePlayStartsIn;

  /// No description provided for @bigGameFixedPrize.
  ///
  /// In en, this message translates to:
  /// **'Fixed Prize'**
  String get bigGameFixedPrize;

  /// No description provided for @bigGameEntryFee.
  ///
  /// In en, this message translates to:
  /// **'Entry Fee'**
  String get bigGameEntryFee;

  /// No description provided for @bigGamePlayStartTime.
  ///
  /// In en, this message translates to:
  /// **'Play Start Time'**
  String get bigGamePlayStartTime;

  /// No description provided for @bigGameMaxCartelas.
  ///
  /// In en, this message translates to:
  /// **'Max Cartelas'**
  String get bigGameMaxCartelas;

  /// No description provided for @bigGameYourCartelas.
  ///
  /// In en, this message translates to:
  /// **'Your Cartelas'**
  String get bigGameYourCartelas;

  /// No description provided for @bigGameReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Big Game is ready'**
  String get bigGameReadyTitle;

  /// No description provided for @bigGameWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for current round to finish.'**
  String get bigGameWaitingBody;

  /// No description provided for @gameCategoryNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Game'**
  String get gameCategoryNormal;

  /// No description provided for @gameCategoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus Game'**
  String get gameCategoryBonus;

  /// No description provided for @gameCategoryBigGotd.
  ///
  /// In en, this message translates to:
  /// **'Big GOTD'**
  String get gameCategoryBigGotd;

  /// No description provided for @gameCategoryBigGame.
  ///
  /// In en, this message translates to:
  /// **'Big Game'**
  String get gameCategoryBigGame;

  /// No description provided for @gameBonusFreeEntry.
  ///
  /// In en, this message translates to:
  /// **'Free entry'**
  String get gameBonusFreeEntry;

  /// No description provided for @gameBonusFixedPrize.
  ///
  /// In en, this message translates to:
  /// **'Fixed prize: {amount}'**
  String gameBonusFixedPrize(String amount);

  /// No description provided for @gameBonusMaxCartelas.
  ///
  /// In en, this message translates to:
  /// **'Max {count} cartelas'**
  String gameBonusMaxCartelas(int count);

  /// No description provided for @gameStatusRegistrationOpen.
  ///
  /// In en, this message translates to:
  /// **'Registration Open'**
  String get gameStatusRegistrationOpen;

  /// No description provided for @gameStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get gameStatusPreparing;

  /// No description provided for @gameStatusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get gameStatusPlaying;

  /// No description provided for @gameStatusWinnerWindow.
  ///
  /// In en, this message translates to:
  /// **'Winner Window'**
  String get gameStatusWinnerWindow;

  /// No description provided for @gameStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get gameStatusFinished;

  /// No description provided for @gameStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get gameStatusCancelled;

  /// No description provided for @gameStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get gameStatusChecking;

  /// No description provided for @gameStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get gameStatusWaiting;

  /// No description provided for @gameStatusRegistrationClosed.
  ///
  /// In en, this message translates to:
  /// **'Registration Closed'**
  String get gameStatusRegistrationClosed;

  /// No description provided for @gameTimelineRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get gameTimelineRegistration;

  /// No description provided for @gameTimelinePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get gameTimelinePreparing;

  /// No description provided for @gameTimelinePlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get gameTimelinePlaying;

  /// No description provided for @gameTimelineWinnerWindow.
  ///
  /// In en, this message translates to:
  /// **'Winner Window'**
  String get gameTimelineWinnerWindow;

  /// No description provided for @gameTimelineFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get gameTimelineFinished;

  /// No description provided for @gameTimelineSemantics.
  ///
  /// In en, this message translates to:
  /// **'Game stage: {stage}'**
  String gameTimelineSemantics(String stage);

  /// No description provided for @gamesHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesHubTitle;

  /// No description provided for @gamesHubLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get gamesHubLiveNow;

  /// No description provided for @gamesHubComingNext.
  ///
  /// In en, this message translates to:
  /// **'Coming Next'**
  String get gamesHubComingNext;

  /// No description provided for @gamesHubBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus Game'**
  String get gamesHubBonus;

  /// No description provided for @gamesHubUpcomingEvent.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Event'**
  String get gamesHubUpcomingEvent;

  /// No description provided for @gamesHubNoLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No live game right now'**
  String get gamesHubNoLiveTitle;

  /// No description provided for @gamesHubNoLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Check back soon for the next round.'**
  String get gamesHubNoLiveBody;

  /// No description provided for @gamesHubNoBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Game not available'**
  String get gamesHubNoBonusTitle;

  /// No description provided for @gamesHubNoBonusBody.
  ///
  /// In en, this message translates to:
  /// **'No bonus round is scheduled today.'**
  String get gamesHubNoBonusBody;

  /// No description provided for @gamesHubStartsAfterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Starts after current round'**
  String get gamesHubStartsAfterCurrent;

  /// No description provided for @gamesHubJoinLive.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get gamesHubJoinLive;

  /// No description provided for @gamesHubOpenBonus.
  ///
  /// In en, this message translates to:
  /// **'Open Bonus Game'**
  String get gamesHubOpenBonus;

  /// No description provided for @gamesHubOpenBigGame.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get gamesHubOpenBigGame;

  /// No description provided for @gamesHubOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get gamesHubOpenHistory;

  /// No description provided for @gamesHubHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Review your past games and cartela results.'**
  String get gamesHubHistoryBody;

  /// No description provided for @gamesHubRegisteredCartelas.
  ///
  /// In en, this message translates to:
  /// **'Your cartelas: {count}'**
  String gamesHubRegisteredCartelas(int count);

  /// No description provided for @gamesHubBigGameSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in for Big Game'**
  String get gamesHubBigGameSignInTitle;

  /// No description provided for @gamesHubBigGameSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account to register for the Big Game.'**
  String get gamesHubBigGameSignInBody;

  /// No description provided for @gamesHubLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load games'**
  String get gamesHubLoadErrorTitle;

  /// No description provided for @announcementBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Game Today'**
  String get announcementBonusTitle;

  /// No description provided for @announcementBonusBody.
  ///
  /// In en, this message translates to:
  /// **'Starts after current round'**
  String get announcementBonusBody;

  /// No description provided for @announcementBonusAction.
  ///
  /// In en, this message translates to:
  /// **'Play Free'**
  String get announcementBonusAction;

  /// No description provided for @announcementBigGameTitle.
  ///
  /// In en, this message translates to:
  /// **'BIG GAME'**
  String get announcementBigGameTitle;

  /// No description provided for @announcementBigGamePrize.
  ///
  /// In en, this message translates to:
  /// **'Prize {amount} ETB'**
  String announcementBigGamePrize(String amount);

  /// No description provided for @announcementBigGameStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get announcementBigGameStartsIn;

  /// No description provided for @announcementBigGameAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get announcementBigGameAction;

  /// No description provided for @announcementBigGameWaiting.
  ///
  /// In en, this message translates to:
  /// **'Big Game ready — waiting for current round'**
  String get announcementBigGameWaiting;

  /// No description provided for @announcementBigGameLive.
  ///
  /// In en, this message translates to:
  /// **'Big Game is live now'**
  String get announcementBigGameLive;

  /// No description provided for @bigGameLivePrompt.
  ///
  /// In en, this message translates to:
  /// **'Big Game is in progress — Go to Big Game'**
  String get bigGameLivePrompt;

  /// No description provided for @bigGameGoAction.
  ///
  /// In en, this message translates to:
  /// **'Go to Big Game'**
  String get bigGameGoAction;

  /// No description provided for @announcementDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss announcement'**
  String get announcementDismiss;

  /// No description provided for @adminMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get adminMessagesTitle;

  /// No description provided for @adminMessagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get adminMessagesEmpty;

  /// No description provided for @adminMessagesDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss message'**
  String get adminMessagesDismiss;

  /// No description provided for @adminMessagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages. Pull to refresh and try again.'**
  String get adminMessagesLoadError;

  /// No description provided for @adminMessagesPersistentBadge.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get adminMessagesPersistentBadge;

  /// No description provided for @adminMessagesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get adminMessagesLoading;

  /// No description provided for @adminMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification} other{{count} notifications}}'**
  String adminMessagesCount(int count);

  /// No description provided for @adminMessagesForcedHint.
  ///
  /// In en, this message translates to:
  /// **'The app will reopen when the admin removes this notice.'**
  String get adminMessagesForcedHint;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @drawerSendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get drawerSendFeedback;

  /// No description provided for @drawerMyFeedback.
  ///
  /// In en, this message translates to:
  /// **'My feedback'**
  String get drawerMyFeedback;

  /// No description provided for @supportSendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get supportSendFeedbackTitle;

  /// No description provided for @supportSendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share feedback, a complaint, or advice. We read every message.'**
  String get supportSendFeedbackSubtitle;

  /// No description provided for @supportCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportCategoryLabel;

  /// No description provided for @supportCategoryFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get supportCategoryFeedback;

  /// No description provided for @supportCategoryComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get supportCategoryComplaint;

  /// No description provided for @supportCategoryAdvice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get supportCategoryAdvice;

  /// No description provided for @supportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportCategoryOther;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened or what we can improve'**
  String get supportMessageHint;

  /// No description provided for @supportSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get supportSendButton;

  /// No description provided for @supportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'We received your message'**
  String get supportMessageSent;

  /// No description provided for @supportMessageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your message. Please try again.'**
  String get supportMessageSendFailed;

  /// No description provided for @supportMyFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'My feedback'**
  String get supportMyFeedbackTitle;

  /// No description provided for @supportFeedbackHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get supportFeedbackHubTitle;

  /// No description provided for @supportMyFeedbackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message} other{{count} messages}}'**
  String supportMyFeedbackCount(int count);

  /// No description provided for @supportMyFeedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not sent any feedback yet.'**
  String get supportMyFeedbackEmpty;

  /// No description provided for @supportAdminResponse.
  ///
  /// In en, this message translates to:
  /// **'Admin response'**
  String get supportAdminResponse;

  /// No description provided for @supportAdminName.
  ///
  /// In en, this message translates to:
  /// **'Friends Bingo'**
  String get supportAdminName;

  /// No description provided for @supportYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYouLabel;

  /// No description provided for @supportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusReplied.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get supportStatusReplied;

  /// No description provided for @supportStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportStatusClosed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'om', 'ti'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
    case 'ti':
      return AppLocalizationsTi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
