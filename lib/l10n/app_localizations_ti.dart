// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tigrinya (`ti`).
class AppLocalizationsTi extends AppLocalizations {
  AppLocalizationsTi([String locale = 'ti']) : super(locale);

  @override
  String get appTitle => 'ፍሬንድስ ቢንጎ';

  @override
  String get appBarHi => 'ሰላም፣ ';

  @override
  String get appBarRefreshTooltip => 'Refresh';

  @override
  String get signIn => 'እቶ';

  @override
  String get signUp => 'መመዝገቢ';

  @override
  String get logout => 'ውጻእ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get themeLight => 'ብርሃን';

  @override
  String get themeDark => 'ጸልማት';

  @override
  String get themeAuto => 'ኣውቶ';

  @override
  String get theme => 'መልክ';

  @override
  String get firstLaunchPreferencesTitle => 'ተመኩሮኹም ምረጹ';

  @override
  String get firstLaunchPreferencesSubtitle =>
      'ንምጅማር መልክዐን ቋንቋን ምረጹ። ኣብ ዝኾነ እዋን ካብ ቅንብራት ክትቕይሩ ትኽእሉ ኢኹም።';

  @override
  String get firstLaunchPreferencesContinue => 'ቀጽል';

  @override
  String get firstLaunchPreferencesSkip => 'ስገር';

  @override
  String get loginTitle => 'Welcome';

  @override
  String get loginPhone => 'ቁጽሪ ተሌፎን';

  @override
  String get loginPhoneHint => '091*******';

  @override
  String get loginPassword => 'password';

  @override
  String get loginPasswordHint => 'password  የእቶ';

  @override
  String get loginForgotPassword => 'password  ረሲዕካ?';

  @override
  String get loginSignIn => 'እቶ';

  @override
  String get loginCreateAccount => 'ሓድሽ ኣካውንት ፍጠር';

  @override
  String get registerFullName => 'ምሉእ ስም';

  @override
  String get registerFullNameHint => 'ምሉእ ስም';

  @override
  String get registerPassword => 'password ';

  @override
  String get registerPasswordHint => 'ቢያንስ 6 ፊደላት';

  @override
  String get registerConfirmPassword => 'password  ኣረጋግጽ';

  @override
  String get registerConfirmPasswordHint => 'password  ደጊምካ እቶ';

  @override
  String get registerContinue => 'ቀጽል';

  @override
  String get registerAlreadyHaveAccount => 'ኣካውንት ታሃሊካ? በዚ እቶ';

  @override
  String get forgotPasswordTitle => 'password ስበር';

  @override
  String get forgotPasswordSubtitle => 'ናይ ምርግጋጽ ኮድ ንምርካብ ቁጽሪ ተሌፎንካ እቶ።';

  @override
  String get forgotPasswordSendCode => 'ናይ ምርግጋጽ ኮድ ስደድ';

  @override
  String get forgotPasswordBackToSignIn => 'ተመለስ';

  @override
  String get otpVerifyPhone => 'ተሌፎንካ ኣረጋግጽ';

  @override
  String otpSentTo(String phone) {
    return 'ኮድ ናብ $phone ተላኢኹ።';
  }

  @override
  String get otpCreateAccount => 'ኣካውንት ፍጠር';

  @override
  String get otpResendCode => 'ኮድ ደጊምካ ስደድ';

  @override
  String otpResendInSeconds(int seconds) {
    return 'ኣብ $seconds ካልኢታት ደጊምካ ስደድ';
  }

  @override
  String otpResendInMinutes(int minutes) {
    return 'ኣብ $minutes ደቒቃታት ደጊምካ ስደድ';
  }

  @override
  String otpResendInMinutesSeconds(int minutes, int seconds) {
    return 'ኣብ $minutesደ $secondsሰ ደጊምካ ስደድ';
  }

  @override
  String get otpBackToDetails => 'ናብ ዝርዝር ተመለስ';

  @override
  String get otpEnterCode => '4 ቁጽሪ ናይ ምርግጋጽ ኮድ እቶ።';

  @override
  String get otpSmsBanner => 'ብSMS ናብ ተሌፎንካ ዝተለኣኸ ኮድ እቶ።';

  @override
  String get resetPasswordTitle => 'ሓድሽ ፓሥዎርድ ቃል ኣዳሉ';

  @override
  String resetPasswordSmsSentTo(String phone) {
    return 'ናብ $phone ዝተለኣኸ SMS ኮድ እቶ።';
  }

  @override
  String get resetPasswordNewPassword => 'ሓድሽ  ቃል';

  @override
  String get resetPasswordConfirmNew => 'ሓድሽ ፓሥዎርድ ቃል ኣረጋግጽ';

  @override
  String get resetPasswordConfirmNewHint => 'ሓድሽ ፓሥዎርድ ቃልካ ደጊምካ እቶ';

  @override
  String get resetPasswordUpdate => 'ፓሥዎርድ ቃል ዘምን';

  @override
  String get resetPasswordBackToPhone => 'ናብ ቁጽሪ ተሌፎን ተመለስ';

  @override
  String get validatorPhoneRequired => 'ቁጽሪ ተሌፎን የድሊ።';

  @override
  String get validatorPhoneInvalid => 'ቅቡል ቁጽሪ ተሌፎን እቶ።';

  @override
  String get validatorPasswordLength => 'password ቃል ቢያንስ 6 ፊደላት ክህልዎ ኣለዎ።';

  @override
  String get validatorFullNameLength => 'ምሉእ ስም ቢያንስ 3 ፊደላት ክህልዎ ኣለዎ።';

  @override
  String get validatorPasswordMismatch => 'password ቃላት ኣይሰማምዑን።';

  @override
  String get validatorAmountRequired => 'መጠን የድሊ።';

  @override
  String get validatorAmountInvalid => 'ቅቡል መጠን የየእቶ።';

  @override
  String get validatorAmountPositive => 'መጠን ካብ ዜሮ ንላዕሊ ክኸውን ኣለዎ።';

  @override
  String validatorDepositAmountMin(String amount) {
    return 'ዝቅተኛ ተቀማጭ $amount ብር እዩ።';
  }

  @override
  String validatorDepositAmountMax(String amount) {
    return 'ዝለዓለ ተቀማጭ $amount ብር እዩ።';
  }

  @override
  String validatorWithdrawAmountMin(String amount) {
    return 'ዝቅተኛ ወጻኢ $amount ብር እዩ።';
  }

  @override
  String validatorWithdrawAmountMax(String amount) {
    return 'ዝለዓለ ወጻኢ $amount ብር እዩ።';
  }

  @override
  String depositAmountRangeHelper(String min, String max) {
    return 'ተቀማጭ ካብ $min ክሳብ $max ብር።';
  }

  @override
  String withdrawAmountRangeHelper(String min, String max) {
    return 'ወጻኢ ካብ $min ክሳብ $max ብር። ኣስተዳዳሪ ጠለብካ ክሕዝ ድማይ እዚ መጠን ክቖለፍ እዩ።';
  }

  @override
  String get validatorTransactionRef => 'ቅቡል ናይ ዕዳጋ ምልክት የየእቶ።';

  @override
  String dashboardHello(String name) {
    return 'ሰላም፣ $name';
  }

  @override
  String get dashboardSubtitle =>
      'ቀጥታ ጸወታ ክፈት፣ ካርቴላታትካ መመዝገብ፣ ዋሊትካዋሊትካ ካብ ሓደ ቦታ ተቆጻጸር።';

  @override
  String get dashboardOpenLiveGame => 'ቀጥታ ጸወታ ክፈት';

  @override
  String get dashboardRole => 'ሚና';

  @override
  String get dashboardStatus => 'ኩነታት';

  @override
  String get dashboardWalletSnapshot => 'ናይ ዋሊት ቅጽበት';

  @override
  String dashboardAvailableBalance(String amount) {
    return 'ዘሎ ቀሪ: $amount ብር';
  }

  @override
  String dashboardLockedBalance(String amount) {
    return 'ዝተቆለፈ ቀሪ: $amount ብር';
  }

  @override
  String get dashboardOpenWallet => 'ዋሊት ክፈት';

  @override
  String get dashboardWalletLoading => 'ዋሊት ይጽዓን ኣሎ...';

  @override
  String get dashboardWalletUnavailable => 'ዋሊት ሕጂ ኣይርከብን።';

  @override
  String get dashboardWhatIsNext => 'ዝቕጽል እንታይ እዩ';

  @override
  String get dashboardWhatIsNextBody =>
      'ዝቕጽሉ ስጉምቲታት ቀጥታ ዝተጸዉዑ ቁጽሪታት፣ ናይ ቢንጎ ጠለባት፣ ክፍሊታትን ወጻኢታትን ናብዚ ቅርጺ ይምልሱ።';

  @override
  String get houseChampionsTitle => 'ናይ ቤት ኣሸናፍቲ';

  @override
  String get houseChampionsSubtitle =>
      'ብዝሓለፈ ካርቴላ ዝዓበዩ ተጻወትቲ። ኣብ ታሕቲ ዘሎ ዝርዝር ካብ ምረጽ።';

