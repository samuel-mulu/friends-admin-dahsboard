// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ፍሬንድስ ቢንጎ';

  @override
  String get appBarHi => 'ሰላም፣ ';

  @override
  String get signIn => 'ግባ';

  @override
  String get signUp => 'ተመዝገብ';

  @override
  String get logout => 'ውጣ';

  @override
  String get language => 'ቋንቋ';

  @override
  String get themeLight => 'ብርሃን';

  @override
  String get themeDark => 'ጨለማ';

  @override
  String get themeAuto => 'ራስ-ሰር';

  @override
  String get theme => 'ገጽታ';

  @override
  String get loginTitle => 'እንኳን ተመለስክ';

  @override
  String get loginPhone => 'ስልክ ቁጥር';

  @override
  String get loginPhoneHint => '091*******';

  @override
  String get loginPassword => 'የይለፍ ቃል';

  @override
  String get loginPasswordHint => 'የይለፍ ቃልህን አስገባ';

  @override
  String get loginForgotPassword => 'የይለፍ ቃል ረሳህ?';

  @override
  String get loginSignIn => 'ግባ';

  @override
  String get loginCreateAccount => 'አዲስ መለያ ፍጠር';

  @override
  String get registerFullName => 'ሙሉ ስም';

  @override
  String get registerFullNameHint => 'ሙሉ ስም';

  @override
  String get registerPassword => 'የይለፍ ቃል';

  @override
  String get registerPasswordHint => 'ቢያንስ 6 ቁምፊዎች';

  @override
  String get registerConfirmPassword => 'የይለፍ ቃል አረጋግጥ';

  @override
  String get registerConfirmPasswordHint => 'የይለፍ ቃልህን ደግም አስገባ';

  @override
  String get registerContinue => 'ቀጥል';

  @override
  String get registerAlreadyHaveAccount => 'መለያ አለህ? ግባ';

  @override
  String get forgotPasswordTitle => 'የይለፍ ቃል ዳግም አስጀምር';

  @override
  String get forgotPasswordSubtitle => 'የማረጋገጫ ኮድ ለማግኘት ስልክ ቁጥርህን አስገባ።';

  @override
  String get forgotPasswordSendCode => 'የማረጋገጫ ኮድ ላክ';

  @override
  String get forgotPasswordBackToSignIn => 'ወደ ግባ ተመለስ';

  @override
  String get otpVerifyPhone => 'ስልክህን አረጋግጥ';

  @override
  String otpSentTo(String phone) {
    return 'ኮድ ወደ $phone ተልኳል።';
  }

  @override
  String get otpCreateAccount => 'መለያ ፍጠር';

  @override
  String get otpResendCode => 'ኮድ ዳግም ላክ';

  @override
  String otpResendInSeconds(int seconds) {
    return 'በ$seconds ሰከንድ ውስጥ ዳግም ላክ';
  }

  @override
  String otpResendInMinutes(int minutes) {
    return 'በ$minutes ደቂቃ ውስጥ ዳግም ላክ';
  }

  @override
  String otpResendInMinutesSeconds(int minutes, int seconds) {
    return 'በ$minutesደ $secondsሰ ውስጥ ዳግም ላክ';
  }

  @override
  String get otpBackToDetails => 'ወደ ዝርዝር ተመለስ';

  @override
  String get otpEnterCode => '6-አሃዝ የማረጋገጫ ኮድ አስገባ።';

  @override
  String get otpSmsBanner => 'በSMS ወደ ስልክህ የተላከውን ኮድ አስገባ።';

  @override
  String get resetPasswordTitle => 'አዲስ የይለፍ ቃል አዘጋጅ';

  @override
  String resetPasswordSmsSentTo(String phone) {
    return 'ወደ $phone የተላከውን SMS ኮድ አስገባ።';
  }

  @override
  String get resetPasswordNewPassword => 'አዲስ የይለፍ ቃል';

  @override
  String get resetPasswordConfirmNew => 'አዲስ የይለፍ ቃል አረጋግጥ';

  @override
  String get resetPasswordConfirmNewHint => 'አዲስ የይለፍ ቃልህን ደግም አስገባ';

  @override
  String get resetPasswordUpdate => 'የይለፍ ቃል ዘምን';

  @override
  String get resetPasswordBackToPhone => 'ወደ ስልክ ቁጥር ተመለስ';

  @override
  String get validatorPhoneRequired => 'ስልክ ቁጥር ያስፈልጋል።';

  @override
  String get validatorPhoneInvalid => 'ትክክለኛ ስልክ ቁጥር አስገባ።';

  @override
  String get validatorPasswordLength => 'የይለፍ ቃሉ ቢያንስ 6 ቁምፊዎች ሊኖረው ይገባል።';

  @override
  String get validatorFullNameLength => 'ሙሉ ስሙ ቢያንስ 3 ቁምፊዎች ሊኖረው ይገባል።';

  @override
  String get validatorPasswordMismatch => 'የይለፍ ቃሎቹ አይዛመዱም።';

  @override
  String get validatorAmountRequired => 'መጠን ያስፈልጋል።';

  @override
  String get validatorAmountInvalid => 'ትክክለኛ መጠን አስገባ።';

  @override
  String get validatorAmountPositive => 'መጠን ከዜሮ በላይ መሆን አለበት።';

  @override
  String get validatorTransactionRef => 'ትክክለኛ የግብይት ማጣቀሻ አስገባ።';

  @override
  String dashboardHello(String name) {
    return 'ሰላም፣ $name';
  }

  @override
  String get dashboardSubtitle =>
      'የቀጥታ ጨዋታ ክፈት፣ ካርቴሎቻችን ምዝገባ፣ እና ቦርሳህን ከአንድ ቦታ ተቆጣጠር።';

  @override
  String get dashboardOpenLiveGame => 'ቀጥታ ጨዋታ ክፈት';

  @override
  String get dashboardRole => 'ሚና';

  @override
  String get dashboardStatus => 'ሁኔታ';

  @override
  String get dashboardWalletSnapshot => 'የቦርሳ ቅጽበታዊ';

  @override
  String dashboardAvailableBalance(String amount) {
    return 'ያለው ቀሪ: $amount ብር';
  }

  @override
  String dashboardLockedBalance(String amount) {
    return 'የተቆለፈ ቀሪ: $amount ብር';
  }

  @override
  String get dashboardOpenWallet => 'ቦርሳ ክፈት';

  @override
  String get dashboardWalletLoading => 'ቦርሳ በመጫን ላይ...';

  @override
  String get dashboardWalletUnavailable => 'ቦርሳ አሁን አይገኝም።';

  @override
  String get dashboardWhatIsNext => 'ቀጣይ ምንድን ነው';

  @override
  String get dashboardWhatIsNextBody =>
      'ቀጣይ እርምጃዎች ቀጥታ ቁጥሮችን፣ ቢንጎ ጥያቄዎችን፣ ተቀማጭና ሽያጭ ወደዚሁ መሠረት ያካተታሉ።';

  @override
  String get walletAvailableBalance => 'ያለው ቀሪ';

  @override
  String get walletLockedBalance => 'የተቆለፈ ቀሪ';

  @override
  String get walletFreezBalance => 'Freez balance';

  @override
  String get walletTotalBalance => 'ጠቅላላ ቦርሳ';

  @override
  String get walletTotalEqualsHint => 'የሚገኝ + የተቆለፈ = ጠቅላላ ቦርሳ';

  @override
  String get walletDeposit => 'ተቀማጭ';

  @override
  String get walletWithdraw => 'ሽያጭ';

  @override
  String get walletTransactionHistory => 'የግብይት ታሪክ';

  @override
  String get walletTransactionHistorySubtitle => 'ሁሉንም የቦርሳ ንቅናቄዎች ያጣጣሉ።';

  @override
  String get walletDepositHistory => 'የተቀማጭ ታሪክ';

  @override
  String get walletDepositHistorySubtitle =>
      'የማረጋገጫ ሂደትን ይከታተሉ እና ሲያስፈልግ ደግም ይሞክሩ።';

  @override
  String get walletWithdrawalHistory => 'የሽያጭ ታሪክ';

  @override
  String get walletWithdrawalHistorySubtitle => 'ጥያቄ፣ ፈቃድ እና ክፍያ ሁኔታዎችን ይከታተሉ።';

  @override
  String get walletCouldNotLoad => 'የቦርሳ ዝርዝር ማምጣት አልተቻለም።';

  @override
  String get walletTryAgain => 'እንደገና ሞክር';

  @override
  String get depositScreenTitle => 'ተቀማጭ';

  @override
  String get depositAmount => 'መጠን';

  @override
  String get depositFtNumber => 'FT ቁጥር';

  @override
  String get depositReceiptId => 'ደረሰኝ መለያ';

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
  String get depositDevHelper => 'የልማት/ሙከራ ረዳት';

  @override
  String depositDevReference(String ref) {
    return 'የልማት ሙከራ ማጣቀሻ: $ref';
  }

  @override
  String get depositUseTestRef => 'ሙከራ ማጣቀሻ ተጠቀም';

  @override
  String get depositSubmit => 'ተቀማጭ አስገባ';

  @override
  String get depositGuideTitle => 'እንዴት ተቀማጭ እንደሚያደርጉ';

  @override
  String get depositGuideTelebirrStep1 => 'ቴሌብር ክፈትን ወደ ፈረንድስ ቢንጎ ገንዘብ ላክ';

  @override
  String get depositGuideTelebirrStep2 => 'ደረሰኝ ክፈትን የግብይት ቁጥር ቅዳ';

  @override
  String get depositGuideTelebirrStep3 => 'የተከፈለውን መጠን እና የደረሰኝ ኮድ ከታች አስገባ';

  @override
  String get depositGuideCbeStep1 => 'ሲቢኢ ባንክ ክፈትን ወደ ፈረንድስ ቢንጎ ላክ';

  @override
  String get depositGuideCbeStep2 => 'ከደረሰኝ የ FT ማጣቀሻ ቅዳ';

  @override
  String get depositGuideCbeStep3 => 'ትክክለኛ መጠን እና ማጣቀሻ ከታች አስገባ';

  @override
  String get depositGuideAwashStep1 => 'አዋሽ ባንክ ክፈትን ክፍያ ላክ';

  @override
  String get depositGuideAwashStep2 => 'የክፍያ ማጣቀሻ ቅዳ';

  @override
  String get depositGuideAwashStep3 => 'ትክክለኛ መጠን እና ማጣቀሻ ከታች አስገባ';

  @override
  String get depositGuideBoaStep1 => 'አቢሲንያ ባንክ ክፈትን ክፍያ ላክ';

  @override
  String get depositGuideBoaStep2 => 'የክፍያ ማጣቀሻ ቅዳ';

  @override
  String get depositGuideBoaStep3 => 'ትክክለኛ መጠን እና ማጣቀሻ ከታች አስገባ';

  @override
  String get depositVerifying => 'ክፍያዎ እየተረጋገጠ ነው…';

  @override
  String get depositApprovedTitle => 'ተቀማጭ ጸድቋል';

  @override
  String get depositRejectedTitle => 'ተቀማጭ አልተሳካም';

  @override
  String get depositTryAgain => 'ዝርዝሮችን ያርሙ እና እንደገና ይሞክሩ።';

  @override
  String get depositSelectProvider => 'የክፍያ ዘዴ';

  @override
  String get depositSendToAccount => 'ወደዚህ ሂሳብ ላክ';

  @override
  String get depositShowInstructions => 'መመሪያዎች';

  @override
  String get depositReceiptReviewLabel =>
      'ከግብይቴ የመጡን መጠን እና የማጣቀሻ ቁጥር አረጋግጬአለሁ';

  @override
  String get depositCopyAccount => 'ሂሳብ ቅዳ';

  @override
  String get depositAccountCopied => 'ሂሳብ ተቀድቷል';

  @override
  String get depositGuideImageMissing => 'ስክሪንሾት በቅርቡ';

  @override
  String get depositGuideTapToExpand => 'ለማጉላት መታ ያድርጉ';

  @override
  String get walletQuickDeposit => 'በሞባይል ገንዘብ ወይም ባንክ ቀጥታ ገንዘብ ያክሉ';

  @override
  String get depositLatest => 'የቅርቡ ተቀማጭ';

  @override
  String depositSubmittedStatus(String status) {
    return 'ተቀማጭ ቀርቧል። ሁኔታ: $status።';
  }

  @override
  String get depositCouldNotSubmit => 'ተቀማጭ ማስገባት አልተቻለም።';

  @override
  String get depositReceiptScan => 'Scan receipt';

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
    return 'አቅራቢ: $provider';
  }

  @override
  String depositAmountLabel(String amount) {
    return 'መጠን: $amount';
  }

  @override
  String depositReference(String ref) {
    return 'ማጣቀሻ: $ref';
  }

  @override
  String depositCreated(String date) {
    return 'ተፈጥሯል: $date';
  }

  @override
  String depositRejectionReason(String reason) {
    return 'ምክንያት: $reason';
  }

  @override
  String get depositHistoryTitle => 'የተቀማጭ ታሪክ';

  @override
  String get depositHistoryEmpty => 'ገና ተቀማጭ የለም';

  @override
  String get depositHistoryEmptyMessage => 'የተቀማጭ ጥያቄዎችዎ እዚህ ይታያሉ።';

  @override
  String get depositHistoryCouldNotLoad => 'የተቀማጭ ታሪክ ማምጣት አልተቻለም።';

  @override
  String get depositRetryVerification => 'ማረጋገጫ ደግም ሞክር';

  @override
  String depositRetried(String status) {
    return 'ማረጋገጫ ደግሟል። ሁኔታ: $status።';
  }

  @override
  String get depositRetryFailed => 'ማረጋገጫ ደግሞ ለማሞከር አልተቻለም።';

  @override
  String depositAmountRow(String amount) {
    return 'መጠን: $amount';
  }

  @override
  String depositRefRow(String ref) {
    return 'ማጣቀሻ: $ref';
  }

  @override
  String depositCreatedRow(String date) {
    return 'ተፈጥሯል: $date';
  }

  @override
  String depositReasonRow(String reason) {
    return 'ምክንያት: $reason';
  }

  @override
  String get withdrawScreenTitle => 'ሽያጭ';

  @override
  String get withdrawAmount => 'መጠን';

  @override
  String get withdrawSubmit => 'ሽያጭ አስገባ';

  @override
  String get withdrawLatest => 'የቅርቡ ሽያጭ';

  @override
  String withdrawSubmittedStatus(String status) {
    return 'ሽያጭ ቀርቧል። ሁኔታ: $status።';
  }

  @override
  String get withdrawCouldNotSubmit => 'ሽያጭ ማስገባት አልተቻለም።';

  @override
  String withdrawStatusLabel(String status) {
    return 'ሁኔታ: $status';
  }

  @override
  String withdrawProviderLabel(String provider) {
    return 'አቅራቢ: $provider';
  }

  @override
  String withdrawAmountLabel(String amount) {
    return 'መጠን: $amount';
  }

  @override
  String withdrawPhoneLabel(String phone) {
    return 'ስልክ: $phone';
  }

  @override
  String withdrawAccountLabel(String account) {
    return 'መለያ: $account';
  }

  @override
  String withdrawCreatedLabel(String date) {
    return 'ተፈጥሯል: $date';
  }

  @override
  String withdrawNoteLabel(String note) {
    return 'ማስታወሻ: $note';
  }

  @override
  String get withdrawHistoryTitle => 'የሽያጭ ታሪክ';

  @override
  String get withdrawHistoryEmpty => 'ገና ሽያጭ የለም';

  @override
  String get withdrawHistoryEmptyMessage => 'የሽያጭ ጥያቄዎችዎ እዚህ ይታያሉ።';

  @override
  String get withdrawHistoryCouldNotLoad => 'የሽያጭ ታሪክ ማምጣት አልተቻለም።';

  @override
  String get withdrawSelectProvider => 'የክፍያ ዘዴ';

  @override
  String get withdrawMaxWithdrawableHint =>
      'እስከ ያለዎት የሚገኝ ቀሪ ሂሳብ ድረስ መውጣት ይችላሉ። ቀሪው ለካርቴላ ምዝገባ ይጠቅማል።';

  @override
  String get withdrawLockedFundsHint =>
      'ተቆልፏ የሚገኙ ገንዘቦች ለበመጠባበቅ ላይ ያሉ የሽያጭ ጥያቄዎች ተይዘዋል።';

  @override
  String get withdrawAmountLockedHelper =>
      'አስተዳዳሪ ጥያቄዎን እስኪያስተናግድ ድረስ ይህ መጠን ይቆለፋል።';

  @override
  String get withdrawAmountExceedsAvailable => 'መጠኑ ከሚገኝ ቀሪ ሂሳብዎ በላይ ነው።';

  @override
  String get withdrawPendingTitle => 'ሽያጭ ቀርቧል';

  @override
  String get withdrawPendingMessage =>
      'ጥያቄዎ ለአስተዳዳሪ ግምገማ በመጠባበቅ ላይ ነው። መጠኑ እስኪጸድቅ ወይም እስኪተሰርዝ ድረስ ተቆልፏል።';

  @override
  String get withdrawApprovedTitle => 'ሽያጭ ጸድቋል';

  @override
  String get withdrawApprovedMessage => 'ክፍያዎ ጸድቆ ተልኳል።';

  @override
  String get withdrawRejectedTitle => 'ሽያጭ ተቀባይነት አላገኘም';

  @override
  String get withdrawRejectedMessage =>
      'ሽያጭዎ ተቀባይነት አላገኘም። ተቆልፏ የነበረው ገንዘብ ወደ ቀሪ ሂሳብዎ ተመልሷል።';

  @override
  String get withdrawStatusPendingReview => 'ግምገማ በመጠባበቅ ላይ';

  @override
  String get withdrawStatusApproved => 'ጸድቋል';

  @override
  String get withdrawStatusRejected => 'ተቀባይነት አላገኘም';

  @override
  String get withdrawStatusFailed => 'አልተሳካም';

  @override
  String get withdrawStatusRefunded => 'ተመልሷል';

  @override
  String get walletLockedBalanceHint =>
      'ለበመጠባበቅ ላይ ያሉ የሽያጭ ጥያቄዎች የተይዙ ገንዘቦችን ያካትታል።';

  @override
  String get withdrawRequestsTitle => 'የሽያጭ ጥያቄዎችዎ';

  @override
  String get withdrawTabAll => 'ሁሉም';

  @override
  String get withdrawTabPending => 'በመጠባበቅ ላይ';

  @override
  String get withdrawTabCompleted => 'ተጠናቋል';

  @override
  String get withdrawTabRejected => 'ተቀባይነት አላገኘም';

  @override
  String get withdrawTableDate => 'ቀን';

  @override
  String get withdrawTableAmount => 'መጠን';

  @override
  String get withdrawTableProvider => 'አቅራቢ';

  @override
  String get withdrawTableStatus => 'ሁኔታ';

  @override
  String get withdrawPendingEmpty => 'በመጠባበቅ ላይ የሽያጭ ጥያቄ የለም።';

  @override
  String get withdrawCompletedEmpty => 'ገና የተጠናቀቀ ሽያጭ የለም።';

  @override
  String get withdrawRejectedEmpty => 'የተቀባይነት አላገኘ ሽያጭ የለም።';

  @override
  String get txHistoryTitle => 'የቦርሳ ግብይቶች';

  @override
  String get txHistoryEmpty => 'ገና ግብይት የለም';

  @override
  String get txHistoryEmptyMessage =>
      'ከተቀማጭ፣ ምዝገባ እና ሽያጭ በኋላ የቦርሳ ታሪክዎ እዚህ ይታያል።';

  @override
  String txHistoryShowing(int count, int total) {
    return 'ከ$total ግብይቶች $countቱ ይታያሉ';
  }

  @override
  String get txHistoryWalletActivity => 'የቦርሳ ንቅናቄ';

  @override
  String get txWithdrawRequestLockedNote => 'ለግምገማ በመጠባበቅ ላይ ወደ ተቆለፈ ቀሪ ተዛውሯል።';

  @override
  String txHistoryBalanceAfter(String amount) {
    return 'ቀሪ: $amount';
  }

  @override
  String get txHistoryCouldNotLoad => 'የግብይት ታሪክ ማምጣት አልተቻለም።';

  @override
  String get gameHistoryTitle => 'የጨዋታ ታሪክ';

  @override
  String get gameHistoryEmpty => 'ገና የተጠናቀቀ ጨዋታ የለም።';

  @override
  String gameHistoryCards(int count) {
    return '$count ካርዶች';
  }

  @override
  String get gameHistoryLoadingAttended => 'የእርስዎ ጨዋታዎች በመጫን ላይ...';

  @override
  String get gameHistoryEmptyAttended => 'እስካሁን ያለፉ ጨዋታዎች የሉም።';

  @override
  String get gameHistoryDetailTitle => 'የጨዋታ ዝርዝር';

  @override
  String get gameHistoryPrizePool => 'የሽልማት መጠን';

  @override
  String gameHistoryYourWinnings(String amount) {
    return '$amount አሸንፈዋል';
  }

  @override
  String get gameHistoryYourCartelas => 'የእርስዎ ካርዶች';

  @override
  String get gameHistorySessionWinners => 'የጨዋታ አሸናፊዎች';

  @override
  String gameHistoryMyCartelaCount(int count) {
    return '$count የእርስዎ';
  }

  @override
  String get gameHistoryLoadMore => 'ተጨማሪ ጫን';

  @override
  String get gameHistoryRetry => 'እንደገና ሞክር';

  @override
  String get gameStatsLabel => 'የጨዋታ ስታቲስቲክስ';

  @override
  String get gameHideStats => 'ስታቲስቲክስ ደብቅ';

  @override
  String get gameShowStats => 'ስታቲስቲክስ አሳይ';

  @override
  String get gameEntryLabel => 'መግቢያ';

  @override
  String get gamePrizeLabel => 'ሽልማት';

  @override
  String get gameRegLabel => 'ምዝ';

  @override
  String get gameCalledLabel => 'ተጠሪ';

  @override
  String get gameNowPlaying => 'አሁን ይጫወታል';

  @override
  String get gameNextGame => 'ቀጣይ ጨዋታ';

  @override
  String get liveCalledNumbersLabel => 'የተጠሩ ቁጥሮች';

  @override
  String get liveNextRoundSectionTitle => 'ቀጣይ ዙር';

  @override
  String get liveJoinCurrentRoundSectionTitle => 'የአሁኑን ዙር ተቀላቀል';

  @override
  String get liveMissedCurrentRoundTitle => 'የአሁኑ ዙር በመጫወት ላይ ነው';

  @override
  String get liveNextQueuedPlayLabel => 'ቀጣይ ተራ ጨዋታ';

  @override
  String get liveRegisteredCartelasLabel => 'የተመዘገቡ ካርቴላዎች';

  @override
  String get liveRegisteredCartelasEmpty => 'እስካሁን የለም — ከታች ቁጥሮችን ምረጥ።';

  @override
  String get liveMissedRoundHelper => 'ይህን ዙር አምልጦሃል። ለቀጣዩ ተራ ጨዋታ አሁን ተመዝገብ።';

  @override
  String get liveMissedRoundYouMissedGame => 'ይህን ዙር አምልጠሃል።';

  @override
  String get liveMissedRoundOverviewTitle => 'ቀጥታ እና ቀጣይ ዙር';

  @override
  String liveMissedRoundCollapsedMissed(String gameName) {
    return 'ተሳልፎ · $gameName';
  }

  @override
  String liveMissedRoundCollapsedNextReady(String gameName) {
    return 'ቀጣይ ዝግጁ · $gameName · አሁን ተመዝገብ';
  }

  @override
  String get liveMissedRoundRegisterBridge =>
      'ለቀጣዩ ጨዋታ ካርቴላ አሁን ተመዝገብ እና በቀጣዩ ዙር ተጫወት።';

  @override
  String liveJoinCurrentRoundGameLive(String gameName) {
    return '$gameName አሁን በቀጥታ እየተጫወተ ነው';
  }

  @override
  String get liveNextGameBannerTitle => 'ቀጣይ ጨዋታ';

  @override
  String get liveMissedRoundBannerSubtitle => 'ቀጣይ ጨዋታ በቅርቡ ይጀምራል';

  @override
  String get liveNextGameLabel => 'ቀጣይ ጨዋታ';

  @override
  String get registrationStartsAfterCurrentGame =>
      'Registration open - starts after current game';

  @override
  String get liveJoinCurrentRoundHelper =>
      'ለዚህ ቀጥታ ዙር ምዝገባ አሁንም ክፍት ነው። የተያዙና የተመዘገቡ ካርቴላዎች በራስ-ሰር ይቆለፋሉ።';

  @override
  String get liveAddMoreCartelasHelper =>
      'ምዝገባ አሁንም ክፍት ነው። ዙሩ በመካሄድ ላይ ሳለ ተጨማሪ ካርቴላዎችን ማከል ትችላለህ።';

  @override
  String get liveAddMoreCartelasTitle => 'ተጨማሪ ካርቴላዎች ጨምር';

  @override
  String get liveNextRoundRegistrationTitle => 'የቀጣይ ዙር ምዝገባ';

  @override
  String get gameRuleDetailTitle => 'የጨዋታ ህግ';

  @override
  String get gameRulePatternSample => 'አሳብ ለማሸነፊያ';

  @override
  String get gameNextGameHide => 'ቀጣይ ጨዋታ ደብቅ';

  @override
  String get gameNextGameShow => 'ቀጣይ ጨዋታ አሳይ';

  @override
  String get leaveLiveGameTitle => 'የቀጥታ ጨዋታ ይዘጋዉ?';

  @override
  String get leaveLiveGameMessage =>
      'ጨዋታዎ በሰርቨር ላይ ይቀጥላል። የተመዘገቡ ምልክቶች በዚህ መሳሪያ ይቀመጣሉ።';

  @override
  String get leaveLiveGameStay => 'ይቆዩ';

  @override
  String get leaveLiveGameLeave => 'ይውጡ';

  @override
  String get confirmBackTitle => 'መመለስ ይፈልጋሉ?';

  @override
  String get confirmBackMessage => 'ይህን ገጽ መልቀቅ ይፈልጋሉ?';

  @override
  String get confirmBackStay => 'ይቆዩ';

  @override
  String get confirmBackLeave => 'ይውጡ';

  @override
  String get exitAppTitle => 'መተግበሪያ ዝጋ?';

  @override
  String get exitAppMessage => 'ጨዋታዎ ይቀጥላል። በማንኛውም ጊዜ መመለስ ይችላሉ።';

  @override
  String get exitAppStay => 'ይቆዩ';

  @override
  String get exitAppExit => 'ዝጋ';

  @override
  String get winningCartelasTitle => 'የማሸነፊያ ካርቴላዎች';

  @override
  String get winningCartelasTapHint =>
      'Tap a cartela to view the full winning pattern.';

  @override
  String get winningCartelasYou => 'እርስዎ';

  @override
  String get winningCartelasPlayer => 'ተጫዋች';

  @override
  String winningCartelasPrize(String amount) {
    return 'ሽልማት: $amount ETB';
  }

  @override
  String winningCartelasDetailTitle(int number) {
    return 'የማሸነፊያ ካርቴላ #$number';
  }

  @override
  String get winningCartelasSwipeHint => 'ለሌሎች አሸናፊዎች ያንሸራትቱ ወይም ቁጥር ይንኩ';

  @override
  String winningCartelasWinningBall(String ball) {
    return 'የማሸነፊያ ቁጥር: $ball';
  }

  @override
  String get winningCartelasAllWinners => 'አሸናፊዎች';

  @override
  String get winningCartelasPreviousWinner => 'ቀዳሚ አሸናፊ';

  @override
  String get winningCartelasNextWinner => 'ቀጣይ አሸናፊ';

  @override
  String get cartelaOutcomeValid => 'ትክክል';

  @override
  String get cartelaOutcomeInvalid => 'ልክ ያልሆነ';

  @override
  String get cartelaOutcomeRegistered => 'ተመዝግቧል';

  @override
  String get cartelaOutcomeNoWin => 'አላሸነፈም';

  @override
  String get cartelaBlockedInfoTooltip => 'ይህ ካርቴላ ለምን ታግዷል?';

  @override
  String cartelaBlockedDialogTitle(int number) {
    return 'ካርቴላ #$number ታግዷል';
  }

  @override
  String get cartelaBlockedDialogOk => 'ተረድቻለሁ';

  @override
  String get cartelaBlockedReasonLate => 'የማሸነፊያውን ቁጥር ስላመሳገርክ ይህ ካርቴላ ታግዷል።';

  @override
  String get cartelaBlockedReasonPattern => 'የቀረበው ቢንጎ ከጨዋታው ህግ ጋር አልተሰማማደም።';

  @override
  String get cartelaBlockedReasonGeneric => 'ይህ ካርቴላ ታግዷል።';

  @override
  String get gameLabel => 'ጨዋታ';

  @override
  String get connectionOnline => 'ተያይዟል';

  @override
  String get connectionReconnecting => 'እንደገና ይያያዛል';

  @override
  String get connectionOffline => 'ተቋርጧል';

  @override
  String get registrationTapHintGuest => 'ካርቴሎ ለመመዝገብ ተመዝገብ';

  @override
  String get registrationTapHintSelect => 'ቁጥሮችን ለመምረጥ ጠቅ አድርግ · ሲዘጋጅ ይገምግሙ';

  @override
  String get registrationTapHintDefault => 'ለቅድመ ዕይታ እና ምዝገባ ቁጥር ጠቅ አድርግ';

  @override
  String get registrationClear => 'ሰርዝ';

  @override
  String registrationReview(int count) {
    return 'ይገምግሙ ($count)';
  }

  @override
  String registrationSecondsLeft(int seconds) {
    return '$seconds ሰ ቀርቷል';
  }

  @override
  String registrationUpTo(int max) {
    return 'እስከ $max';
  }

  @override
  String get registrationLeft => ' ቀርቷል';

  @override
  String get registrationOpenBanner => 'ምዝገባ ክፍት ነው';

  @override
  String get registrationOpenLabel => 'ምዝገባ ክፍት ነው';

  @override
  String registrationClosesIn(int seconds) {
    return 'ምዝገባ በ $seconds ሰከን ይዘጋል';
  }

  @override
  String registrationClosesInDuration(String duration) {
    return 'ምዝገባ በ $duration ይዘጋል';
  }

  @override
  String get registrationClosedPreparing => 'ምዝገባ ተዘግቷል። ጨዋታ በመዘጋጀት ላይ...';

  @override
  String get preparingGameNoCartelas => 'የካርቴላ ምዝገባ ተዘግቷል። ቀጣይ ጨዋታ በቅርቡ ይጀምራል።';

  @override
  String preparingGameCartelasRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ካርቴላዎች ተመዝግበዋል። ቀጣይ ጨዋታ በቅርቡ ይጀምራል።',
      one: '1 ካርቴላ ተመዝግቧል። ቀጣይ ጨዋታ በቅርቡ ይጀምራል።',
    );
    return '$_temp0';
  }

  @override
  String get liveNoGameTitle => 'በረድፍ ላይ ጨዋታ የለም';

  @override
  String get liveNoGameMessage => 'አሁን ክፍት ጨዋታ የለም። ቀጣይ ዙር ሲጀምር ወደ ታች ይጎትቱ።';

  @override
  String get gameCheckingTitle => 'ቢንጎ ጥያቄ በመፈተሽ ላይ';

  @override
  String get gameCheckingMessage => 'የቢንጎ ጥያቄ በመ review ላይ ነው። እባክዎ ይጠብቁ።';

  @override
  String calledNumbersDrawnCount(int count) {
    return 'ተጥሯል፦ $count';
  }

  @override
  String calledNumbersBallOrder(int order) {
    return '#$order';
  }

  @override
  String get calledNumbersSyncLive => 'ቀጥታ';

  @override
  String get calledNumbersSyncCatchingUp => 'እየተመሳሰለ…';

  @override
  String get calledNumbersSyncHelp =>
      'የተጠሩ ቁጥሮች ከሰርቨር ይመጣሉ። በዝግተኛ ግንኙነት ላይ ትንሽ መዘግየት የተለመደ ነው።';

  @override
  String get calledNumbersSyncHelpTitle => 'የተጠሩ ቁጥሮች ማመሳሰል';

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
    return 'ቀጣይ ኳስ · $secondsሰ';
  }

  @override
  String get calledNumbersNextBallLabel => 'Next ball';

  @override
  String get calledNumbersFirstBallLabel => 'First ball';

  @override
  String calledNumbersWaitingFirstBallIn(int seconds) {
    return 'የመጀመሪያ ኳስ በመጠበቅ · $secondsሰ';
  }

  @override
  String get calledNumbersCallingNext => 'እየተጠራ…';

  @override
  String get calledNumbersSyncingNextBall => 'Syncing next ball…';

  @override
  String calledNumbersDrawLabel(int order) {
    return 'Draw #$order';
  }

  @override
  String get calledNumbersSyncingMissed => 'ያለፉ ቁጥሮች እየተመሳሰሉ…';

  @override
  String get calledNumbersWaitingNextBall => 'ቀጣይ ኳስ በመጠበቅ ላይ…';

  @override
  String get calledNumbersAllBallsDrawn => 'ሁሉም ኳሶች ተጥሰዋል';

  @override
  String get calledNumbersWillAppear => 'ቁጥሮች እዚህ ይታያሉ';

  @override
  String get calledNumbersCheckingBingo => 'ቢንጎ እየተፈተኸ…';

  @override
  String get calledNumbersClaimHoldNote => 'ጥያቄዎ ከተሰራ በኋላ አዲስ ቁጥሮች ይታያሉ።';

  @override
  String get registrationSignUpToPlay => 'ለመጫወት ተመዝገብ';

  @override
  String get bulkReviewTitle => 'ካርቴሎቻችን ይገምግሙ';

  @override
  String get bulkRegisteringTitle => 'ካርቴሎች እየተመዘገቡ ነው';

  @override
  String bulkCartelasTotal(int count, String total) {
    return '$count ካርቴሎች · ጠቅላላ $total';
  }

  @override
  String bulkPerCartela(String fee) {
    return 'በካርቴሎ $fee';
  }

  @override
  String get bulkConfirmNumbers => 'ቁጥሮቹን አረጋግጥ፣ ከዚያ አብረው ምዝገባ።';

  @override
  String get bulkStarting => 'ምዝገባ እየተጀመረ ነው...';

  @override
  String bulkProgress(int completed, int total) {
    return '$completed ከ$total ካርቴሎች እየተመዘገቡ ነው...';
  }

  @override
  String get bulkCancel => 'ሰርዝ';

  @override
  String bulkRegister(int count) {
    return '$count ምዝገባ';
  }

  @override
  String get bulkRegistering => 'እየተመዘገበ ነው...';

  @override
  String get bulkCouldNotRegister =>
      'የተመረጡ ካርቴሎችን ማስመዝገብ አልተቻለም። እባክዎ ደግም ይሞክሩ።';

  @override
  String bulkTakenNumbers(String numbers) {
    return 'የተመረጡ ካርቴሎችን ማስመዝገብ አልተቻለም። $numbers ተወስዷል።';
  }

  @override
  String get winnerBannerSyncingTitle => 'ቀጥታ ጨዋታ እየተመሳሰለ ነው…';

  @override
  String get winnerBannerSyncingMessage => 'ቀጥታ ዙሩ ከሰርቨር እየዘመነ ነው።';

  @override
  String get winnerBannerWindowOpenTitle => 'የአሸናፊ መስኮት ክፍት ነው';

  @override
  String get winnerBannerWindowOpenMessage =>
      'ሌሎች ተጫዋቾች በአሸናፊ መስኮቱ ውስጥ አሁንም ሊጠይቁ ይችላሉ።';

  @override
  String get winnerBannerYouWonTitle => 'አሸነፍክ!';

  @override
  String winnerBannerWonWithPayout(String amount) {
    return 'እንኳን ደስ አለህ! $amount ብር አሸነፍክ። ቀጣይ ምዝገባ ብዙ ሳይቆይ ይከፈታል።';
  }

  @override
  String get winnerBannerWonNoPayout =>
      'እንኳን ደስ አለህ! ካርቴሎህ አሸነፈ። ሽልማቱ እየዘመነ ነው። ቀጣይ ምዝገባ ብዙ ሳይቆይ ይከፈታል።';

  @override
  String get winnerBannerFinishedTitle => 'ጨዋታ ተጠናቀቀ';

  @override
  String get winnerBannerFinishedMessage =>
      'ይህ ጨዋታ ተጠናቅቋል። በሚቀጥለው ዕድለኛ ሁን! ቀጣይ ምዝገባ ብዙ ሳይቆይ ይከፈታል።';

  @override
  String get winnerBannerNoPlayersTitle => 'ምንም ተጫዋቾች አልተቀላቀሉም';

  @override
  String get winnerBannerNoPlayersMessage =>
      'በዚህ ዙር ምንም ተጫዋቾች አልተቀላቀሉም። ቀጣይ ዙር እየተጀመረ ነው…';

  @override
  String get winnerBannerCancelledTitle => 'ጨዋታ ተሰርዟል';

  @override
  String get winnerBannerCancelledMessage =>
      'ይህ ጨዋታ ተሰርዟል። የምዝገባ ክፍያዎች ተመልሰዋል። ቀጣይ ዙር እየተጀመረ ነው…';

  @override
  String get drawerSignInToPlay => 'ለመጫወት እና ካርቴሎ ለመመዝገብ ግባ';

  @override
  String get drawerBalance => 'ቀሪ';

  @override
  String get drawerJoinTheGame => 'ወደ ጨዋታው ተቀላቀል';

  @override
  String get drawerJoinTheGameBody => 'ካርቴሎ ለመመዝገብ እና ቦርሳህን ለማስተዳደር መለያ ፍጠር።';

  @override
  String get drawerLiveGame => 'ቀጥታ ጨዋታ';

  @override
  String get drawerWallet => 'ቦርሳ';

  @override
  String get drawerProfile => 'መገለጫ';

  @override
  String get drawerHistory => 'ታሪክ';

  @override
  String get drawerTransactionHistory => 'የግብይት ታሪክ';

  @override
  String get drawerGameHistory => 'የጨዋታ ታሪክ';

  @override
  String get drawerAppVersion => 'የመተግበሪያ ስሪት';

  @override
  String get drawerAppVersionUpToDate => 'ዘምኗል';

  @override
  String get drawerAppVersionUpdateAvailable => 'ዝመና አለ';

  @override
  String get drawerAppVersionUpdateRequired => 'ዝመና ያስፈልጋል';

  @override
  String get drawerAppVersionChecking => 'ዝመና በመፈተሽ ላይ…';

  @override
  String drawerAppVersionCurrent(String version) {
    return 'የተጫነ፡ $version';
  }

  @override
  String get noUpdateAvailableTitle => 'ምንም ዝመና የለም';

  @override
  String get noUpdateAvailableBody => 'በእርስዎ ላይ የቅርብ ጊዜው ስሪት ተጭኗል።';

  @override
  String get noUpdateAvailableOk => 'እሺ';

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
  String get updateAvailableTitle => 'ዝመና አለ';

  @override
  String get updateRequiredTitle => 'ዝመና ያስፈልጋል';

  @override
  String get updateLater => 'በኋላ';

  @override
  String get updateAction => 'አዘምን';

  @override
  String updateAvailableMessage(String version) {
    return 'ስሪት $version አለ።';
  }

  @override
  String updateRequiredMessage(String version) {
    return 'አዲስ ስሪት ($version) ለመቀጠል ያስፈልጋል።';
  }

  @override
  String get updateLinkUnavailable => 'የዝመና አገናኝ አይገኝም።';

  @override
  String get guestPromptTitle => 'ይህን ካርቴሎ ለመመዝገብ መለያ ፍጠር';

  @override
  String get guestPromptMessage =>
      'የካርቴሎ ቁጥሮችን ለመምረጥ እና ጨዋታ ለመቀላቀል ተመዝገብ ወይም ግባ።';

  @override
  String get guestPromoModeLabel => 'የእንግዳ ሁኔታ';

  @override
  String get guestPromoTitle => 'ቀጥታ የወጡ ቁጥሮችን ተመልከት፣ ለቀጣዩ ዙር ተቀላቀል';

  @override
  String get guestPromoMessage =>
      'ቁጥሮች በቅጽበት ሲወጡ ተመልከት፣ ከዚያም ቀጣዩ ተራ ጨዋታ ከመጀመሩ በፊት ካርቴላዎችን ለመያዝ ግባ ወይም መለያ ፍጠር።';

  @override
  String get guestPromoFooter => 'ፈጣን ምዝገባ። የቀጣይ ዙር መዳረሻ። የቀጥታ ቢንጎ ኃይል።';

  @override
  String get guestPromoRowLabel => 'የረድፍ መስመር';

  @override
  String get guestPromoRowHelper => 'በመጀመሪያ ሙሉ ረድፍ ይሞላል።';

  @override
  String get guestPromoColumnLabel => 'የአምድ መስመር';

  @override
  String get guestPromoColumnHelper => 'ከዚያ ሙሉ አምድ ይሞላል።';

  @override
  String get guestPromoDiagonalLabel => 'ዲያጎናል ቢንጎ';

  @override
  String get guestPromoDiagonalHelper => 'በመጨረሻ ዲያጎናሉ ቢንጎን ይጨርሳል።';

  @override
  String get guestPromoWinnerLabel => 'አሸናፊ';

  @override
  String get guestPromoCongratsTitle => 'እንኳን ደስ አለህ!';

  @override
  String guestPromoCongratsAmountWon(String amount) {
    return '$amount አሸንፈሃል';
  }

  @override
  String guestPromoCongratsReceived(String amount) {
    return '$amount በሲቢኢ ባንክ ተቀብለሃል።';
  }

  @override
  String get guestPromoCongratsWithdraw => 'ለማውጣት ግባ ወይም ተመዝገብ።';

  @override
  String get drawerTheme => 'ገጽታ';

  @override
  String get drawerThemeLight => 'ብርሃን';

  @override
  String get drawerThemeDark => 'ጨለማ';

  @override
  String get drawerThemeAuto => 'ራስ-ሰር';

  @override
  String get drawerLogout => 'ውጣ';

  @override
  String get drawerJoinGame => 'ወደ ጨዋታው ተቀላቀል';

  @override
  String get drawerCreateAccount => 'ካርቴሎ ለመመዝገብ እና ቦርሳህን ለማስተዳደር መለያ ፍጠር።';

  @override
  String get gameStats => 'የጨዋታ ስታቲስቲክስ';

  @override
  String get gameStatsHide => 'ስታቲስቲክስ ደብቅ';

  @override
  String get gameStatsShow => 'ስታቲስቲክስ አሳይ';

  @override
  String get gameInfoEntry => 'መግቢያ';

  @override
  String get gameInfoPrize => 'ሽልማት';

  @override
  String get gameInfoReg => 'ምዝ';

  @override
  String get gameInfoCalled => 'ተጠሪ';

  @override
  String get gameInfoGame => 'ጨዋታ';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusReconnecting => 'እንደገና ይያያዛል';

  @override
  String get statusOffline => 'ተቋርጧል';

  @override
  String get gameHintGuest => 'ካርቴሎ ለመመዝገብ ተመዝገብ';

  @override
  String get gameHintSelectMode => 'ቁጥሮችን ለመምረጥ ጠቅ አድርግ · ሲዘጋጅ ይገምግሙ';

  @override
  String get gameHintSingleMode => 'ለመመልከት ጠቅ አድርግ · ብዙ ለመምረጥ ይይዝ';

  @override
  String get gameClear => 'ሰርዝ';

  @override
  String gameReview(int count) {
    return 'ይገምግሙ ($count)';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds ሰ ቀርቷል';
  }

  @override
  String gameUpTo(int max) {
    return 'እስከ $max';
  }

  @override
  String get gameBalanceLeft => 'ቀርቷል';

  @override
  String get gameSyncing => 'ቀጥታ ጨዋታ እየተመሳሰለ ነው…';

  @override
  String get gameSyncingMessage => 'ቀጥታ ዙሩ ከሰርቨር እየዘመነ ነው።';

  @override
  String get gameWinnerWindowOpen => 'የአሸናፊ መስኮት ክፍት ነው';

  @override
  String get gameWinnerWindowMessage =>
      'ሌሎች ተጫዋቾች በአሸናፊ መስኮቱ ውስጥ አሁንም ሊጠይቁ ይችላሉ።';

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
  String get gameYouWon => 'አሸነፍክ!';

  @override
  String get gameNextRegistration => 'ቀጣይ ምዝገባ ብዙ ሳይቆይ ይከፈታል።';

  @override
  String gameWonAmount(String amount) {
    return 'እንኳን ደስ አለህ! $amount ብር አሸነፍክ።';
  }

  @override
  String get gameWonPending => 'እንኳን ደስ አለህ! ካርቴሎህ አሸነፈ። ሽልማቱ እየዘመነ ነው።';

  @override
  String get gameFinished => 'ጨዋታ ተጠናቀቀ';

  @override
  String get gameFinishedMessage =>
      'ይህ ጨዋታ ተጠናቅቋል። በሚቀጥለው ዕድለኛ ሁን! ቀጣይ ምዝገባ ብዙ ሳይቆይ ይከፈታል።';

  @override
  String postGameSummaryNextRoundIn(int seconds) {
    return 'ቀጣይ በ $seconds ሰ';
  }

  @override
  String get postGameSummaryTapToViewWinner => 'አሸናፊ ካርቴላ ለመመልከት ይንኩ';

  @override
  String get postGameSummaryNextGame => 'Continue';

  @override
  String get postGameSummaryOpeningNextRound => 'Opening next round…';

  @override
  String finishedGamePrizeLine(String amount) {
    return 'ለዚህ ጨዋታ የሽልማቱ $amount ነው';
  }

  @override
  String get reviewModeWinnerTitle => 'አሸናፊ';

  @override
  String reviewModeWinnerCartela(int number) {
    return 'ካርቴላ #$number';
  }

  @override
  String reviewModeAdditionalWinners(int count) {
    return '+$count ተጨማሪ አሸናፊ(ዎች)';
  }

  @override
  String get gameNoPlayers => 'ምንም ተጫዋቾች አልተቀላቀሉም';

  @override
  String get gameNoPlayersMessage =>
      'በዚህ ዙር ምንም ተጫዋቾች አልተቀላቀሉም። ቀጣይ ዙር እየተጀመረ ነው…';

  @override
  String get gameCancelled => 'ጨዋታ ተሰርዟል';

  @override
  String get gameCancelledMessage =>
      'ይህ ጨዋታ ተሰርዟል። የምዝገባ ክፍያዎች ተመልሰዋል። ቀጣይ ዙር እየተጀመረ ነው…';

  @override
  String get bulkConfirmHint => 'ለመመልከት ነካ · ለማስወገድ X · ዝግጁ ሲሆን ይመዝገቡ';

  @override
  String bulkRemoveCartela(int number) {
    return 'ካርቴላ #$number አስወግድ';
  }

  @override
  String get bulkReviewEmpty => 'ለመመዝገብ ቢያንስ አንድ ካርቴላ ይምረጡ።';

  @override
  String bulkRegisterCount(int count) {
    return '$count ምዝገባ';
  }

  @override
  String get bulkRegisterError => 'የተመረጡ ካርቴሎችን ማስመዝገብ አልተቻለም። እባክዎ ደግም ይሞክሩ።';

  @override
  String get bulkRegisterFailed => 'የተመረጡ ካርቴሎችን ማስመዝገብ አልተቻለም።';

  @override
  String bulkRegisterTaken(String numbers) {
    return 'የተመረጡ ካርቴሎችን ማስመዝገብ አልተቻለም። $numbers ተወስዷል።';
  }

  @override
  String depositHistoryRef(String ref) {
    return 'ማጣቀሻ: $ref';
  }

  @override
  String get depositHistoryRetry => 'ማረጋገጫ ደግም ሞክር';

  @override
  String depositHistoryRetriedStatus(String status) {
    return 'ማረጋገጫ ደግሟል። ሁኔታ: $status።';
  }

  @override
  String get depositHistoryCouldNotRetry => 'ማረጋገጫ ደግሞ ለማሞከር አልተቻለም።';

  @override
  String withdrawHistoryPhone(String phone) {
    return 'ስልክ: $phone';
  }

  @override
  String withdrawHistoryAccount(String account) {
    return 'መለያ: $account';
  }

  @override
  String withdrawHistoryNote(String note) {
    return 'ማስታወሻ: $note';
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
  String get bigGameEntryFee => 'Entry Fee';

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
  String get gameCategoryBonus => 'Bonus Game';

  @override
  String get gameCategoryBigGotd => 'Big GOTD';

  @override
  String get gameCategoryBigGame => 'Big Game';

  @override
  String get gameBonusFreeEntry => 'Free entry';

  @override
  String gameBonusFixedPrize(String amount) {
    return 'Fixed prize: $amount';
  }

  @override
  String gameBonusMaxCartelas(int count) {
    return 'Max $count cartelas';
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
  String get gamesHubBonus => 'Bonus Game';

  @override
  String get gamesHubUpcomingEvent => 'Upcoming Event';

  @override
  String get gamesHubNoLiveTitle => 'No live game right now';

  @override
  String get gamesHubNoLiveBody => 'Check back soon for the next round.';

  @override
  String get gamesHubNoBonusTitle => 'Bonus Game not available';

  @override
  String get gamesHubNoBonusBody => 'No bonus round is scheduled today.';

  @override
  String get gamesHubStartsAfterCurrent => 'Starts after current round';

  @override
  String get gamesHubJoinLive => 'Join';

  @override
  String get gamesHubOpenBonus => 'Open Bonus Game';

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
  String get announcementBonusTitle => 'Bonus Game Today';

  @override
  String get announcementBonusBody => 'Starts after current round';

  @override
  String get announcementBonusAction => 'Play Free';

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
