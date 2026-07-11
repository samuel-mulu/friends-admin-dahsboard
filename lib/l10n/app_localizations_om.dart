// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appTitle => 'Friends Bingo-online';

  @override
  String get appBarHi => 'Akkam, ';

  @override
  String get signIn => 'Seeni';

  @override
  String get signUp => 'Galmaa\'i';

  @override
  String get logout => 'Ba\'i';

  @override
  String get language => 'Afaan';

  @override
  String get themeLight => 'Ifaa';

  @override
  String get themeDark => 'Gurraacha';

  @override
  String get themeAuto => 'Ofumaan';

  @override
  String get theme => 'Dhangii';

  @override
  String get loginTitle => 'Baga nagaan deebite';

  @override
  String get loginPhone => 'Lakkoofsa bilbilaa';

  @override
  String get loginPhoneHint => '091*******';

  @override
  String get loginPassword => 'Jecha iccitii';

  @override
  String get loginPasswordHint => 'Jecha iccitii kee galchi';

  @override
  String get loginForgotPassword => 'Jecha iccitii dagattee?';

  @override
  String get loginSignIn => 'Seeni';

  @override
  String get loginCreateAccount => 'Herrega haaraa uumi';

  @override
  String get registerFullName => 'Maqaa guutuu';

  @override
  String get registerFullNameHint => 'Maqaa guutuu';

  @override
  String get registerPassword => 'Jecha iccitii';

  @override
  String get registerPasswordHint => 'Yoo xiqqaate arfiilee 6';

  @override
  String get registerConfirmPassword => 'Jecha iccitii mirkaneessi';

  @override
  String get registerConfirmPasswordHint =>
      'Jecha iccitii kee irra deebi\'ii galchi';

  @override
  String get registerContinue => 'Itti fufi';

  @override
  String get registerAlreadyHaveAccount => 'Herrega qabdaa? Seeni';

  @override
  String get forgotPasswordTitle => 'Jecha iccitii haaromsi';

  @override
  String get forgotPasswordSubtitle =>
      'Koodii mirkaneessaa argachuuf lakkoofsa bilbilaa kee galchi.';

  @override
  String get forgotPasswordSendCode => 'Koodii mirkaneessaa ergi';

  @override
  String get forgotPasswordBackToSignIn => 'Gara seensaa deebi\'i';

  @override
  String get otpVerifyPhone => 'Bilbila kee mirkaneessi';

  @override
  String otpSentTo(String phone) {
    return 'Koodiin gara $phone ergame.';
  }

  @override
  String get otpCreateAccount => 'Herrega uumi';

  @override
  String get otpResendCode => 'Koodii irra deebi\'ii ergi';

  @override
  String otpResendInSeconds(int seconds) {
    return 'Sekondii $seconds keessatti irra deebi\'ii ergi';
  }

  @override
  String otpResendInMinutes(int minutes) {
    return 'Daqiiqaa $minutes keessatti irra deebi\'ii ergi';
  }

  @override
  String otpResendInMinutesSeconds(int minutes, int seconds) {
    return 'Daqiiqaa $minutes fi sekondii $seconds keessatti irra deebi\'ii ergi';
  }

  @override
  String get otpBackToDetails => 'Gara ibsaatti deebi\'i';

  @override
  String get otpEnterCode => 'Koodii mirkaneessaa dijiitii 6 galchi.';

  @override
  String get otpSmsBanner =>
      'Koodii mirkaneessaa SMS\'n gara bilbila keetti ergame galchi.';

  @override
  String get resetPasswordTitle => 'Jecha iccitii haaraa kaa\'i';

  @override
  String resetPasswordSmsSentTo(String phone) {
    return 'Koodii SMS gara $phone ergame galchi.';
  }

  @override
  String get resetPasswordNewPassword => 'Jecha iccitii haaraa';

  @override
  String get resetPasswordConfirmNew => 'Jecha iccitii haaraa mirkaneessi';

  @override
  String get resetPasswordConfirmNewHint =>
      'Jecha iccitii haaraa kee irra deebi\'ii galchi';

  @override
  String get resetPasswordUpdate => 'Jecha iccitii haaromsi';

  @override
  String get resetPasswordBackToPhone => 'Gara lakkoofsa bilbilaa deebi\'i';

  @override
  String get validatorPhoneRequired => 'Lakkoofsi bilbilaa barbaachisa.';

  @override
  String get validatorPhoneInvalid => 'Lakkoofsa bilbilaa sirrii galchi.';

  @override
  String get validatorPasswordLength =>
      'Jechi iccitii yoo xiqqaate arfiilee 6 ta\'uu qaba.';

  @override
  String get validatorFullNameLength =>
      'Maqaan guutuun yoo xiqqaate arfiilee 3 ta\'uu qaba.';

  @override
  String get validatorPasswordMismatch => 'Jechoonni iccitii wal hin simne.';

  @override
  String get validatorAmountRequired => 'Hanga barbaachisa.';

  @override
  String get validatorAmountInvalid => 'Hanga sirrii galchi.';

  @override
  String get validatorAmountPositive => 'Hangni zeeroo ol ta\'uu qaba.';

  @override
  String get validatorTransactionRef => 'Wabii daldalaa sirrii galchi.';

  @override
  String dashboardHello(String name) {
    return 'Akkam, $name';
  }

  @override
  String get dashboardSubtitle =>
      'Tapha kallattii bani, kaartelaa kee asitti galmeessi, boorsa kee bakka tokkotti too\'adhu.';

  @override
  String get dashboardOpenLiveGame => 'Tapha kallattii bani';

  @override
  String get dashboardRole => 'Gahee';

  @override
  String get dashboardStatus => 'Haala';

  @override
  String get dashboardWalletSnapshot => 'Ibsa gabaabaa boorsaa';

  @override
  String dashboardAvailableBalance(String amount) {
    return 'Haftee jiru: $amount ETB';
  }

  @override
  String dashboardLockedBalance(String amount) {
    return 'Haftee cufame: $amount ETB';
  }

  @override
  String get dashboardOpenWallet => 'Boorsa bani';

  @override
  String get dashboardWalletLoading => 'Boorsa fe\'amaa jira...';

  @override
  String get dashboardWalletUnavailable => 'Boorsi amma hin argamu.';

  @override
  String get dashboardWhatIsNext => 'Itti aanu maal';

  @override
  String get dashboardWhatIsNextBody =>
      'Tartiiboonni itti aanan lakkoofsa kallattii, gaaffii bingo, galchii fi baasii gara bu\'uura kanaatti ni dabalamu.';

  @override
  String get walletAvailableBalance => 'Haftee jiru';

  @override
  String get walletLockedBalance => 'Haftee cufame';

  @override
  String get walletFreezBalance => 'Freez balance';

  @override
  String get walletTotalBalance => 'Total wallet';

  @override
  String get walletTotalEqualsHint => 'Available + Locked = Total wallet';

  @override
  String get walletDeposit => 'Galchi';

  @override
  String get walletWithdraw => 'Baasi';

  @override
  String get walletTransactionHistory => 'Seenaa daldalaa';

  @override
  String get walletTransactionHistorySubtitle => 'Sochii boorsaa hunda ilaali.';

  @override
  String get walletDepositHistory => 'Seenaa galchii';

  @override
  String get walletDepositHistorySubtitle =>
      'Adeemsa mirkaneessaa hordofi; yoo barbaachise irra deebi\'ii yaali.';

  @override
  String get walletWithdrawalHistory => 'Seenaa baasii';

  @override
  String get walletWithdrawalHistorySubtitle =>
      'Haala gaaffii, hayyama fi kaffaltii hordofi.';

  @override
  String get walletCouldNotLoad => 'Ibsi boorsaa fe\'uu hin dandeenye.';

  @override
  String get walletTryAgain => 'Irra deebi\'ii yaali';

  @override
  String get depositScreenTitle => 'Galchi';

  @override
  String get depositAmount => 'Hanga';

  @override
  String get depositFtNumber => 'Lakkoofsa FT';

  @override
  String get depositReceiptId => 'Eenyummaa nagahee';

  @override
  String get depositReceiptCode => 'Koodii nagahee';

  @override
  String get depositReceiptCodeInvalid =>
      'Koodii nagahee sirrii galchi (arfiilee fi lakkoofsa 6-20).';

  @override
  String get depositReceiptUrlNotAllowed =>
      'Koodii nagahee qofa galchi, URL guutuu hin galchin.';

  @override
  String get depositSuccessApproved => 'Galchiin milkaa\'e. Boorsi haaromfame.';

  @override
  String get depositReceiptDuplicate => 'Nagaheen kun dursee fayyadameera.';

  @override
  String get depositReceiptInvalid => 'Nagaheen mirkanaa\'uu hin dandeenye.';

  @override
  String get depositAmountMismatch =>
      'Hangni nagahee kana wajjin wal hin simne. Hanga nagahee irratti mul\'atu galchi.';

  @override
  String depositAmountMismatchSettled(String settledAmount) {
    return 'Hangi nagahee kanaa $settledAmount ETB dha. Hangicha galchi—kaffaltii waliigalaa (kaffaltii Telebirr hin galchamu).';
  }

  @override
  String get depositReceiverMismatch =>
      'Nagaheen kun gara Friends Bingo hin kaffalamne.';

  @override
  String get depositDevHelper => 'Gargaaraa qorannoo/fooyya\'insaa';

  @override
  String depositDevReference(String ref) {
    return 'Wabii qorannoo: $ref';
  }

  @override
  String get depositUseTestRef => 'Wabii qorannoo fayyadami';

  @override
  String get depositSubmit => 'Galchi galchi';

  @override
  String get depositGuideTitle => 'How to deposit';

  @override
  String get depositGuideTelebirrStep1 =>
      'Open Telebirr and send money to Friends Bingo';

  @override
  String get depositGuideTelebirrStep2 =>
      'Open the receipt and copy the transaction number';

  @override
  String get depositGuideTelebirrStep3 =>
      'Enter the settled amount and receipt code below';

  @override
  String get depositGuideCbeStep1 =>
      'Open CBE mobile banking and transfer to Friends Bingo';

  @override
  String get depositGuideCbeStep2 =>
      'Copy the FT reference number from the receipt';

  @override
  String get depositGuideCbeStep3 =>
      'Enter the exact amount and reference below';

  @override
  String get depositGuideAwashStep1 =>
      'Open Awash mobile banking and send payment';

  @override
  String get depositGuideAwashStep2 => 'Copy the payment reference number';

  @override
  String get depositGuideAwashStep3 =>
      'Enter the exact amount and reference below';

  @override
  String get depositGuideBoaStep1 => 'Open BOA mobile banking and send payment';

  @override
  String get depositGuideBoaStep2 => 'Copy the payment reference number';

  @override
  String get depositGuideBoaStep3 =>
      'Enter the exact amount and reference below';

  @override
  String get depositVerifying => 'Verifying your payment…';

  @override
  String get depositApprovedTitle => 'Deposit approved';

  @override
  String get depositRejectedTitle => 'Deposit failed';

  @override
  String get depositTryAgain => 'You can correct the details and try again.';

  @override
  String get depositSelectProvider => 'Payment method';

  @override
  String get depositSendToAccount => 'Send to this account';

  @override
  String get depositShowInstructions => 'Instructions';

  @override
  String get depositReceiptReviewLabel =>
      'I have checked the amount and reference number from my transaction';

  @override
  String get depositCopyAccount => 'Copy account';

  @override
  String get depositAccountCopied => 'Account copied';

  @override
  String get depositGuideImageMissing => 'Screenshot coming soon';

  @override
  String get depositGuideTapToExpand => 'Tap to enlarge';

  @override
  String get walletQuickDeposit =>
      'Add funds instantly via mobile money or bank transfer';

  @override
  String get depositLatest => 'Galchi dhiyoo';

  @override
  String depositSubmittedStatus(String status) {
    return 'Galchi dhiyaate. Haala: $status.';
  }

  @override
  String get depositCouldNotSubmit => 'Galchi galchuu hin dandeenye.';

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
    return 'Dhiyeessaa: $provider';
  }

  @override
  String depositAmountLabel(String amount) {
    return 'Hanga: $amount';
  }

  @override
  String depositReference(String ref) {
    return 'Wabii: $ref';
  }

  @override
  String depositCreated(String date) {
    return 'Uumame: $date';
  }

  @override
  String depositRejectionReason(String reason) {
    return 'Sababa: $reason';
  }

  @override
  String get depositHistoryTitle => 'Seenaa galchii';

  @override
  String get depositHistoryEmpty => 'Amma galchi hin jiru';

  @override
  String get depositHistoryEmptyMessage =>
      'Gaaffii galchii kee asitti ni mul\'ata.';

  @override
  String get depositHistoryCouldNotLoad =>
      'Seenaa galchii fe\'uu hin dandeenye.';

  @override
  String get depositRetryVerification => 'Mirkaneessaa irra deebi\'ii yaali';

  @override
  String depositRetried(String status) {
    return 'Mirkaneessaan irra deebi\'ame. Haala: $status.';
  }

  @override
  String get depositRetryFailed =>
      'Mirkaneessaa irra deebi\'ii yaaluu hin dandeenye.';

  @override
  String depositAmountRow(String amount) {
    return 'Hanga: $amount';
  }

  @override
  String depositRefRow(String ref) {
    return 'Wabii: $ref';
  }

  @override
  String depositCreatedRow(String date) {
    return 'Uumame: $date';
  }

  @override
  String depositReasonRow(String reason) {
    return 'Sababa: $reason';
  }

  @override
  String get withdrawScreenTitle => 'Baasi';

  @override
  String get withdrawAmount => 'Hanga';

  @override
  String get withdrawSubmit => 'Baasii galchi';

  @override
  String get withdrawLatest => 'Baasii dhiyoo';

  @override
  String withdrawSubmittedStatus(String status) {
    return 'Baasiin dhiyaate. Haala: $status.';
  }

  @override
  String get withdrawCouldNotSubmit => 'Baasii galchuu hin dandeenye.';

  @override
  String withdrawStatusLabel(String status) {
    return 'Haala: $status';
  }

  @override
  String withdrawProviderLabel(String provider) {
    return 'Dhiyeessaa: $provider';
  }

  @override
  String withdrawAmountLabel(String amount) {
    return 'Hanga: $amount';
  }

  @override
  String withdrawPhoneLabel(String phone) {
    return 'Bilbila: $phone';
  }

  @override
  String withdrawAccountLabel(String account) {
    return 'Herrega: $account';
  }

  @override
  String withdrawCreatedLabel(String date) {
    return 'Uumame: $date';
  }

  @override
  String withdrawNoteLabel(String note) {
    return 'Yaadannoo: $note';
  }

  @override
  String get withdrawHistoryTitle => 'Seenaa baasii';

  @override
  String get withdrawHistoryEmpty => 'Amma baasii hin jiru';

  @override
  String get withdrawHistoryEmptyMessage =>
      'Gaaffii baasii kee asitti ni mul\'ata.';

  @override
  String get withdrawHistoryCouldNotLoad =>
      'Seenaa baasii fe\'uu hin dandeenye.';

  @override
  String get withdrawSelectProvider => 'Payout method';

  @override
  String get withdrawMaxWithdrawableHint =>
      'You can withdraw up to your available balance. The rest stays usable for cartelas.';

  @override
  String get withdrawLockedFundsHint =>
      'Locked funds are reserved for pending withdrawal requests.';

  @override
  String get withdrawAmountLockedHelper =>
      'This amount will be locked until admin processes your request.';

  @override
  String get withdrawAmountExceedsAvailable =>
      'Amount exceeds your available balance.';

  @override
  String get withdrawPendingTitle => 'Withdrawal submitted';

  @override
  String get withdrawPendingMessage =>
      'Your request is pending admin review. The amount is locked until approved or rejected.';

  @override
  String get withdrawApprovedTitle => 'Withdrawal approved';

  @override
  String get withdrawApprovedMessage =>
      'Your payout has been approved and sent.';

  @override
  String get withdrawRejectedTitle => 'Withdrawal rejected';

  @override
  String get withdrawRejectedMessage =>
      'Your withdrawal was rejected. Locked funds were returned to your balance.';

  @override
  String get withdrawStatusPendingReview => 'Pending review';

  @override
  String get withdrawStatusApproved => 'Approved';

  @override
  String get withdrawStatusRejected => 'Rejected';

  @override
  String get withdrawStatusFailed => 'Failed';

  @override
  String get withdrawStatusRefunded => 'Refunded';

  @override
  String get walletLockedBalanceHint =>
      'Includes funds reserved for pending withdrawals.';

  @override
  String get withdrawRequestsTitle => 'Your withdrawal requests';

  @override
  String get withdrawTabAll => 'All';

  @override
  String get withdrawTabPending => 'Pending';

  @override
  String get withdrawTabCompleted => 'Completed';

  @override
  String get withdrawTabRejected => 'Rejected';

  @override
  String get withdrawTableDate => 'Date';

  @override
  String get withdrawTableAmount => 'Amount';

  @override
  String get withdrawTableProvider => 'Provider';

  @override
  String get withdrawTableStatus => 'Status';

  @override
  String get withdrawPendingEmpty => 'No pending withdrawal requests.';

  @override
  String get withdrawCompletedEmpty => 'No completed withdrawals yet.';

  @override
  String get withdrawRejectedEmpty => 'No rejected withdrawals.';

  @override
  String get txHistoryTitle => 'Daldala boorsaa';

  @override
  String get txHistoryEmpty => 'Amma daldalli hin jiru';

  @override
  String get txHistoryEmptyMessage =>
      'Galchii, galmeessaa fi baasii booda seenaan boorsaa kee asitti ni mul\'ata.';

  @override
  String txHistoryShowing(int count, int total) {
    return 'Daldala $total keessaa $count agarsiisaa jira';
  }

  @override
  String get txHistoryWalletActivity => 'Sochii boorsaa';

  @override
  String get txWithdrawRequestLockedNote =>
      'Moved to locked balance pending approval.';

  @override
  String txHistoryBalanceAfter(String amount) {
    return 'Haftee: $amount';
  }

  @override
  String get txHistoryCouldNotLoad => 'Seenaa daldalaa fe\'uu hin dandeenye.';

  @override
  String get gameHistoryTitle => 'Seenaa taphaa';

  @override
  String get gameHistoryEmpty => 'Taphni xumurame amma hin jiru.';

  @override
  String gameHistoryCards(int count) {
    return 'Kaardii $count';
  }

  @override
  String get gameHistoryLoadingAttended => 'Taphoota kee fe\'amaa jiru...';

  @override
  String get gameHistoryEmptyAttended =>
      'Taphoota xumurame kee hirmaatan amma hin jiru.';

  @override
  String get gameHistoryDetailTitle => 'Ibsa taphaa';

  @override
  String get gameHistoryPrizePool => 'Badhaasa';

  @override
  String gameHistoryYourWinnings(String amount) {
    return 'Badhaasa $amount argatte';
  }

  @override
  String get gameHistoryYourCartelas => 'Kaartelaa kee';

  @override
  String get gameHistorySessionWinners => 'Mo\'atoota taphaa';

  @override
  String gameHistoryMyCartelaCount(int count) {
    return 'Kan kee $count';
  }

  @override
  String get gameHistoryLoadMore => 'Dabalataa fe\'i';

  @override
  String get gameHistoryRetry => 'Irra deebi\'ii yaali';

  @override
  String get gameStatsLabel => 'Istaatistiksii taphaa';

  @override
  String get gameHideStats => 'Istaatistiksii dhoksi';

  @override
  String get gameShowStats => 'Istaatistiksii agarsiisi';

  @override
  String get gameEntryLabel => 'Seensa';

  @override
  String get gamePrizeLabel => 'Badhaasa';

  @override
  String get gameRegLabel => 'Galmeessa';

  @override
  String get gameCalledLabel => 'Waamame';

  @override
  String get gameNowPlaying => 'AMMA TAPHAA JIRA';

  @override
  String get gameNextGame => 'Tapha itti aanu';

  @override
  String get liveCalledNumbersLabel => 'Lakkoofsa waamaman';

  @override
  String get liveNextRoundSectionTitle => 'Raawundii itti aanu';

  @override
  String get liveJoinCurrentRoundSectionTitle => 'Raawundii ammaa hirmaadhu';

  @override
  String get liveMissedCurrentRoundTitle => 'Raawundiin ammaa taphatamaa jira';

  @override
  String get liveNextQueuedPlayLabel => 'Tapha itti aanu';

  @override
  String get liveRegisteredCartelasLabel => 'Kaartelaa galmaa\'an';

  @override
  String get liveRegisteredCartelasEmpty =>
      'Amma hin jiru — armaan gadii lakkoofsa filadhu.';

  @override
  String get liveMissedRoundHelper =>
      'Raawundii kana irra darbite. Tapha itti aanuuf amma galmeessi.';

  @override
  String get liveMissedRoundYouMissedGame => 'Raawundii kana irra darbite.';

  @override
  String get liveMissedRoundOverviewTitle => 'Kallattii & raawundii itti aanu';

  @override
  String liveMissedRoundCollapsedMissed(String gameName) {
    return 'Darbitame · $gameName';
  }

  @override
  String liveMissedRoundCollapsedNextReady(String gameName) {
    return 'Itti aanu qophii · $gameName · amma galmeessi';
  }

  @override
  String get liveMissedRoundRegisterBridge =>
      'Tapha itti aanuuf amma kaartelaa galmeessiitii raawundii itti aanutti taphadhu.';

  @override
  String liveJoinCurrentRoundGameLive(String gameName) {
    return '$gameName amma kallattii taphatamaa jira';
  }

  @override
  String get liveNextGameBannerTitle => 'TAPHAA ITTI AANU';

  @override
  String get liveMissedRoundBannerSubtitle =>
      'Taphni itti aanu yeroo dhiyootti ni eegala';

  @override
  String get liveNextGameLabel => 'Tapha itti aanu';

  @override
  String get registrationStartsAfterCurrentGame =>
      'Registration open - starts after current game';

  @override
  String get liveJoinCurrentRoundHelper =>
      'Galmeessi raawundii kallattii kanaaf ammallee banaa dha. Kaartelaa fudhataman fi qabaman ofumaan cufamu.';

  @override
  String get liveAddMoreCartelasHelper =>
      'Galmeessi ammallee banaa dha. Raawundii yeroo taphatu kaartelaa dabalataa dabaluu dandeessa.';

  @override
  String get liveAddMoreCartelasTitle => 'Kaartelaa dabalataa dabaluu';

  @override
  String get liveNextRoundRegistrationTitle => 'Galmeessa raawundii itti aanu';

  @override
  String get gameRuleDetailTitle => 'Seera taphaa';

  @override
  String get gameRulePatternSample => 'Fakkeenya mo\'achuu';

  @override
  String get gameNextGameHide => 'Tapha itti aanu dhoksi';

  @override
  String get gameNextGameShow => 'Tapha itti aanu agarsiisi';

  @override
  String get leaveLiveGameTitle => 'Tapha kallattii dhiisi?';

  @override
  String get leaveLiveGameMessage =>
      'Taphni kee sarvar irratti itti fufa. Mallattoon kee meeshaa kana irratti ni kuufama.';

  @override
  String get leaveLiveGameStay => 'Turi';

  @override
  String get leaveLiveGameLeave => 'Ba\'i';

  @override
  String get confirmBackTitle => 'Deebi\'uu barbaaddaa?';

  @override
  String get confirmBackMessage => 'Fuula kana dhiisuu barbaaddaa?';

  @override
  String get confirmBackStay => 'Turi';

  @override
  String get confirmBackLeave => 'Ba\'i';

  @override
  String get exitAppTitle => 'Appii cufuu?';

  @override
  String get exitAppMessage =>
      'Taphni kee itti fufa. Yeroo kamiyyuu deebi\'uu dandeessa.';

  @override
  String get exitAppStay => 'Turi';

  @override
  String get exitAppExit => 'Cufi';

  @override
  String get winningCartelasTitle => 'Kaartelaa mo\'atan';

  @override
  String get winningCartelasTapHint =>
      'Akkaataa mo\'achuu guutuu ilaaluuf kaartelaa tuqi.';

  @override
  String get winningCartelasYou => 'Ati';

  @override
  String get winningCartelasPlayer => 'Taphataa';

  @override
  String winningCartelasPrize(String amount) {
    return 'Badhaasa: $amount ETB';
  }

  @override
  String winningCartelasDetailTitle(int number) {
    return 'Kaartelaa mo\'ate #$number';
  }

  @override
  String get winningCartelasSwipeHint =>
      'Mo\'ataa hunda ilaaluuf haxaa\'i ykn lakkoofsa tuqi';

  @override
  String winningCartelasWinningBall(String ball) {
    return 'Kubbaa mo\'achuu: $ball';
  }

  @override
  String get winningCartelasAllWinners => 'Mo\'atoota';

  @override
  String get winningCartelasPreviousWinner => 'Mo\'ataa duraan';

  @override
  String get winningCartelasNextWinner => 'Mo\'ataa itti aanu';

  @override
  String get cartelaOutcomeValid => 'Sirrii';

  @override
  String get cartelaOutcomeInvalid => 'Sirrii miti';

  @override
  String get cartelaOutcomeRegistered => 'Galmaa\'e';

  @override
  String get cartelaOutcomeNoWin => 'Hin mo\'amne';

  @override
  String get cartelaBlockedInfoTooltip => 'Kaartelaa kun maaliif cufame?';

  @override
  String cartelaBlockedDialogTitle(int number) {
    return 'Kaartelaa #$number cufame';
  }

  @override
  String get cartelaBlockedDialogOk => 'Hubadhe';

  @override
  String get cartelaBlockedReasonLate =>
      'Lakkoofsi mo\'ataa darbee kaartelaa kun cufameera.';

  @override
  String get cartelaBlockedReasonPattern =>
      'Bingo kee seera taphaa wajjin wal hin simne.';

  @override
  String get cartelaBlockedReasonGeneric => 'Kaartelaa kun cufameera.';

  @override
  String get gameLabel => 'Tapha';

  @override
  String get connectionOnline => 'Toora irratti';

  @override
  String get connectionReconnecting => 'Irra deebi\'aa wal qunnamsiisaa jira';

  @override
  String get connectionOffline => 'Toora irraa adda';

  @override
  String get registrationTapHintGuest => 'Kaartelaa galmeessuuf galmaa\'i';

  @override
  String get registrationTapHintSelect =>
      'Filachuuf lakkoofsa tuqi · Qophaa\'ee yoo ta\'e ilaali';

  @override
  String get registrationTapHintDefault => 'Dursee ilaaluuf lakkoofsa tuqi';

  @override
  String get registrationClear => 'Haqi';

  @override
  String registrationReview(int count) {
    return 'Ilaali ($count)';
  }

  @override
  String registrationSecondsLeft(int seconds) {
    return 'Sekondii $seconds hafe';
  }

  @override
  String registrationUpTo(int max) {
    return 'Hamma $max';
  }

  @override
  String get registrationLeft => ' hafe';

  @override
  String get registrationOpenBanner => 'GALMEESSI BANAA DHA';

  @override
  String get registrationOpenLabel => 'Galmeessi banaa dha';

  @override
  String registrationClosesIn(int seconds) {
    return 'Galmeessi sekondii $seconds keessatti ni cufa';
  }

  @override
  String registrationClosesInDuration(String duration) {
    return 'Galmeessi $duration keessatti ni cufa';
  }

  @override
  String get registrationClosedPreparing => 'Eegaa jira...';

  @override
  String get preparingGameNoCartelas =>
      'Galmeessi kaartelaa cufame. Raawundii kallattii yeroo dhiyoo ni jalqaba.';

  @override
  String preparingGameCartelasRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Kaartelaa $count galmaa\'an. Raawundii kallattii yeroo dhiyoo ni jalqaba.',
      one:
          'Kaartelaa 1 galmaa\'e. Raawundii kallattii yeroo dhiyoo ni jalqaba.',
    );
    return '$_temp0';
  }

  @override
  String get liveNoGameTitle => 'Taphni tarree irratti hin jiru';

  @override
  String get liveNoGameMessage =>
      'Amma taphni banaa hin jiru. Raawundii itti aanu yoo jalqabu gadi harkisi.';

  @override
  String get gameCheckingTitle => 'Gaaffii bingo mirkanaa\'aa jira';

  @override
  String get gameCheckingMessage =>
      'Gaaffii bingo mirkanaa\'aa jira. Eegi — lakkoofsa haaraa hin mallattein.';

  @override
  String calledNumbersDrawnCount(int count) {
    return 'Baafame: $count';
  }

  @override
  String calledNumbersBallOrder(int order) {
    return '#$order';
  }

  @override
  String get calledNumbersSyncLive => 'Kallattii';

  @override
  String get calledNumbersSyncCatchingUp => 'Wal simsiisaa jira…';

  @override
  String get calledNumbersSyncHelp =>
      'Lakkoofsi waamaman sarvar irraa wal simsiifamu. Qunnamtii suuta irratti xiqqoo dhiibbaa ni ta\'a.';

  @override
  String get calledNumbersSyncHelpTitle => 'Wal simsiisa lakkoofsa waamaman';

  @override
  String get calledNumbersSyncReconnecting =>
      'Irra deebi\'aa wal qunnamsiisaa jira…';

  @override
  String get calledNumbersRefreshTooltip => 'Lakkoofsa waamaman haaromsi';

  @override
  String get cartelaMarkColorGreen => 'Mallattoo magariisa';

  @override
  String get cartelaMarkColorRed => 'Mallattoo diimaa';

  @override
  String get cartelaMarkColorYellow => 'Mallattoo booraa';

  @override
  String get cartelaMarkColorBlue => 'Mallattoo cuquliisa';

  @override
  String get cartelaMarkColorMenu => 'Halluu mallattoo';

  @override
  String get cartelaClearMarks => 'Mallattoolee haqi';

  @override
  String calledNumbersNextBallIn(int seconds) {
    return 'Kubbaa itti aanu · sekondii $seconds';
  }

  @override
  String get calledNumbersNextBallLabel => 'Kubbaa itti aanu';

  @override
  String get calledNumbersFirstBallLabel => 'Kubbaa jalqabaa';

  @override
  String calledNumbersWaitingFirstBallIn(int seconds) {
    return 'Kubbaa jalqabaa eegaa jira · sekondii $seconds';
  }

  @override
  String get calledNumbersCallingNext => 'Waamamaa jira…';

  @override
  String get calledNumbersSyncingNextBall =>
      'Kubbaa itti aanu wal simsiisaa jira…';

  @override
  String calledNumbersDrawLabel(int order) {
    return 'Baafannaa #$order';
  }

  @override
  String get calledNumbersSyncingMissed =>
      'Lakkoofsa darban wal simsiisaa jira…';

  @override
  String get calledNumbersWaitingNextBall => 'Kubbaa itti aanu eegaa jira…';

  @override
  String get calledNumbersAllBallsDrawn => 'Kubbaan hundi baafame';

  @override
  String get calledNumbersWillAppear => 'Lakkoofsi asitti ni mul\'ata';

  @override
  String get calledNumbersCheckingBingo => 'Bingo mirkanaa\'aa jira…';

  @override
  String get calledNumbersClaimHoldNote =>
      'Gaaffii kee erga adeemsifamee booda lakkoofsi haaraa ni mul\'ata.';

  @override
  String get registrationSignUpToPlay => 'Taphachuuf galmaa\'i';

  @override
  String get bulkReviewTitle => 'Kaartelaa kee ilaali';

  @override
  String get bulkRegisteringTitle => 'Kaartelaa galmeessaa jira';

  @override
  String bulkCartelasTotal(int count, String total) {
    return 'Kaartelaa $count · waliigalaa $total';
  }

  @override
  String bulkPerCartela(String fee) {
    return 'Kaartelaa tokkotti $fee';
  }

  @override
  String get bulkConfirmNumbers =>
      'Lakkoofsa armaan olii mirkaneessi, achiis waliin galmeessi.';

  @override
  String get bulkStarting => 'Galmeessi jalqabaa jira...';

  @override
  String bulkProgress(int completed, int total) {
    return 'Kaartelaa $total keessaa $completed galmeessaa jira...';
  }

  @override
  String get bulkCancel => 'Haqi';

  @override
  String bulkRegister(int count) {
    return 'Galmeessi $count';
  }

  @override
  String get bulkRegistering => 'Galmeessaa jira...';

  @override
  String get bulkCouldNotRegister =>
      'Kaartelaa filataman galmeessuu hin dandeenye. Irra deebi\'ii yaali.';

  @override
  String bulkTakenNumbers(String numbers) {
    return 'Kaartelaa filataman galmeessuu hin dandeenye. $numbers dursee fudhatame.';
  }

  @override
  String get winnerBannerSyncingTitle => 'Tapha kallattii wal simsiisaa jira…';

  @override
  String get winnerBannerSyncingMessage =>
      'Raawundii kallattii sarvar irraa haaromfamaa jira.';

  @override
  String get winnerBannerWindowOpenTitle => 'Foddaa mo\'ataa banaa dha';

  @override
  String get winnerBannerWindowOpenMessage =>
      'Taphattoonni biroo foddaa mo\'ataa keessatti ammallee gaafachuu danda\'u.';

  @override
  String get winnerBannerYouWonTitle => 'Mo\'atte!';

  @override
  String winnerBannerWonWithPayout(String amount) {
    return 'Baga gammaddan! Badhaasa $amount ETB argatte. Galmeessi itti aanu yeroo dhiyoo ni bana.';
  }

  @override
  String get winnerBannerWonNoPayout =>
      'Baga gammaddan! Kaartelaa kee mo\'ate. Badhaasni haaromfamaa jira. Galmeessi itti aanu yeroo dhiyoo ni bana.';

  @override
  String get winnerBannerFinishedTitle => 'Taphni Xumurame';

  @override
  String get winnerBannerFinishedMessage =>
      'Taphni kun xumurame. Tapha itti aanu carraa gaarii! Galmeessi itti aanu yeroo dhiyoo ni bana.';

  @override
  String get winnerBannerNoPlayersTitle => 'Taphataan Hin Hirmaanne';

  @override
  String get winnerBannerNoPlayersMessage =>
      'Raawundii kana keessatti taphataan hin hirmaanne. Raawundii itti aanu jalqabaa jira…';

  @override
  String get winnerBannerCancelledTitle => 'Taphni Haqame';

  @override
  String get winnerBannerCancelledMessage =>
      'Taphni kun haqame. Kaffaltiin seensaa deebifame. Raawundii itti aanu jalqabaa jira…';

  @override
  String get drawerSignInToPlay => 'Taphachuuf fi kaartelaa galmeessuuf seeni';

  @override
  String get drawerBalance => 'Haftee';

  @override
  String get drawerJoinTheGame => 'Taphaatti makami';

  @override
  String get drawerJoinTheGameBody =>
      'Kaartelaa galmeessuuf fi boorsa kee too\'achuuf herrega uumi.';

  @override
  String get drawerLiveGame => 'Tapha Kallattii';

  @override
  String get drawerWallet => 'Boorsa';

  @override
  String get drawerProfile => 'Ibsa dhuunfaa';

  @override
  String get drawerHistory => 'Seenaa';

  @override
  String get drawerTransactionHistory => 'Seenaa daldalaa';

  @override
  String get drawerGameHistory => 'Seenaa taphaa';

  @override
  String get drawerAppVersion => 'Version appii';

  @override
  String get drawerAppVersionUpToDate => 'Ammaaf haaraa dha';

  @override
  String get drawerAppVersionUpdateAvailable => 'Haaromsa ni argama';

  @override
  String get drawerAppVersionUpdateRequired => 'Haaromsa barbaachisa';

  @override
  String get drawerAppVersionChecking => 'Haaromsa sakatta\'aa jira…';

  @override
  String drawerAppVersionCurrent(String version) {
    return 'Kan fe\'ame: $version';
  }

  @override
  String get noUpdateAvailableTitle => 'Haaromsi hin jiru';

  @override
  String get noUpdateAvailableBody => 'Version haaraan duraan fe\'amee jira.';

  @override
  String get noUpdateAvailableOk => 'TOLE';

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
  String get updateAvailableTitle => 'Haaromsa ni argama';

  @override
  String get updateRequiredTitle => 'Haaromsa barbaachisa';

  @override
  String get updateLater => 'Booda';

  @override
  String get updateAction => 'Haaromsi';

  @override
  String updateAvailableMessage(String version) {
    return 'Version $version ni argama.';
  }

  @override
  String updateRequiredMessage(String version) {
    return 'Version haaraa ($version) itti fufuuf barbaachisa.';
  }

  @override
  String get updateLinkUnavailable => 'Geessituu haaromsaa hin argamu.';

  @override
  String get guestPromptTitle => 'Kaartelaa kana galmeessuuf herrega uumi';

  @override
  String get guestPromptMessage =>
      'Lakkoofsa kaartelaa filachuuf fi taphaatti makamuuf galmaa\'i ykn seeni.';

  @override
  String get guestPromoModeLabel => 'Haala keessummaa';

  @override
  String get guestPromoTitle =>
      'Lakkoofsa kallattii ilaali, raawundii itti aanu keessatti hirmaadhu';

  @override
  String get guestPromoMessage =>
      'Lakkoofsi yeroo dhugaa keessatti akkuma bu\'u ilaali; achiis tapha tarree itti aanu dura kaartelaa qabachuuf seeni yookaan herrega uumi.';

  @override
  String get guestPromoFooter =>
      'Galmee saffisaa. Carraa raawundii itti aanu. Humna bingo kallattii.';

  @override
  String get guestPromoRowLabel => 'Sarara tarree';

  @override
  String get guestPromoRowHelper => 'Dura tarreen guutuun ni cufa.';

  @override
  String get guestPromoColumnLabel => 'Sarara tarjaa';

  @override
  String get guestPromoColumnHelper => 'Achiin booda tarjaan guutuun ni cufa.';

  @override
  String get guestPromoDiagonalLabel => 'Bingo qaxxaamuraa';

  @override
  String get guestPromoDiagonalHelper =>
      'Dhuma irratti qaxxaamurri bingo ni guuta.';

  @override
  String get guestPromoWinnerLabel => 'Mo\'ataa';

  @override
  String get guestPromoCongratsTitle => 'Baga gammaddan!';

  @override
  String guestPromoCongratsAmountWon(String amount) {
    return '$amount mo\'atteetta';
  }

  @override
  String guestPromoCongratsReceived(String amount) {
    return '$amount karaa Baankii CBE siif galeera.';
  }

  @override
  String get guestPromoCongratsWithdraw => 'Baasuuf seeni yookaan galmaa\'i.';

  @override
  String get drawerTheme => 'Dhangii';

  @override
  String get drawerThemeLight => 'Ifaa';

  @override
  String get drawerThemeDark => 'Gurraacha';

  @override
  String get drawerThemeAuto => 'Ofumaan';

  @override
  String get drawerLogout => 'Ba\'i';

  @override
  String get drawerJoinGame => 'Taphaatti makami';

  @override
  String get drawerCreateAccount =>
      'Kaartelaa galmeessuuf fi boorsa kee too\'achuuf herrega uumi.';

  @override
  String get gameStats => 'Istaatistiksii taphaa';

  @override
  String get gameStatsHide => 'Istaatistiksii dhoksi';

  @override
  String get gameStatsShow => 'Istaatistiksii agarsiisi';

  @override
  String get gameInfoEntry => 'Seensa';

  @override
  String get gameInfoPrize => 'Badhaasa';

  @override
  String get gameInfoReg => 'Galmeessa';

  @override
  String get gameInfoCalled => 'Waamame';

  @override
  String get gameInfoGame => 'Tapha';

  @override
  String get statusOnline => 'Toora irratti';

  @override
  String get statusReconnecting => 'Irra deebi\'aa wal qunnamsiisaa jira';

  @override
  String get statusOffline => 'Toora irraa adda';

  @override
  String get gameHintGuest => 'Kaartelaa galmeessuuf galmaa\'i';

  @override
  String get gameHintSelectMode =>
      'Filachuuf lakkoofsa tuqi · Qophaa\'ee yoo ta\'e ilaali';

  @override
  String get gameHintSingleMode => 'Ilaaluuf tuqi · Baay\'ee filachuuf qabi';

  @override
  String get gameClear => 'Haqi';

  @override
  String gameReview(int count) {
    return 'Ilaali ($count)';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return 'Sekondii $seconds hafe';
  }

  @override
  String gameUpTo(int max) {
    return 'Hamma $max';
  }

  @override
  String get gameBalanceLeft => 'hafe';

  @override
  String get gameSyncing => 'Tapha kallattii wal simsiisaa jira…';

  @override
  String get gameSyncingMessage =>
      'Raawundii kallattii sarvar irraa haaromfamaa jira.';

  @override
  String get gameWinnerWindowOpen => 'Foddaa mo\'ataa banaa dha';

  @override
  String get gameWinnerWindowMessage =>
      'Taphattoonni biroo foddaa mo\'ataa keessatti ammallee gaafachuu danda\'u.';

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
  String get gameResultsLoading => 'Bu\'aa raawundii fe\'amaa jira…';

  @override
  String get sessionResultsNoWinners =>
      'Raawundii kana keessatti mo\'ataan hin jiru.';

  @override
  String get gameAllNumbersCalled => 'All numbers were called.';

  @override
  String get gameNoWinnerNextRoundShortly => 'Next game will open shortly.';

  @override
  String get calledNumbersCheckingCartela => 'Kaartelaa mirkanaa\'aa jira';

  @override
  String get calledNumbersWinnerCartela => 'Kaartelaa mo\'ate';

  @override
  String get calledNumbersBlockedCartela => 'Kaartelaa cufame';

  @override
  String get gameYouWon => 'Mo\'atte!';

  @override
  String get gameNextRegistration =>
      'Galmeessi itti aanu yeroo dhiyoo ni bana.';

  @override
  String gameWonAmount(String amount) {
    return 'Baga gammaddan! Badhaasa $amount ETB argatte.';
  }

  @override
  String get gameWonPending =>
      'Baga gammaddan! Kaartelaa kee mo\'ate. Badhaasni haaromfamaa jira.';

  @override
  String get gameFinished => 'Taphni Xumurame';

  @override
  String get gameFinishedMessage =>
      'Taphni kun xumurame. Tapha itti aanu carraa gaarii! Galmeessi itti aanu yeroo dhiyoo ni bana.';

  @override
  String postGameSummaryNextRoundIn(int seconds) {
    return 'Sekondii $seconds keessatti itti fufi';
  }

  @override
  String get postGameSummaryTapToViewWinner =>
      'Kaartelaa mo\'ate ilaaluuf tuqi';

  @override
  String get postGameSummaryNextGame => 'Itti fufi';

  @override
  String get postGameSummaryOpeningNextRound => 'Opening next round…';

  @override
  String finishedGamePrizeLine(String amount) {
    return 'Tapha kanaaf badhaasni $amount dha';
  }

  @override
  String get reviewModeWinnerTitle => 'Mo\'ataa';

  @override
  String reviewModeWinnerCartela(int number) {
    return 'Kaartelaa #$number';
  }

  @override
  String reviewModeAdditionalWinners(int count) {
    return 'Mo\'ataa dabalataa +$count';
  }

  @override
  String get gameNoPlayers => 'Taphataan Hin Hirmaanne';

  @override
  String get gameNoPlayersMessage =>
      'Raawundii kana keessatti taphataan hin hirmaanne. Raawundii itti aanu jalqabaa jira…';

  @override
  String get gameCancelled => 'Taphni Haqame';

  @override
  String get gameCancelledMessage =>
      'Taphni kun haqame. Kaffaltiin seensaa deebifame. Raawundii itti aanu jalqabaa jira…';

  @override
  String get bulkConfirmHint =>
      'Ilaaluuf tuqi · Haquuf X · Qophaa\'ee yoo ta\'e galmeessi';

  @override
  String bulkRemoveCartela(int number) {
    return 'Kaartelaa #$number haqi';
  }

  @override
  String get bulkReviewEmpty =>
      'Galmeessuuf yoo xiqqaate kaartelaa tokko filadhu.';

  @override
  String bulkRegisterCount(int count) {
    return 'Galmeessi $count';
  }

  @override
  String get bulkRegisterError =>
      'Kaartelaa filataman galmeessuu hin dandeenye. Irra deebi\'ii yaali.';

  @override
  String get bulkRegisterFailed =>
      'Kaartelaa filataman galmeessuu hin dandeenye.';

  @override
  String bulkRegisterTaken(String numbers) {
    return 'Kaartelaa filataman galmeessuu hin dandeenye. $numbers dursee fudhatame.';
  }

  @override
  String depositHistoryRef(String ref) {
    return 'Wabii: $ref';
  }

  @override
  String get depositHistoryRetry => 'Mirkaneessaa irra deebi\'ii yaali';

  @override
  String depositHistoryRetriedStatus(String status) {
    return 'Mirkaneessaan irra deebi\'ame. Haala: $status.';
  }

  @override
  String get depositHistoryCouldNotRetry =>
      'Mirkaneessaa irra deebi\'ii yaaluu hin dandeenye.';

  @override
  String withdrawHistoryPhone(String phone) {
    return 'Bilbila: $phone';
  }

  @override
  String withdrawHistoryAccount(String account) {
    return 'Herrega: $account';
  }

  @override
  String withdrawHistoryNote(String note) {
    return 'Yaadannoo: $note';
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