  @override
  String get houseChampionsSelectPeriod => 'ደረጃ ንምርኣይ';

  @override
  String get houseChampionsViewAll => 'ኩሉ ርአ';

  @override
  String get houseChampionsFairnessNote => 'ብዝሓለፈ ካርቴላ ይደረግ፣ ብመጠን ሽልክ ኣይደረግን።';

  @override
  String get houseChampionsLoadError => 'ናይ ቤት ኣሸናፍቲ ምጽዓን ኣይተኻእለን።';

  @override
  String get houseChampionsEmpty => 'ንዚ ግዜ ኣሁን ኣሸናፊ የለን። ቀዳማይ ኩን።';

  @override
  String get houseChampionsPeriodToday => 'ሎሚ';

  @override
  String get houseChampionsPeriodThisWeek => 'እዚ ሰሙን';

  @override
  String get houseChampionsPeriodLastWeek => 'ዝሓለፈ ሰሙን';

  @override
  String get houseChampionsPeriodLast7Days => 'ዝሓለፉ 7 መዓልቲ';

  @override
  String get houseChampionsPeriodLast30Days => 'ዝሓለፉ 30 መዓልቲ';

  @override
  String get houseChampionsPeriodAllTime => 'ኩሉ ግዜ';

  @override
  String houseChampionsPeriodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String houseChampionsYourRank(int rank, int wins) {
    return 'ቁጽሪ $rank ኢኻ ብ $wins ዓወት';
  }

  @override
  String houseChampionsWins(int count) {
    return '$count ዓወት';
  }

  @override
  String houseChampionsGamesWon(int count) {
    return '$count ጸወታታት ዓዊቱ';
  }

  @override
  String get walletAvailableBalance => 'ዘሎ ቀሪ';

  @override
  String get walletLockedBalance => 'ዝተቆለፈ ቀሪ';

  @override
  String get walletFreezBalance => 'Freez balance';

  @override
  String get walletTotalBalance => 'ጠቕላላ ዋሌት';

  @override
  String get walletTotalEqualsHint => 'ዝርከብ + ዝተቖለፈ = ጠቕላላ ዋሌት';

  @override
  String get welcomeBonusTitle => 'እንቋዕ ብደሓን መጻእካ ቦነስ';

  @override
  String welcomeBonusBody(int count) {
    return '$count ቦነስ ካርቴላታት ንንቡር ጸወታታት ኣለካ። ነፍሲ ወከፍ 1 ንቡር ጸወታ ካርቴላ ብዘይ ETB ቀሪኻ የመዝግብ። Big GOTD ከምኡ’ውን Big Game ናይ ዋሌት ገንዘብ ይጥቀሙ። ቦነስ ካርቴላታት ኣይወጹን።';
  }

  @override
  String get welcomeBonusDeniedDeviceAlreadyClaimed =>
      'እዚ መሳርሒ ቅድም ንቕድም እንቋዕ ብደሓን መጻእካ ቦነስ ተቐቢሉ። ኣካውንትኻ ድልው እዩ፣ ግን ነጻ ካርቴላታት ኣይርከቡን።';

  @override
  String get welcomeBonusDeniedUserAlreadyClaimed =>
      'ኣካውንትኻ ቅድም ንቕድም እንቋዕ ብደሓን መጻእካ ቦነስ ተቐቢሉ። ነጻ ካርቴላታት ዳግም ኣይርከቡን።';

  @override
  String get walletBonusCartelasLabel => 'ቦነስ ካርቴላታት (ንቡር ጸወታታት)';

  @override
  String registrationBonusBalanceLabel(int count) {
    return 'ቦነስ: $count';
  }

  @override
  String get walletDeposit => 'ኣታዊ ንምግባር';

  @override
  String get walletWithdraw => 'ኣውፅእ';

  @override
  String get walletTransactionHistory => 'ናይ ዋሊት ዝርዝር';

  @override
  String get walletTransactionHistorySubtitle => 'ኩሎም ናይ ዋሊት ምንቅስቓሳት ርኣ።';

  @override
  String get walletDepositHistory => 'ናይ ኣታዊ ዝርዝር';

  @override
  String get walletDepositHistorySubtitle =>
      'ናይ ምርግጋጽ ምዕባለ ተኸታተል ድሕሪኡ ደጊምካ ፈትን።';

  @override
  String get walletWithdrawalHistory => 'ናይ ኣውፅእ ዝርዝር';

  @override
  String get walletWithdrawalHistorySubtitle =>
      'ጠለብ፣ ምሕደራ ፈቓድ፣ ናይ ክፍሊት ኩነታት ተኸታተል።';

  @override
  String get walletCouldNotLoad => 'ናይ ዋሊት ዝርዝር ምምጻእ ኣይተኻእለን።';

  @override
  String get walletTryAgain => 'ደጊምካ ፈትን';

  @override
  String get depositScreenTitle => 'ኣታዊ';

  @override
  String get depositAmount => 'መጠን';

  @override
  String get depositFtNumber => 'FT ቁጽሪ';

  @override
  String get depositReceiptId => 'ደረሰኝ መለለዪ';

  @override
  String get depositReceiptCode => 'Receipt code';

  @override
  String get depositReceiptCodeInvalid =>
      'Enter a valid receipt code (6-20 letters and numbers).';

  @override
  String get depositReceiptUrlNotAllowed =>
      'Enter the receipt code only, not the full URL.';

  @override
  String get depositSuccessApproved => 'Deposit successful. Wallet updated.';

  @override
  String get depositReceiptDuplicate => 'This receipt has already been used.';

  @override
  String get depositReceiptInvalid => 'Receipt could not be verified.';

  @override
  String get depositAmountMismatch =>
      'Amount does not match this receipt. Enter the settled amount shown on the receipt.';

  @override
  String depositAmountMismatchSettled(String settledAmount) {
    return 'This receipt settled amount is $settledAmount ETB. Enter that amount—not the total paid amount (Telebirr fees are not deposited).';
  }

  @override
  String get depositReceiverMismatch =>
      'This receipt was not paid to Friends Bingo.';

  @override
  String get depositDevHelper => 'ናይ ምዕባለ/ሙከራ ሓጋዚ';

  @override
  String depositDevReference(String ref) {
    return 'ናይ ምዕባለ ሙከራ ምልክት: $ref';
  }

  @override
  String get depositUseTestRef => 'ናይ ሙከራ ምልክት ተጠቐም';

  @override
  String get depositSubmit => 'ኣታዊ ኣእቱ';

  @override
  String get depositGuideTitle => 'ከመይ ጌርካ ኣታዊ ትገብር';

  @override
  String get depositGuideTelebirrStep1 => 'ቴሌብር ክፈት ናብ ፈረንድስ ቢንጎ ገንዘብ ልኣኽ';

  @override
  String get depositGuideTelebirrStep2 => 'ደረሰኝ ክፈትን ናይ ግብይት ቁጽሪ ቅዳሕ';

  @override
  String get depositGuideTelebirrStep3 =>
      'እቲ ዝተኸፍለ መጠንን ናይ ደረሰኝ ኮድን ኣብ ታሕቲ ኣእቱ';

  @override
  String get depositGuideCbeStep1 => 'ሲቢኢ ባንኪ ክፈትን ናብ ፈረንድስ ቢንጎ ልኣኽ';

  @override
  String get depositGuideCbeStep2 => 'ካብ ደረሰኝ ናይ FT ምልክት ቅዳሕ';

  @override
  String get depositGuideCbeStep3 => 'ቅኑዕ መጠንን ምልክትን ኣብ ታሕቲ ኣእቱ';

  @override
  String get depositGuideAwashStep1 => 'ኣዋሽ ባንኪ ክፈትን ክፍሊት ልኣኽ';

  @override
  String get depositGuideAwashStep2 => 'ናይ ክፍሊት ምልክት ቅዳሕ';

  @override
  String get depositGuideAwashStep3 => 'ቅኑዕ መጠንን ምልክትን ኣብ ታሕቲ ኣእቱ';

  @override
  String get depositGuideBoaStep1 => 'ኤብኦኤ ባንኪ ክፈትን ክፍሊት ልኣኽ';

  @override
  String get depositGuideBoaStep2 => 'ናይ ክፍሊት ምልክት ቅዳሕ';

  @override
  String get depositGuideBoaStep3 => 'ቅኑዕ መጠንን ምልክትን ኣብ ታሕቲ ኣእቱ';

  @override
  String get depositVerifying => 'ክፍሊትካ ይረጋገጽ ኣሎ…';

  @override
  String get depositApprovedTitle => 'ኣታዊ ጸዲቑ';

  @override
  String get depositPendingTitle => 'ኣታዊ ቀሪቡ';

  @override
  String get depositPendingMessage =>
      'ኣታዊኻ ንፍቓድ ኣስተዳዳሪ ይጽበ። ኣብ ዝጸድቕ ድሕሪ ክፍሊትካ ክሞላ እዩ።';

  @override
  String get depositRefUnderReview => 'እዚ ማጣቀሻ እዚ ቀዲሙ ኣብ ግምገማ ኣስተዳዳሪ ኣሎ።';

  @override
  String get depositRejectedTitle => 'ኣታዊ ምግባር ኣይተኻእለን';

  @override
  String get depositTryAgain => 'ኣይተሳከዐን  ደጊምካ ፈትን።';

  @override
  String get depositSelectProvider => 'ኣገባብ ክፍሊት';

  @override
  String get depositSendToAccount => 'ናብዚ ሕሳብ ልኣኽ ኣዘር ባንክ አይካኣልን';

  @override
  String get depositSendToAccounts => 'ናብዞም ሕሳባት ልኣኽ';

  @override
  String get depositTelebirrAccount1 => 'ሕሳብ 1';

  @override
  String get depositTelebirrAccount2 => 'ሕሳብ 2';

  @override
  String get depositShowInstructions => 'መምርሒታት';

  @override
  String get depositReceiptReviewLabel =>
      'ካብ scrrenshot ዝመጸ ኮድ አና መጠን ኣረጋጊጸ ኣለኹ';

  @override
  String get depositCopyAccount => 'ሕሳብ ቅዳሕ';

  @override
  String get depositAccountCopied => 'ሕሳብ ተቐዲሑ';

  @override
  String get depositGuideImageMissing => 'ስክሪንሾት ኣብ ቀረባ እዋን';

  @override
  String get depositGuideTapToExpand => 'ንምስፍሓ ጠውቕ';

  @override
  String get walletQuickDeposit => 'ብሞባይል ገንዘብ ወይ ባንክ ብቐጥታ ገንዘብ ወስኽ';

  @override
  String get depositLatest => 'ኣብዚ ቀረባ ዝተገበረ ኣታዊ';

  @override
  String depositSubmittedStatus(String status) {
    return 'ኣታዊ  ኩነታት: $status።';
  }

  @override
  String get depositCouldNotSubmit => 'ኣታዊ ምግባር ኣይተኻእለን።';

  @override
  String get depositReceiptScan => 'Scan receipt';

  @override
  String get depositReceiptScreenshotHelperPrefix => 'ካብ ';

  @override
  String get depositReceiptScreenshotHelperLink => 'ስክሪንሾት';

  @override
  String get depositReceiptScreenshotHelperSuffix =>
      ' ክተመልእ ትኽእል ኢኻ፣ ቅድሚ submit ምግባሮም የረጋግጽ።';

  @override
  String get depositReceiptScanSuccess =>
      'Receipt detected. Please review before submitting.';

  @override
  String get depositReceiptScanPartial =>
      'Some details detected. Please review.';

  @override
  String get depositReceiptScanFailure =>
      'Could not read receipt. Please type manually.';

  @override
  String depositProvider(String provider) {
    return 'ኣቕራቢ: $provider';
  }

  @override
  String depositAmountLabel(String amount) {
    return 'መጠን: $amount';
  }

  @override
  String depositReference(String ref) {
    return 'ምልክት: $ref';
  }

  @override
  String depositCreated(String date) {
    return 'ተፈጢሩ: $date';
  }

  @override
  String depositRejectionReason(String reason) {
    return 'ምኽንያት: $reason';
  }

  @override
  String get depositHistoryTitle => 'ኣታዊ ዝተገበሩ ዝርዝር';

  @override
  String get depositHistoryEmpty => ' ኣታዊ የለን';

  @override
  String get depositHistoryEmptyMessage => 'ናይ ኣታዊ ጠለባትካ ኣብዚ ክርኣዩ እዮም።';

  @override
  String get depositHistoryCouldNotLoad => 'ናይ ኣታዊ ዝተገበሩ ዝርዝር ምምጻእ ኣይተኻእለን።';

  @override
  String get depositRetryVerification => 'ንምርግጋጽ ደጊምካ ፈትን';

  @override
  String depositRetried(String status) {
    return 'ምርግጋጽ ተደጊሙ ኣሎ። ኩነታት: $status።';
  }

  @override
  String get depositRetryFailed => 'ምርግጋጽ ደጊምካ ምፍታን ኣይተኻእለን።';

  @override
  String depositAmountRow(String amount) {
    return 'መጠን: $amount';
  }

  @override
  String depositRefRow(String ref) {
    return 'ምልክት: $ref';
  }

  @override
  String depositCreatedRow(String date) {
    return 'ተፈጢሩ: $date';
  }

  @override
  String depositReasonRow(String reason) {
    return 'ምኽንያት: $reason';
  }

  @override
  String get withdrawScreenTitle => 'ወፃኢ';

  @override
  String get withdrawAmount => 'መጠን';

  @override
  String get withdrawSubmit => 'ወፃኢ ኣቕርብ';

  @override
  String get withdrawLatest => 'ናይ ቀረባ ወፃኢታት';

  @override
  String withdrawSubmittedStatus(String status) {
    return 'ወፃኢ  ኩነታት: $status።';
  }

  @override
  String get withdrawCouldNotSubmit => 'ወፃኢ ምቕራብ ኣይተኻእለን።';

  @override
  String withdrawStatusLabel(String status) {
    return 'ኩነታት: $status';
  }

  @override
  String withdrawProviderLabel(String provider) {
    return 'ኣቕራቢ: $provider';
  }

  @override
  String withdrawAmountLabel(String amount) {
    return 'መጠን: $amount';
  }

  @override
  String withdrawPhoneLabel(String phone) {
    return 'ተሌፎን: $phone';
  }

  @override
  String withdrawAccountLabel(String account) {
    return 'ኣካውንት: $account';
  }

  @override
  String withdrawCreatedLabel(String date) {
    return 'ተፈጢሩ: $date';
  }

  @override
  String withdrawNoteLabel(String note) {
    return 'መዘኻኸሪ: $note';
  }

  @override
  String get withdrawHistoryTitle => 'ናይ ወፃኢታት ዝርዝር';

  @override
  String get withdrawHistoryEmpty => 'ገና ወፃኢ የለን';

  @override
  String get withdrawHistoryEmptyMessage => 'ናይ ወፃኢ ጠለባትካ ኣብዚ ክርኣዩ እዮም።';

  @override
  String get withdrawHistoryCouldNotLoad => 'ናይ ወፃኢ ዝርዝር ምምጻእ ኣይተኻእለን።';

  @override
  String get withdrawSelectProvider => 'ናይ ክፍሊት መንገዲ';

  @override
  String get withdrawMaxWithdrawableHint =>
      'ክሳብ ዘለካ ዝርከብ ቀሪ ሂሳብ ክትወፅእ ትኽእል ኢኻ። እቲ ዝተረፈ ንካርቴላ ምዝገባ ይጥቀም።';

  @override
  String get withdrawLockedFundsHint =>
      'ዝተቖለፉ ገንዘባታት ንዘለዉ ናይ ወፃኢ ጠለባት ተይዞም ኣለዉ።';

  @override
  String get withdrawAmountLockedHelper =>
      'ኣስተዳዳሪ ጠለብካ ክሕዝ ድማይ እዚ መጠን ክቖለፍ እዩ።';

  @override
  String get withdrawAmountExceedsAvailable =>
      'እቲ መጠን ካብ ዘለካ ዝርከብ ቀሪ ሂሳብ ይዝያየ።';

  @override
  String get withdrawPendingTitle => 'ወፃኢ ቀሪቡ';

  @override
  String get withdrawPendingMessage =>
      'ጠለብካ ንኣስተዳዳሪ ግምገማ ይጽበ። እቲ መጠን ክሕዝ ወይ ክኸይድ ድማይ ክቖለፍ እዩ።';

  @override
  String get withdrawApprovedTitle => 'ወፃኢ ተጸዲቑ';

  @override
  String get withdrawApprovedMessage => 'ክፍልትካ ተጸዲቑ ተላኢኹ።';

  @override
  String get withdrawRejectedTitle => 'ወፃኢ ተነጺጉ';

  @override
  String get withdrawRejectedMessage =>
      'ወፃኢኻ ተነጺጉ። ዝተቖለፈ ገንዘብ ናብ ቀሪ ሂሳብካ ተመሊሱ።';

  @override
  String get withdrawStatusPendingReview => 'ግምገማ ይጽበ';

  @override
  String get withdrawStatusApproved => 'ተጸዲቑ';

  @override
  String get withdrawStatusRejected => 'ተነጺጉ';

  @override
  String get withdrawStatusFailed => 'ኣይተሳኸዐን';

  @override
  String get withdrawStatusRefunded => 'ተመሊሱ';

  @override
  String get walletLockedBalanceHint => 'ንዘለዉ ናይ ወፃኢ ጠለባት ዝተይዙ ገንዘባታት ዘጠቓልል።';

  @override
  String get withdrawRequestsTitle => 'ናይ ወፃኢ ጠለባትካ';

  @override
  String get withdrawTabAll => 'ኩሉ';

  @override
  String get withdrawTabPending => 'ይጽበ';

  @override
  String get withdrawTabCompleted => 'ተዛዚሙ';

  @override
  String get withdrawTabRejected => 'ተነጺጉ';

  @override
  String get withdrawTableDate => 'ዕለት';

  @override
  String get withdrawTableAmount => 'መጠን';

  @override
  String get withdrawTableProvider => 'ኣቕራቢ';

  @override
  String get withdrawTableStatus => 'ኩነታት';

  @override
  String get withdrawPendingEmpty => 'ዘለዉ ናይ ወፃኢ ጠለባት የለን።';

  @override
  String get withdrawCompletedEmpty => 'ገና ዝተዛዘመ ወፃኢ የለን።';

  @override
  String get withdrawRejectedEmpty => 'ዝተነጸገ ወፃኢ የለን።';

  @override
  String get txHistoryTitle => 'ናይ  ዕዳጋታት';

  @override
  String get txHistoryEmpty => 'ገና ዕዳጋ የለን';

  @override
  String get txHistoryEmptyMessage =>
      'ድሕሪ ኣታዊ፣ ምዝገባ፣ ወፃኢ ናይ ዋሊት  ዝርዝር ኣብዚ ክርኣይ እዩ።';

  @override
  String txHistoryShowing(int count, int total) {
    return 'ካብ $total ዕዳጋታት $count ይርኣዩ';
  }

  @override
  String get txHistoryWalletActivity => 'ናይ ዋሊት ምንቅስቓስ';

  @override
  String get txWithdrawRequestLockedNote => 'ንግምገማ ዝጽበ ናብ ዝተቖለፈ ቀሪ ተሰጋጊሩ።';

  @override
  String txHistoryBalanceAfter(String amount) {
    return 'ቀሪ: $amount';
  }

  @override
  String get txHistoryCouldNotLoad => 'ናይ ዕዳጋ ዝርዝር ምምጻእ ኣይተኻእለን።';

  @override
  String get gameHistoryTitle => 'ናይ ጸወታ ዝርዝር';

  @override
  String get gameHistoryEmpty => 'ገና ዝተወደአ ጸወታ የለን።';

  @override
  String gameHistoryCards(int count) {
    return '$count ካርዳት';
  }

  @override
  String get gameHistoryLoadingAttended => 'ናይ ጸወታታትካ ይጽዕን...';

  @override
  String get gameHistoryEmptyAttended => 'ክሳዕ ሕጂ ዝተወደኡ ዝተሳተፍካሎም ጸወታታት የለን።';

  @override
  String get gameHistoryDetailTitle => 'ዝርዝር ጸወታ';

  @override
  String get gameHistoryPrizePool => 'ጠቕላላ ሽልማት';

  @override
  String gameHistoryYourWinnings(String amount) {
    return '$amount ኣሸኒፍካ';
  }

  @override
  String get gameHistoryYourCartelas => 'ካርዳትካ';

  @override
  String get gameHistorySessionWinners => 'ኣሸነፍቲ ጸወታ';

  @override
  String gameHistoryMyCartelaCount(int count) {
    return '$count ናትካ';
  }

  @override
  String get gameHistoryLoadMore => 'ተወሳኺ ጽዕን';

  @override
  String get gameHistoryRetry => 'እንደገና ፈትን';

  @override
  String get gameStatsLabel => 'ናይ ጸወታ ስታቲስቲክስ';

  @override
  String get gameHideStats => 'ስታቲስቲክስ ሕብእ';

  @override
  String get gameShowStats => 'ስታቲስቲክስ ኣርኣ';

  @override
  String get gameEntryLabel => 'መእቶዊ';

  @override
  String get gamePrizeLabel => 'ሽልማት';

  @override
  String get gameRegLabel => 'ምዝ';

  @override
  String get gameCalledLabel => 'ዝተጸዋዑ';

  @override
  String get gameNowPlaying => 'ሕጂ ይጻወት';

  @override
  String get gameNextGame => 'ዝቕጽል ጸወታ';

  @override
  String get liveCalledNumbersLabel => 'ዝተጸውዑ ቁጽሪታት';

  @override
  String get liveNextRoundSectionTitle => 'ዝቕጽል ዙር';

  @override
  String get liveJoinCurrentRoundSectionTitle => 'ናይ ሕጂ ዙር ተጸንበር';

  @override
  String get liveMissedCurrentRoundTitle => 'እዚ ዙር ሕጂ ይጻወት ኣሎ';

  @override
  String get liveNextQueuedPlayLabel => 'ዝቕጽል ተራ ጸወታ';

  @override
  String get liveRegisteredCartelasLabel => 'ዝተመዝገቡ ካርቴላታት';

  @override
  String get liveRegisteredCartelasEmpty => 'ገና የለን — ኣብ ታሕቲ ቁጽሪታት ምረጽ።';

  @override
  String get liveMissedRoundHelper => 'ነዚ ዙር ሓሊፍካዮ። ንዝቕጽል ተራ ጸወታ ሕጂ ተመዝገብ።';

  @override
  String get liveMissedRoundYouMissedGame => 'ነዚ ዙር ሓሊፍካዮ።';

  @override
  String get liveMissedNoNextTitle => 'ነዚ ዙር ሓሊፍካዮ';

  @override
  String get liveMissedNoNextMessage =>
      'እዚ ጸወታ ሕጂ ብቀጥታ ይጻወት ኣሎ፣ ምዝገባውን ተዓጽዩ። ዝቕጽል ዙር ምስ ተኸፍተ ካርቴላታት ኣብዚ ክትመዝገብ ትኽእል።';

  @override
  String get liveMissedNoNextTipWatch => 'ነቲ ጸወታ ንምክትታል ኣብ ላዕሊ ዝወጹ ቁጽርታት ርአ።';

  @override
  String get liveMissedNoNextTipRefresh => 'ዝቕጽል ዙር ምስ ድልዩ ንታሕቲ ስሓብካ ኣሐድስ።';

  @override
  String get liveMissedRoundOverviewTitle => 'ቀጥታ & ዝቕጽል ዙር';

  @override
  String liveMissedRoundCollapsedMissed(String gameName) {
    return 'ዝሓለፍካ ጨወታ · $gameName ድሕሪ ዝተወሰን ደቃይቅ ክውዳእ እዩ ';
  }

  @override
  String liveMissedRoundCollapsedNextReady(String gameName) {
    return 'ዝቕጽል ዝተዳለወ ጨወታ · $gameName · ሕጂ ምምዝገብ ይካኣል እዩ';
  }

  @override
  String get liveMissedRoundRegisterBridge =>
      'ንዝቕጽል ጸወታ ሕጂ ካርቴላ ተመዝገብ ከምኡ ኣብ ዝቕጽል ዙር ተጻወት።';

  @override
  String liveJoinCurrentRoundGameLive(String gameName) {
    return '$gameName ሕጂ ቀጥታ ይጻወት ኣሎ';
  }

  @override
  String get liveNextGameBannerTitle => 'ዝቕጽል ጸወታ';

  @override
  String get liveMissedRoundBannerSubtitle => 'ዝቕጽል ጸወታ ብቐረባ ክጅምር እዩ';

  @override
  String get liveNextGameLabel => 'ዝቕጽል ጸወታ';

  @override
  String get registrationStartsAfterCurrentGame =>
      'Registration open - starts after current game';

  @override
  String get liveJoinCurrentRoundHelper =>
      'ምዝገባ ንዚ ቀጥታ ዙር ኣሁን እውን ክፉት እዩ። ዝተተሓዙን ዝተመዝገቡን ካርቴላታት ብኣውቶማቲክ ይዕጸዉ።';

  @override
  String get liveAddMoreCartelasHelper =>
      'ምዝገባ ኣሁን እውን ክፉት እዩ። እቲ ዙር እንተሃለወ ተወሳኺ ካርቴላታት ክትውስኽ ትኽእል።';

  @override
  String get liveAddMoreCartelasTitle => 'ተወሳኺ ካርቴላታት ወስኽ';

  @override
  String get liveNextRoundRegistrationTitle => 'ምዝገባ ዝቕጽል ዙር';

  @override
  String get gameRuleDetailTitle => 'ሕግ ጸወታ';

  @override
  String get gameRulePatternSample => 'ኣብነታዊ ዓውደራ ኣሸነፍቲ';

  @override
  String get gameNextGameHide => 'ዝቕጽል ጸወታ ሕብእ';

  @override
  String get gameNextGameShow => 'ዝቕጽል ጸወታ ኣርኢ';

  @override
  String get leaveLiveGameTitle => 'ቀጥታ ጸወታ ትሰግር?';

  @override
  String get leaveLiveGameMessage =>
      'ጸወታኻ ኣብ ሰርቨር ክቕጽል እዩ። ዝተመልከትካዮም ሴሎች ኣብዚ መሳርሒ ይቐመጡ።';

  @override
  String get leaveLiveGameStay => 'ቀን';

  @override
  String get leaveLiveGameLeave => 'ወጻኢ';

  @override
  String get confirmBackTitle => 'ንክትመልስ ትደሊ?';

  @override
  String get confirmBackMessage => 'እዚ ገጽ ክትሰግር ትደሊ?';

  @override
  String get confirmBackStay => 'ቀን';

  @override
  String get confirmBackLeave => 'ወጻኢ';

  @override
  String get exitAppTitle => 'ኣፕሊኬሽን ዕጾ?';

  @override
  String get exitAppMessage => 'ጸወታኻ ክቕጽል እዩ። በይኑ ጊዜ ክትምለሱ ትኽእሉ።';

  @override
  String get exitAppStay => 'ቀን';

  @override
  String get exitAppExit => 'ዕጾ';

  @override
  String get developerModeBlockedTitle => 'Security check';

  @override
  String get developerModeBlockedMessage =>
      'Developer options are turned on. Turn them off in your phone settings to use Friends Bingo.';

  @override
  String get developerModeOpenSettings => 'Open settings';

  @override
  String get developerModeCloseApp => 'Close app';

  @override
  String get winningCartelasTitle => 'ታ ዓዋቲት ካርቴላ';

  @override
  String get winningCartelasTapHint =>
      'Tap a cartela to view the full winning pattern.';

  @override
  String get winningCartelasYou => 'ንስኻ/ኺ';

  @override
  String get winningCartelasPlayer => 'ተጻዋቲ';

  @override
  String winningCartelasPrize(String amount) {
    return 'ሽልማት: $amount ETB';
  }

  @override
  String winningCartelasDetailTitle(int number) {
    return 'ቁፅሪ ካርቴላ #$number';
  }

  @override
  String get winningCartelasSwipeHint => 'ንካልኦት ታ ዓወቲ ካርቴላ ቁጽሪ ጠውቕ ';

  @override
  String winningCartelasWinningBall(String ball) {
    return 'መ ዐወቲ ቁጽሪ: $ball';
  }

  @override
  String get winningCartelasAllWinners => 'ኣሸነፍቲ';

  @override
  String get winningCartelasPreviousWinner => 'ቀዳማይ ኣሸናፊ';

  @override
  String get winningCartelasNextWinner => 'ዝቕጽል ኣሸናፊ';

  @override
  String get cartelaOutcomeValid => 'ቅኑዕ';

  @override
  String get cartelaOutcomeInvalid => 'ዘይቅኑዕ';

  @override
  String get cartelaOutcomeRegistered => 'ተመዝጊቡ';

  @override
  String get cartelaOutcomeNoWin => 'ዘይተዓወተ';

  @override
  String get cartelaBlockedInfoTooltip => 'እዚ ካርቴላ ንምንቅጻጽ ስጉምቲ ኣሎ?';

  @override
  String cartelaBlockedDialogTitle(int number) {
    return 'ካርቴላ #$number ተዓጽዩ';
  }

  @override
  String get cartelaBlockedDialogOk => 'ተረዲኡኒ';

  @override
  String get cartelaBlockedReasonLate =>
      'ነቲ ዘይተዓወተ ቁጽሪ ስለ ዝሓለፍካዮ እዚ ካርቴላ ተዓጽዩ።';

  @override
  String get cartelaBlockedReasonPattern =>
      'እቲ ዝቐረብካዮ ቢንጎ ምስ ናይ ጸወታ ሕጊ ኣይሰማማዕን።';

  @override
  String get cartelaBlockedReasonGeneric => 'እዚ ካርቴላ ተዓጽዩ።';

  @override
  String get gameLabel => 'ጸወታ';

  @override
  String get connectionOnline => 'ተራኺቡ';

  @override
  String get connectionReconnecting => 'ደጊምካ ይራኸብ';

  @override
  String get connectionOffline => 'ተቋሪጹ';

  @override
  String get registrationTapHintGuest => 'ካርቴላ ንምምዝጋብ ምዝጋብ ኣድላዪ';

  @override
  String get registrationTapHintSelect => 'ቁጽሪታት ንምምራጽ ጠውቕ · ምስ ተዳለኻ ርኣዮ';

  @override
  String get registrationTapHintDefault => 'ንቅድሚት ምርኣይ ኮይኑ ካርቴላ ንምምዝጋብ ቁጽሪ ጠውቕ';

  @override
  String get registrationClear => 'ሕደጎ';

  @override
  String registrationReview(int count) {
    return 'ርኣዮ ($count)';
  }

  @override
  String registrationSecondsLeft(int seconds) {
    return '$seconds ሰከንድ ተሪፉ';
  }

  @override
  String registrationUpTo(int max) {
    return 'ክሳብ $max';
  }

  @override
  String get registrationLeft => ' ተሪፉ';

  @override
  String get registrationOpenBanner => 'ምዝገባ ክፉት እዩ';

  @override
  String get registrationOpenLabel => 'ምዝገባ ክፉት እዩ';

  @override
  String registrationClosesIn(int seconds) {
    return 'ምዝገባ ኣብ $seconds ሰከንድ ክዕጸው እዩ';
  }

  @override
  String registrationClosesInDuration(String duration) {
    return 'ምዝገባ ኣብ $duration ክዕጸው እዩ';
  }

  @override
  String get registrationClosedPreparing => 'ምዝገባ ተዓጽኢ። ጸወታ ይድለይ...';

  @override
  String get preparingGameNoCartelas => 'ምዝገባ ካርቴላ ተዓጽኢ። ጸወታ ኣብ ቀረባ እዩ...';

  @override
  String preparingGameCartelasRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ካርቴላታት ተመዝጊቦም። ጸወታ ኣብ ቀረባ እዩ...',
      one: '1 ካርቴላ ተመዝጊቡ። ጸወታ ኣብ ቀረባ እዩ...',
    );
    return '$_temp0';
  }

  @override
  String get liveNoGameTitle => 'ጸወታ ኣብ ወረፍ የለን';

  @override
  String get liveNoGameMessage => 'ሕጂ ክፍት ጸወታ የለን። ዝቕጽል ዙር ምስ ይጅምር ኣውሽ ኣውርድ።';

  @override
  String get gameCheckingTitle => 'ቢንጎ ጥያቄ ይፈትሽ';

  @override
  String get gameCheckingMessage => 'ቢንጎ ጥያቄ ይፈትሽ ኣሎ። በጃኹም ተጸበዩ።';

  @override
  String calledNumbersDrawnCount(int count) {
    return 'ዘተጸዉዑ፦ $count';
  }

  @override
  String calledNumbersBallOrder(int order) {
    return '#$order';
  }

  @override
  String get calledNumbersSyncLive => 'ኦንላይን';

  @override
  String missedPreviewGameTitle(String gameName) {
    return '$gameName (ዝሓለፈ ጸወታ)';
  }

  @override
  String missedPreviewRemaining(int count) {
    return 'ዝተረፈ $count';
  }

  @override
  String get calledNumbersSyncCatchingUp => 'እየተመሳሰለ…';

  @override
  String get calledNumbersSyncHelp =>
      'ዝተጸዊዑ ቁጽሪታት ካብ ሰርቨር ይመጹ። ኣብ  ግንኙነት ንእሽቶ ምድንጓይ መደበኛ እዩ።';

  @override
  String get calledNumbersSyncHelpTitle => 'ዝተጸዊዑ ቁጽሪታት ምምሕዳር';

  @override
  String get calledNumbersSyncReconnecting => 'እየተገናኘ…';

  @override
  String get calledNumbersRefreshTooltip => 'Refresh called numbers';

  @override
  String get cartelaMarkColorGreen => 'Green marks';

  @override
  String get cartelaMarkColorRed => 'Red marks';

  @override
  String get cartelaMarkColorYellow => 'Yellow marks';

  @override
  String get cartelaMarkColorBlue => 'Blue marks';

  @override
  String get cartelaMarkColorMenu => 'Mark color';

  @override
  String get cartelaClearMarks => 'Clear marks';

  @override
  String calledNumbersNextBallIn(int seconds) {
    return 'ዝቕጽል ኳስ · ${seconds}s';
  }

  @override
  String get calledNumbersNextBallLabel => 'Next ball';

  @override
  String get calledNumbersFirstBallLabel => 'First ball';

  @override
  String calledNumbersWaitingFirstBallIn(int seconds) {
    return 'መጀመርታ ኳስ · ${seconds}s';
  }

  @override
  String get calledNumbersCallingNext => 'እንዳተፀወዐ…';

  @override
  String get calledNumbersSyncingNextBall => 'Syncing next ball…';

  @override
  String calledNumbersDrawLabel(int order) {
    return 'Draw #$order';
  }

  @override
  String get calledNumbersSyncingMissed => 'ዝጠፍኡ ቁጽሪታት እየተመሳሰሉ…';

  @override
  String get calledNumbersWaitingNextBall => 'ዝቕጽል ኳስ ይጽበ…';

  @override
  String get calledNumbersAllBallsDrawn => 'ኩሉ ኳሳት ተጸዊዑ';

  @override
  String get calledNumbersWillAppear => 'ቁጽሪታት ኣብዚ ይርአ';

  @override
  String get calledNumbersCheckingBingo => 'ቢንጎ ይፈትሽ…';

  @override
  String get calledNumbersClaimHoldNote => 'ድሕሪ ጥያቄኹም ዝሓድሽ ቁጽሪታት ክርአዩ እዮም።';

  @override
  String get registrationSignUpToPlay => 'ንምጻወት ተመዝገብ';

  @override
  String get bulkReviewTitle => 'ካርቴላታትካ ርኣዮ';

  @override
  String get bulkRegisteringTitle => 'ካርቴላታት ይምዝገቡ ኣለዉ';

  @override
  String bulkCartelasTotal(int count, String total) {
    return '$count ካርቴላታት · ጠቕላላ $total';
  }

  @override
  String bulkPerCartela(String fee) {
    return 'ንካርቴላ $fee';
  }

  @override
  String get bulkConfirmNumbers => 'ቁጽሪታት ኣረጋግጽ፣ ድሕሪኡ ሓቢሮም ምዝጋብ።';

  @override
  String get bulkStarting => 'ምዝገባ ይጅምር ኣሎ...';

  @override
  String bulkProgress(int completed, int total) {
    return '$completed ካብ $total ካርቴላታት ይምዝገቡ ኣለዉ...';
  }

  @override
  String get bulkCancel => 'ሰርዝ';

  @override
  String bulkRegister(int count) {
    return '$count ምዝጋብ';
  }

  @override
  String get bulkRegistering => 'ይምዝገብ ኣሎ...';

  @override
  String get bulkCouldNotRegister =>
      'ዝተመርጹ ካርቴላታት ምምዝጋብ ኣይተኻእለን። በጃኻ ደጊምካ ፈትን።';

  @override
  String bulkTakenNumbers(String numbers) {
    return 'ዝተመርጹ ካርቴላታት ምምዝጋብ ኣይተኻእለን። $numbers ተወሲዱ ኣሎ።';
  }

  @override
  String get winnerBannerSyncingTitle => 'ቀጥታ ጸወታ ይምዓራረ ኣሎ…';

  @override
  String get winnerBannerSyncingMessage => 'ቀጥታ ዙር ካብ ሰርቨር ይዝምን ኣሎ።';

  @override
  String get winnerBannerWindowOpenTitle => 'ታዓዋታይ ቢንጎ ንምባል ክፉት እዩ';

  @override
  String get winnerBannerWindowOpenMessage =>
      'ካልኦት ተጻወቲ ኣብ ናይ ዓወታ መስኮት ክጠልቡ ይኽእሉ።';

  @override
  String get winnerBannerYouWonTitle => 'ዓወት!';

  @override
  String winnerBannerWonWithPayout(String amount) {
    return 'እንቋዕ ሓጎሰካ! $amount ብር ኣሸኒኒፍካ። ዝቕጽል ምዝገባ ብቕልጡፍ ክኽፈት እዩ።';
  }

  @override
  String get winnerBannerWonNoPayout =>
      'እንቋዕ ሓጎሰካ! ካርቴላካ ዓወት ኣምጺአ። ሽልማቱ ይዝምን ኣሎ። ዝቕጽል ምዝገባ ብቕልጡፍ ክኽፈት እዩ።';

  @override
  String get winnerBannerFinishedTitle => 'ጸወታ ተወዲኡ';

  @override
  String get winnerBannerFinishedMessage =>
      'እዚ ጸወታ ተወዲኡ። ብዓወት ናብ ዝቕጽል! ዝቕጽል ምዝገባ ብቕልጡፍ ክኽፈት እዩ።';

  @override
  String get winnerBannerNoPlayersTitle => 'ዝተሳተፉ ተጻወቲ የለዉን';

  @override
  String get winnerBannerNoPlayersMessage =>
      'ኣብዚ ዙር ዝተሳተፉ ተጻወቲ የለዉን። ዝቕጽል ዙር ይጅምር ኣሎ…';

  @override
  String get winnerBannerCancelledTitle => 'ጸወታ ተሰሪዙ';

  @override
  String get winnerBannerCancelledMessage =>
      'እዚ ጸወታ ተሰሪዙ። ናይ ምዝገባ ክፍሊታት ተመሊሱ ኣሎ። ዝቕጽል ዙር ይጅምር ኣሎ…';

  @override
  String get drawerSignInToPlay => 'ንምጽዋት ኮነ ካርቴላ ንምምዝጋብ እቶ';

  @override
  String get drawerSounds => 'ድምጽታት';

  @override
  String get soundSettingsDeviceOnly => 'እዞም ቅንብራት ኣብዚ መሳርሒ ጥራይ ይቕመጡ።';

  @override
  String get soundMaster => 'ናይ ጸወታ ድምጽታት';

  @override
  String get soundCalledNumber => 'ዝተጸውዐ ቁጽሪ';

  @override
  String get soundGameStart => 'ምጅማር ጸወታ';

  @override
  String get soundWinnerWindow => 'ናይ ተዓዋቲ መስኮት';

  @override
  String get soundValidBingo => 'ቅኑዕ ቢንጎ';

  @override
  String get soundVibrate => 'ንዝረት';

  @override
  String get drawerBalance => 'ቀሪ';

  @override
  String get drawerJoinTheGame => 'ናብ ጸወታ ተሓወስ';

  @override
  String get drawerJoinTheGameBody => 'ካርቴላ ንምምዝጋብ ኮይኑ ዋሊትካ ንምምሕዳር ኣካውንት ፍጠር።';

  @override
  String get drawerLiveGame => 'ቀጥታ ጸወታ';

  @override
  String get drawerWallet => 'ዋሊት';

  @override
  String get drawerProfile => 'ፕሮፋይል';

  @override
  String get drawerHistory => 'ዝርዝር';

  @override
  String get drawerTransactionHistory => 'ናይ ሂሳብ ዝርዝር';

  @override
  String get drawerGameHistory => 'ናይ ጸወታ ዝርዝር';

  @override
  String get drawerAppVersion => 'update ኣፕ';

  @override
  String get drawerAppVersionUpToDate => 'updated እዩ';

  @override
  String get drawerAppVersionUpdateAvailable => 'ምዕራይ ኣሎ';

  @override
  String get drawerAppVersionUpdateRequired => 'update የድሊ';

  @override
  String get drawerAppVersionChecking => 'ምዕራይ ይፍለጥ ኣሎ…';

  @override
  String drawerAppVersionCurrent(String version) {
    return 'ዝተጠመቀ፡ $version';
  }

  @override
  String get noUpdateAvailableTitle => 'update የለን';

  @override
  String get noUpdateAvailableBody => 'እቲ ናይ ናይ መወዳእታ update ኣብ ስልክኻ ኣሎ።';

  @override
  String get noUpdateAvailableOk => 'ሕራይ';

  @override
  String get updateCheckFailedTitle => 'Update check failed';

  @override
  String get updateCheckFailedBody =>
      'Could not reach the update server. Check your internet connection and try again.';

  @override
  String updateStatusDetail(
    int installedBuild,
    int serverBuild,
    String serverVersion,
  ) {
    return 'Installed build $installedBuild. Server latest build $serverBuild ($serverVersion).';
  }

  @override
  String get updateAvailableTitle => 'update ኣሎ';

  @override
  String get updateRequiredTitle => ' update ይግበሩ';

  @override
  String get updateLater => 'ድሕሪት';

  @override
  String get updateAction => 'ምዕራይ';

  @override
  String get updateVersionInstalled => 'ዝተፃዓነ';

  @override
  String get updateVersionMinimum => 'ዝተቐነሰ';

  @override
  String get updateVersionLatest => 'ናይ ሕጂ';

  @override
  String updateAvailableMessage(String version) {
    return 'update $version ኣሎ።';
  }

  @override
  String updateRequiredMessage(String version) {
    return 'እዚ version app update ኣይተገበረን። ንምቀጻልካ version $version update ግበር።';
  }

  @override
  String get updateLinkUnavailable => 'update  ኣይተገበረን።';

  @override
  String get guestPromptTitle => 'ነዚ ካርቴላ ንምምዝጋብ ኣካውንት ፍጠር';

  @override
  String get guestPromptMessage =>
      'ቁጽሪታት ካርቴላ ንምምራጽ ኮይነ ጸወታ ንምጽዋት ምዝጋብ ወይ ምእታው የደሊ።';

  @override
  String get guestPromoModeLabel => 'welcome';

  @override
  String get guestPromoTitle => ' ንዝቕጽል ዙር ተሓወስ';

  @override
  String get guestPromoMessage =>
      ' ዝቕጽል ተራ ጸወታ ከይጀመረ ካርቴላታት ንምሓዝ እቶ ወይ ኣካውንት ፍጠር።';

  @override
  String get guestPromoFooter => 'ቅልጡፍ ምዝገባ። ናይ ዝቕጽል ዙር  ቀጥታ ቢንጎ።';

  @override
  String get guestPromoRowLabel => 'መስመር ረድፍ';

  @override
  String get guestPromoRowHelper => 'ብመጀመርታ ምሉእ ረድፍ ይምላእ።';

  @override
  String get guestPromoColumnLabel => 'መስመር ዓምዲ';

  @override
  String get guestPromoColumnHelper => 'ድሕሪኡ ምሉእ ዓምዲ ይምላእ።';

  @override
  String get guestPromoDiagonalLabel => 'ዲያጎናል ቢንጎ';

  @override
  String get guestPromoDiagonalHelper => 'ኣብ መወዳእታ እቲ ዲያጎናል ቢንጎ ይፍጽም።';

  @override
  String get guestPromoWinnerLabel => 'ተዓዋቲ';

  @override
  String get guestPromoCongratsTitle => 'እንቋዕ ደስ በለካ!';

  @override
  String guestPromoCongratsAmountWon(String amount) {
    return '$amount ተዓዊትካ';
  }

  @override
  String guestPromoCongratsReceived(String amount) {
    return '$amount ብሲቢኢ ባንክ ተቐቢልካ።';
  }

  @override
  String get guestPromoCongratsWithdraw => 'ንምውጻእ እቶ ወይ ተመዝገብ።';

  @override
  String get drawerTheme => 'ቅርጺ';

  @override
  String get drawerThemeLight => 'ብርሃን';

  @override
  String get drawerThemeDark => 'ጸሊም';

  @override
  String get drawerThemeAuto => 'ኣውቶ';

  @override
  String get drawerLogout => 'ውጻእ';

  @override
  String get drawerJoinGame => 'ናብ ጸወታ ተሓወስ';

  @override
  String get drawerCreateAccount =>
      'ካርቴላ ንምምዝጋብ ኮይኑ ዋሊትካዋሊትካ ንምምሕዳር ኣካውንት ፍጠር።';

  @override
  String get gameStats => 'ናይ ጸወታ ስታቲስቲክስ';

  @override
  String get gameStatsHide => 'ስታቲስቲክስ ሕብእ';

  @override
  String get gameStatsShow => 'ስታቲስቲክስ ኣርኣ';

  @override
  String get gameInfoEntry => 'መእቶዊ';

  @override
  String get gameInfoPrize => 'ሽልማት';

  @override
  String get gameInfoReg => 'ምዝ';

  @override
  String get gameInfoCalled => 'ዝተጸዉዑ';

  @override
  String get gameInfoGame => 'ጸወታ';

  @override
  String get statusOnline => 'ኦንላይን';

  @override
  String get statusReconnecting => ' ይራኸብ አሎ';

  @override
  String get statusOffline => 'ኦንላይን ተቋሪጹ';

  @override
  String get gameHintGuest => 'ካርቴላ ንምምዝጋብ account ክፈት';

  @override
  String get gameHintSelectMode => 'ቁጽሪታት ንምምራጽ ጠውቕ · ምስ ተዳለኻ ርኣዮ';

  @override
  String get gameHintSingleMode => 'ንምርኣይ ጠውቕ ';

  @override
  String get gameClear => 'ሕደጎ';

  @override
  String gameReview(int count) {
    return 'ርኣዮ ($count)';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds ሰከንድ ተሪፉ';
  }

  @override
  String gameUpTo(int max) {
    return 'ክሳብ $max';
  }

  @override
  String get gameBalanceLeft => 'ተሪፉ';

  @override
  String get gameSyncing => 'ቀጥታ ጸወታ ይምዓርር ኣሎ…';

  @override
  String get gameSyncingMessage => 'ቀጥታ ዙር ካብ ሰርቨር ይዝምን ኣሎ።';

  @override
  String get gameWinnerWindowOpen => 'ናይ ዓወታ መስኮት ክፉት እዩ';

  @override
  String get gameWinnerWindowMessage => 'ካልኦት ተጻወቲ ኣብ ናይ ዓወታ መስኮት ክጠልቡ ይኽእሉ።';

  @override
  String get gameFinalizingWinners => 'Finalizing winners…';

  @override
  String get gameFinalizingWinnersMessage =>
      'Waiting for the server to finish this round and credit prizes.';

  @override
  String get gameFinalizingWinnersDelayed =>
      'Taking longer than usual. Pull to refresh or tap retry.';

  @override
  String get gameStartingRound => 'Starting round…';

  @override
  String get gameStartingRoundMessage =>
      'Waiting for the live session to open.';

  @override
  String get gameOpeningNextRound => 'Opening next round…';

  @override
  String get gameOpeningNextRoundMessage =>
      'Waiting for the next registration to open.';

  @override
  String get gameResultsLoading => 'Loading round results…';

  @override
  String get sessionResultsNoWinners => 'No winners this round.';

  @override
  String get gameAllNumbersCalled => 'All numbers were called.';

  @override
  String get gameNoWinnerNextRoundShortly => 'Next game will open shortly.';

  @override
  String get calledNumbersCheckingCartela => 'Checking cartela';

  @override
  String get calledNumbersWinnerCartela => 'Winner cartela';

  @override
  String get calledNumbersBlockedCartela => 'Blocked cartela';

  @override
  String get gameYouWon => 'ዓወት!';

  @override
  String get gameNextRegistration => 'ዝቕጽል ምዝገባ ብቕልጡፍ ክኽፈት እዩ።';

  @override
  String gameWonAmount(String amount) {
    return 'እንቋዕ ሓጎሰካ! $amount ብር ኣሸነፍካ።';
  }

  @override
  String get gameWonPending => 'እንቋዕ ሓጎሰካ! ካርቴላካ ዓወት ኣምጺኡ። ሽልማቱ ይዝምን ኣሎ።';

  @override
  String get gameFinished => 'ጸወታ ተወዲኡ';

  @override
  String get gameFinishedMessage =>
      'እዚ ጸወታ ተወዲኡ። ብዓወት ናብ ዝቕጽል! ዝቕጽል ምዝገባ ብቕልጡፍ ክኽፈት እዩ።';

  @override
  String postGameSummaryNextRoundIn(int seconds) {
    return 'ቀጽል ኣብ $seconds ሰ';
  }

  @override
  String get postGameSummaryTapToViewWinner => 'ናይ ዓወት ካርቴላ ንምርኣይ ጠውቑ';

  @override
  String get postGameSummaryNextGame => 'ቀጽል';

  @override
  String get postGameSummaryOpeningNextRound => 'Opening next round…';

  @override
  String finishedGamePrizeLine(String amount) {
    return 'ንዚ ጸወታ እቲ ኣብልናት $amount እዩ';
  }

  @override
  String get reviewModeWinnerTitle => 'ዓወተኛ';

  @override
  String reviewModeWinnerCartela(int number) {
    return 'ካርቴላ #$number';
  }

  @override
  String reviewModeAdditionalWinners(int count) {
    return '+$count ካልኦት ዓወተኛ(ታት)';
  }

  @override
  String get gameNoPlayers => 'ዝተሳተፉ ተጻወቲ የለዉን';

  @override
  String get gameNoPlayersMessage => 'ኣብዚ ዙር ዝተሳተፉ ተጻወቲ የለዉን። ዝቕጽል ዙር ይጅምር ኣሎ…';

  @override
  String get gameCancelled => 'ጸወታ ተሰሪዙ';

  @override
  String get gameCancelledMessage =>
      'እዚ ጸወታ ተሰሪዙ። ናይ ምዝገባ ክፍሊታት ተመሊሱ ኣሎ። ዝቕጽል ዙር ይጅምር ኣሎ…';

  @override
  String get bulkConfirmHint => 'ንምርኣይ ነካ · ንምውጻእ X · ድሉው ምስ ዀነ ተመዝገብ';

  @override
  String bulkRemoveCartela(int number) {
    return 'ካርቴላ #$number ወፃኢ ንምግባር';
  }

  @override
  String get bulkReviewEmpty => 'ንምምዝጋብ እንተወሓዱ ካርቴላ ምረጽ።';

  @override
  String bulkRegisterCount(int count) {
    return '$count ምዝጋብ';
  }

  @override
  String get bulkRegisterError => 'ዝተመርጹ ካርቴላታት ምምዝጋብ ኣይተኻእለን። በጃኻ ደጊምካ ፈትን።';

  @override
  String get bulkRegisterFailed => 'ዝተመርጹ ካርቴላታት ምምዝጋብ ኣይተኻእለን።';

  @override
  String bulkRegisterTaken(String numbers) {
    return 'ዝተመርጹ ካርቴላታት ምምዝጋብ ኣይተኻእለን። $numbers ተወሲዱ ኣሎ።';
  }

  @override
  String depositHistoryRef(String ref) {
    return 'ምልክት: $ref';
  }

  @override
  String get depositHistoryRetry => 'ምርግጋጽ ደጊምካ ፈትን';

  @override
  String depositHistoryRetriedStatus(String status) {
    return 'ምርግጋጽ ተደጊሙ። ኩነታት: $status።';
  }

  @override
  String get depositHistoryCouldNotRetry => 'ምርግጋጽ ደጊምካ ምፍታን ኣይተኻእለን።';

  @override
  String withdrawHistoryPhone(String phone) {
    return 'ተሌፎን: $phone';
  }

  @override
  String withdrawHistoryAccount(String account) {
    return 'ኣካውንት: $account';
  }

  @override
  String withdrawHistoryNote(String note) {
    return 'መዘኻኸሪ: $note';
  }

  @override
  String get drawerBigGame => 'Big Game';

  @override
  String get bigGameNoScheduledTitle => 'No Big Game scheduled yet.';

  @override
  String get bigGameNoScheduledBody => 'Check back soon.';

  @override
  String get bigGameScheduledTitle => 'Big Game Scheduled';

  @override
  String get bigGameRegistrationOpensIn => 'Registration opens in:';

  @override
  String get bigGameRegistrationOpenTitle => 'Big Game Registration Open';

  @override
  String get bigGamePlayStartsIn => 'Play starts in:';

  @override
  String get bigGameFixedPrize => 'Fixed Prize';

  @override
  String get bigGameEntryFee => 'ክፍሊት መእተዊ';

  @override
  String get bigGamePlayStartTime => 'Play Start Time';

  @override
  String get bigGameMaxCartelas => 'Max Cartelas';

  @override
  String get bigGameYourCartelas => 'Your Cartelas';

  @override
  String get bigGameReadyTitle => 'Big Game is ready';

  @override
  String get bigGameWaitingBody => 'Waiting for current round to finish.';

  @override
  String get gameCategoryNormal => 'Normal Game';

  @override
  String get gameCategoryBonus => 'ቦነስ ጸወታ';

  @override
  String get gameCategoryBigGotd => 'Normal Game';

  @override
  String get gameCategoryBigGame => 'Big Game';

  @override
  String get gameBonusFreeEntry => 'ነጻ መእተዊ';

  @override
  String gameBonusFixedPrize(String amount) {
    return 'ቋሚ ሽልማት፦ $amount';
  }

  @override
  String gameBonusMaxCartelas(int count) {
    return 'ከፍተኛ $count ካርቴላ';
  }

  @override
  String get registrationInsufficientBalance => 'ብቑዕ ቀሪ የለን';

  @override
  String get registrationInsufficientBalanceRegister =>
      'ካርቴላ ንምምዝጋብ ብቑዕ ቀሪ የለን';

  @override
  String get registrationInsufficientBalanceSelect =>
      'ተወሳኺ ካርቴላ ንምምራጽ ብቑዕ ቀሪ የለን';

  @override
  String registrationBalanceAllowsUpTo(int max) {
    return 'ቀሪኻ ክሳዕ $max ካርቴላ ይፈቅድ';
  }

  @override
  String get registrationBigGotdLimitReached =>
      'ን Big GOTD ናይ ካርቴላ ወሰን በጺሕካ ኣለኻ።';

  @override
  String get registrationBigGotdAllCartelasUsed =>
      'ን Big GOTD ኩሉ ካርቴላታት ተጠቒምካ ኣለኻ።';

  @override
  String registrationBigGotdCanRegisterMore(int max) {
    return 'ን Big GOTD ክሳዕ $max ተወሳኺ ካርቴላ ክትምዝገብ ትኽእል ኢኻ።';
  }

  @override
  String registrationBigGotdCanSelectMore(int max) {
    return 'ን Big GOTD ክሳዕ $max ተወሳኺ ካርቴላ ክትመርጽ ትኽእል ኢኻ።';
  }

  @override
  String get gameStatusRegistrationOpen => 'Registration Open';

  @override
  String get gameStatusPreparing => 'Preparing';

  @override
  String get gameStatusPlaying => 'Playing';

  @override
  String get gameStatusWinnerWindow => 'Winner Window';

  @override
  String get gameStatusFinished => 'Finished';

  @override
  String get gameStatusCancelled => 'Cancelled';

  @override
  String get gameStatusChecking => 'Checking';

  @override
  String get gameStatusWaiting => 'Waiting';

  @override
  String get gameStatusRegistrationClosed => 'Registration Closed';

  @override
  String get gameTimelineRegistration => 'Registration';

  @override
  String get gameTimelinePreparing => 'Preparing';

  @override
  String get gameTimelinePlaying => 'Playing';

  @override
  String get gameTimelineWinnerWindow => 'Winner Window';

  @override
  String get gameTimelineFinished => 'Finished';

  @override
  String gameTimelineSemantics(String stage) {
    return 'Game stage: $stage';
  }

  @override
  String get gamesHubTitle => 'Games';

  @override
  String get gamesHubLiveNow => 'Live Now';

  @override
  String get gamesHubComingNext => 'Coming Next';

  @override
  String get gamesHubBonus => 'ቦነስ ጸወታ';

  @override
  String get gamesHubUpcomingEvent => 'Upcoming Event';

  @override
  String get gamesHubNoLiveTitle => 'No live game right now';

  @override
  String get gamesHubNoLiveBody => 'Check back soon for the next round.';

  @override
  String get gamesHubNoBonusTitle => 'ቦነስ ጸወታ የለን';

  @override
  String get gamesHubNoBonusBody => 'ሎሚ ዝተሓሰበ ቦነስ ዙር የለን።';

  @override
  String get gamesHubStartsAfterCurrent => 'Starts after current round';

  @override
  String get gamesHubJoinLive => 'Join';

  @override
  String get gamesHubOpenBonus => 'ቦነስ ጸወታ ክፈት';

  @override
  String get gamesHubOpenBigGame => 'Open';

  @override
  String get gamesHubOpenHistory => 'View history';

  @override
  String get gamesHubHistoryBody =>
      'Review your past games and cartela results.';

  @override
  String gamesHubRegisteredCartelas(int count) {
    return 'Your cartelas: $count';
  }

  @override
  String get gamesHubBigGameSignInTitle => 'Sign in for Big Game';

  @override
  String get gamesHubBigGameSignInBody =>
      'Create an account to register for the Big Game.';

  @override
  String get gamesHubLoadErrorTitle => 'Could not load games';

  @override
  String get announcementBonusTitle => 'ሎሚ ቦነስ ጸወታ';

  @override
  String get announcementBonusBody => 'ድሕሪ ሕጂ ዙር ይጅምር';

  @override
  String get announcementBonusAction => 'ብነጻ ተጻወት';

  @override
  String get announcementBigGameTitle => 'BIG GAME';

  @override
  String announcementBigGamePrize(String amount) {
    return 'Prize $amount ETB';
  }

  @override
  String get announcementBigGameStartsIn => 'Starts in';

  @override
  String get announcementBigGameAction => 'Open';

  @override
  String get announcementBigGameWaiting =>
      'Big Game ready — waiting for current round';

  @override
  String get announcementBigGameLive => 'Big Game is live now';

  @override
  String get bigGameLivePrompt => 'Big Game is in progress — Go to Big Game';

  @override
  String get bigGameGoAction => 'Go to Big Game';

  @override
  String get announcementDismiss => 'Dismiss announcement';

  @override
  String get adminMessagesTitle => 'Messages';

  @override
  String get adminMessagesEmpty => 'No messages';

  @override
  String get adminMessagesDismiss => 'Dismiss message';

  @override
  String get adminMessagesLoadError =>
      'Could not load messages. Pull to refresh and try again.';

  @override
  String get adminMessagesPersistentBadge => 'Pinned';

  @override
  String get adminMessagesLoading => 'Loading notifications...';

  @override
  String adminMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications',
      one: '1 notification',
    );
    return '$_temp0';
  }

  @override
  String get adminMessagesForcedHint =>
      'The app will reopen when the admin removes this notice.';

  @override
  String get close => 'Close';

  @override
  String get drawerSendFeedback => 'Send feedback';

  @override
  String get drawerMyFeedback => 'My feedback';

  @override
  String get supportSendFeedbackTitle => 'Send feedback';

  @override
  String get supportSendFeedbackSubtitle =>
      'Share feedback, a complaint, or advice. We read every message.';

  @override
  String get supportCategoryLabel => 'Category';

  @override
  String get supportCategoryFeedback => 'Feedback';

  @override
  String get supportCategoryComplaint => 'Complaint';

  @override
  String get supportCategoryAdvice => 'Advice';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportMessageLabel => 'Your message';

  @override
  String get supportMessageHint =>
      'Tell us what happened or what we can improve';

  @override
  String get supportSendButton => 'Send message';

  @override
  String get supportMessageSent => 'We received your message';

  @override
  String get supportMessageSendFailed =>
      'Could not send your message. Please try again.';

  @override
  String get supportMyFeedbackTitle => 'My feedback';

  @override
  String get supportFeedbackHubTitle => 'Feedback';

  @override
  String supportMyFeedbackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get supportMyFeedbackEmpty => 'You have not sent any feedback yet.';

  @override
  String get supportAdminResponse => 'Admin response';

  @override
  String get supportAdminName => 'Friends Bingo';

  @override
  String get supportYouLabel => 'You';

  @override
  String get supportStatusOpen => 'Open';

  @override
  String get supportStatusReplied => 'Replied';

  @override
  String get supportStatusClosed => 'Closed';
}
