// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Friends Bingo';

  @override
  String get appBarHi => 'Hi, ';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAuto => 'Auto';

  @override
  String get theme => 'Theme';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginPhone => 'Phone number';

  @override
  String get loginPhoneHint => '091*******';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginCreateAccount => 'Create a new account';

  @override
  String get registerFullName => 'Full name';

  @override
  String get registerFullNameHint => 'Full Name';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerPasswordHint => 'Minimum 6 characters';

  @override
  String get registerConfirmPassword => 'Confirm password';

  @override
  String get registerConfirmPasswordHint => 'Re-enter your password';

  @override
  String get registerContinue => 'Continue';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your phone number to receive a verification code.';

  @override
  String get forgotPasswordSendCode => 'Send verification code';

  @override
  String get forgotPasswordBackToSignIn => 'Back to sign in';

  @override
  String get otpVerifyPhone => 'Verify your phone';

  @override
  String otpSentTo(String phone) {
    return 'Code sent to $phone.';
  }

  @override
  String get otpCreateAccount => 'Create account';

  @override
  String get otpResendCode => 'Resend code';

  @override
  String otpResendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String otpResendInMinutes(int minutes) {
    return 'Resend in $minutes min';
  }

  @override
  String otpResendInMinutesSeconds(int minutes, int seconds) {
    return 'Resend in ${minutes}m ${seconds}s';
  }

  @override
  String get otpBackToDetails => 'Back to details';

  @override
  String get otpEnterCode => 'Enter the 6-digit verification code.';

  @override
  String get otpSmsBanner =>
      'Enter the verification code sent to your phone by SMS.';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String resetPasswordSmsSentTo(String phone) {
    return 'Enter the SMS code sent to $phone.';
  }

  @override
  String get resetPasswordNewPassword => 'New password';

  @override
  String get resetPasswordConfirmNew => 'Confirm new password';

  @override
  String get resetPasswordConfirmNewHint => 'Re-enter your new password';

  @override
  String get resetPasswordUpdate => 'Update password';

  @override
  String get resetPasswordBackToPhone => 'Back to phone number';

  @override
  String get validatorPhoneRequired => 'Phone number is required.';

  @override
  String get validatorPhoneInvalid => 'Enter a valid phone number.';

  @override
  String get validatorPasswordLength =>
      'Password must be at least 6 characters.';

  @override
  String get validatorFullNameLength =>
      'Full name must be at least 3 characters.';

  @override
  String get validatorPasswordMismatch => 'Passwords do not match.';

  @override
  String get validatorAmountRequired => 'Amount is required.';

  @override
  String get validatorAmountInvalid => 'Enter a valid amount.';

  @override
  String get validatorAmountPositive => 'Amount must be greater than zero.';

  @override
  String get validatorTransactionRef => 'Enter a valid transaction reference.';

  @override
  String dashboardHello(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardSubtitle =>
      'Open the live game, register your cartelas there, and keep an eye on your wallet from one place.';

  @override
  String get dashboardOpenLiveGame => 'Open live game';

  @override
  String get dashboardRole => 'Role';

  @override
  String get dashboardStatus => 'Status';

  @override
  String get dashboardWalletSnapshot => 'Wallet snapshot';

  @override
  String dashboardAvailableBalance(String amount) {
    return 'Available balance: $amount ETB';
  }

  @override
  String dashboardLockedBalance(String amount) {
    return 'Locked balance: $amount ETB';
  }

  @override
  String get dashboardOpenWallet => 'Open wallet';

  @override
  String get dashboardWalletLoading => 'Loading wallet...';

  @override
  String get dashboardWalletUnavailable => 'Wallet unavailable right now.';

  @override
  String get dashboardWhatIsNext => 'What is next';

  @override
  String get dashboardWhatIsNextBody =>
      'Next steps can plug live called numbers, bingo claims, deposits, and withdrawals into this same foundation.';

  @override
  String get walletAvailableBalance => 'Available balance';

  @override
  String get walletLockedBalance => 'Locked balance';

  @override
  String get walletFreezBalance => 'Freez balance';

  @override
  String get walletTotalBalance => 'Total wallet';

  @override
  String get walletTotalEqualsHint => 'Available + Locked = Total wallet';

  @override
  String get walletDeposit => 'Deposit';

  @override
  String get walletWithdraw => 'Withdraw';

  @override
  String get walletTransactionHistory => 'Transaction history';

  @override
  String get walletTransactionHistorySubtitle =>
      'Review every wallet ledger movement.';

  @override
  String get walletDepositHistory => 'Deposit history';

  @override
  String get walletDepositHistorySubtitle =>
      'Track verification progress and retry when needed.';

  @override
  String get walletWithdrawalHistory => 'Withdrawal history';

  @override
  String get walletWithdrawalHistorySubtitle =>
      'Follow request, approval, and payout statuses.';

  @override
  String get walletCouldNotLoad => 'Could not load wallet details.';

  @override
  String get walletTryAgain => 'Try again';

  @override
  String get depositScreenTitle => 'Deposit';

  @override
  String get depositAmount => 'Amount';

  @override
  String get depositFtNumber => 'FT number';

  @override
  String get depositReceiptId => 'Receipt ID';

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
  String get depositDevHelper => 'Development / test helper';

  @override
  String depositDevReference(String ref) {
    return 'Development test reference: $ref';
  }

  @override
  String get depositUseTestRef => 'Use test reference';

  @override
  String get depositSubmit => 'Submit deposit';

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
  String get depositLatest => 'Latest deposit';

  @override
  String depositSubmittedStatus(String status) {
    return 'Deposit submitted. Status: $status.';
  }

  @override
  String get depositCouldNotSubmit => 'Could not submit deposit.';

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
    return 'Provider: $provider';
  }

  @override
  String depositAmountLabel(String amount) {
    return 'Amount: $amount';
  }

  @override
  String depositReference(String ref) {
    return 'Reference: $ref';
  }

  @override
  String depositCreated(String date) {
    return 'Created: $date';
  }

  @override
  String depositRejectionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get depositHistoryTitle => 'Deposit history';

  @override
  String get depositHistoryEmpty => 'No deposits yet';

  @override
  String get depositHistoryEmptyMessage =>
      'Your deposit requests will appear here.';

  @override
  String get depositHistoryCouldNotLoad => 'Could not load deposit history.';

  @override
  String get depositRetryVerification => 'Retry verification';

  @override
  String depositRetried(String status) {
    return 'Verification retried. Status: $status.';
  }

  @override
  String get depositRetryFailed => 'Could not retry verification.';

  @override
  String depositAmountRow(String amount) {
    return 'Amount: $amount';
  }

  @override
  String depositRefRow(String ref) {
    return 'Ref: $ref';
  }

  @override
  String depositCreatedRow(String date) {
    return 'Created: $date';
  }

  @override
  String depositReasonRow(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get withdrawScreenTitle => 'Withdraw';

  @override
  String get withdrawAmount => 'Amount';

  @override
  String get withdrawSubmit => 'Submit withdrawal';

  @override
  String get withdrawLatest => 'Latest withdrawal';

  @override
  String withdrawSubmittedStatus(String status) {
    return 'Withdrawal submitted. Status: $status.';
  }

  @override
  String get withdrawCouldNotSubmit => 'Could not submit withdrawal.';

  @override
  String withdrawStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String withdrawProviderLabel(String provider) {
    return 'Provider: $provider';
  }

  @override
  String withdrawAmountLabel(String amount) {
    return 'Amount: $amount';
  }

  @override
  String withdrawPhoneLabel(String phone) {
    return 'Phone: $phone';
  }

  @override
  String withdrawAccountLabel(String account) {
    return 'Account: $account';
  }

  @override
  String withdrawCreatedLabel(String date) {
    return 'Created: $date';
  }

  @override
  String withdrawNoteLabel(String note) {
    return 'Note: $note';
  }

  @override
  String get withdrawHistoryTitle => 'Withdrawal history';

  @override
  String get withdrawHistoryEmpty => 'No withdrawals yet';

  @override
  String get withdrawHistoryEmptyMessage =>
      'Your withdrawal requests will appear here.';

  @override
  String get withdrawHistoryCouldNotLoad =>
      'Could not load withdrawal history.';

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
  String get txHistoryTitle => 'Wallet transactions';

  @override
  String get txHistoryEmpty => 'No transactions yet';

  @override
  String get txHistoryEmptyMessage =>
      'Your wallet ledger will show up here after deposits, entries, and withdrawals.';

  @override
  String txHistoryShowing(int count, int total) {
    return 'Showing $count of $total transactions';
  }

  @override
  String get txHistoryWalletActivity => 'Wallet activity';

  @override
  String get txWithdrawRequestLockedNote =>
      'Moved to locked balance pending approval.';

  @override
  String txHistoryBalanceAfter(String amount) {
    return 'Bal: $amount';
  }

  @override
  String get txHistoryCouldNotLoad => 'Could not load transaction history.';

  @override
  String get gameHistoryTitle => 'Game history';

  @override
  String get gameHistoryEmpty => 'No finished games yet.';

  @override
  String gameHistoryCards(int count) {
    return '$count cards';
  }

  @override
  String get gameHistoryLoadingAttended => 'Loading your games...';

  @override
  String get gameHistoryEmptyAttended => 'No finished games you joined yet.';

  @override
  String get gameHistoryDetailTitle => 'Game details';

  @override
  String get gameHistoryPrizePool => 'Prize pool';

  @override
  String gameHistoryYourWinnings(String amount) {
    return 'You won $amount';
  }

  @override
  String get gameHistoryYourCartelas => 'Your cartelas';

  @override
  String get gameHistorySessionWinners => 'Session winners';

  @override
  String gameHistoryMyCartelaCount(int count) {
    return '$count of yours';
  }

  @override
  String get gameHistoryLoadMore => 'Load more';

  @override
  String get gameHistoryRetry => 'Try again';

  @override
  String get gameStatsLabel => 'Game stats';

  @override
  String get gameHideStats => 'Hide game stats';

  @override
  String get gameShowStats => 'Show game stats';

  @override
  String get gameEntryLabel => 'Entry';

  @override
  String get gamePrizeLabel => 'Prize';

  @override
  String get gameRegLabel => 'Reg';

  @override
  String get gameCalledLabel => 'Called';

  @override
  String get gameNowPlaying => 'NOW PLAYING';

  @override
  String get gameNextGame => 'Next game';

  @override
  String get liveCalledNumbersLabel => 'Called numbers';

  @override
  String get liveNextRoundSectionTitle => 'Next round';

  @override
  String get liveJoinCurrentRoundSectionTitle => 'Join current round';

  @override
  String get liveMissedCurrentRoundTitle => 'Current round in play';

  @override
  String get liveNextQueuedPlayLabel => 'Next queued play';

  @override
  String get liveRegisteredCartelasLabel => 'Registered cartelas';

  @override
  String get liveRegisteredCartelasEmpty => 'None yet — pick numbers below.';

  @override
  String get liveMissedRoundHelper =>
      'You missed the current game. Register for the next round.';

  @override
  String get liveMissedRoundYouMissedGame => 'You missed this round.';

  @override
  String get liveMissedRoundOverviewTitle => 'Live & next round';

  @override
  String liveMissedRoundCollapsedMissed(String gameName) {
    return 'Missed · $gameName';
  }

  @override
  String liveMissedRoundCollapsedNextReady(String gameName) {
    return 'Next ready · $gameName · register now';
  }

  @override
  String get liveMissedRoundRegisterBridge =>
      'Register cartelas now for the next game and play next round.';

  @override
  String liveJoinCurrentRoundGameLive(String gameName) {
    return '$gameName is live now';
  }

  @override
  String get liveNextGameBannerTitle => 'NEXT GAME';

  @override
  String get liveMissedRoundBannerSubtitle => 'Soon starts the next game';

  @override
  String get liveNextGameLabel => 'Next game';

  @override
  String get registrationStartsAfterCurrentGame =>
      'Registration open - starts after current game';

  @override
  String get liveJoinCurrentRoundHelper =>
      'Registration is still open for this live round. Taken and reserved cartelas are locked automatically.';

  @override
  String get liveAddMoreCartelasHelper =>
      'Registration is still open. You can add more cartelas while the round is active.';

  @override
  String get liveAddMoreCartelasTitle => 'Add more cartelas';

  @override
  String get liveNextRoundRegistrationTitle => 'Next round registration';

  @override
  String get gameRuleDetailTitle => 'Game rule';

  @override
  String get gameRulePatternSample => 'Sample winning pattern';

  @override
  String get gameNextGameHide => 'Hide next game';

  @override
  String get gameNextGameShow => 'Show next game';

  @override
  String get leaveLiveGameTitle => 'Leave live game?';

  @override
  String get leaveLiveGameMessage =>
      'Your game will continue on the server. Your marked cells will be saved on this device.';

  @override
  String get leaveLiveGameStay => 'Stay';

  @override
  String get leaveLiveGameLeave => 'Leave';

  @override
  String get confirmBackTitle => 'Go back?';

  @override
  String get confirmBackMessage => 'Do you want to leave this page?';

  @override
  String get confirmBackStay => 'Stay';

  @override
  String get confirmBackLeave => 'Leave';

  @override
  String get exitAppTitle => 'Exit app?';

  @override
  String get exitAppMessage =>
      'Your game will continue. You can return anytime.';

  @override
  String get exitAppStay => 'Stay';

  @override
  String get exitAppExit => 'Exit';

  @override
  String get winningCartelasTitle => 'Winning cartelas';

  @override
  String get winningCartelasTapHint =>
      'Tap a cartela to view the full winning pattern.';

  @override
  String get winningCartelasYou => 'You';

  @override
  String get winningCartelasPlayer => 'Player';

  @override
  String winningCartelasPrize(String amount) {
    return 'Prize: $amount ETB';
  }

  @override
  String winningCartelasDetailTitle(int number) {
    return 'Winning cartela #$number';
  }

  @override
  String get winningCartelasSwipeHint =>
      'Swipe or tap a number to see each winner';

  @override
  String winningCartelasWinningBall(String ball) {
    return 'Winning ball: $ball';
  }

  @override
  String get winningCartelasAllWinners => 'Winners';

  @override
  String get winningCartelasPreviousWinner => 'Previous winner';

  @override
  String get winningCartelasNextWinner => 'Next winner';

  @override
  String get cartelaOutcomeValid => 'Valid';

  @override
  String get cartelaOutcomeInvalid => 'Invalid';

  @override
  String get cartelaOutcomeRegistered => 'Registered';

  @override
  String get cartelaOutcomeNoWin => 'No win';

  @override
  String get cartelaBlockedInfoTooltip => 'Why is this cartela blocked?';

  @override
  String cartelaBlockedDialogTitle(int number) {
    return 'Cartela #$number blocked';
  }

  @override
  String get cartelaBlockedDialogOk => 'Got it';

  @override
  String get cartelaBlockedReasonLate =>
      'You missed the winning call. This cartela has been blocked.';

  @override
  String get cartelaBlockedReasonPattern =>
      'Your claim did not match the game rule.';

  @override
  String get cartelaBlockedReasonGeneric => 'This cartela has been blocked.';

  @override
  String get gameLabel => 'Game';

  @override
  String get connectionOnline => 'Online';

  @override
  String get connectionReconnecting => 'Reconnecting';

  @override
  String get connectionOffline => 'Offline';

  @override
  String get registrationTapHintGuest => 'Sign up to register cartelas';

  @override
  String get registrationTapHintSelect =>
      'Tap numbers to select · Review when ready';

  @override
  String get registrationTapHintDefault =>
      'Tap a number to preview and register';

  @override
  String get registrationClear => 'Clear';

  @override
  String registrationReview(int count) {
    return 'Review ($count)';
  }

  @override
  String registrationSecondsLeft(int seconds) {
    return '${seconds}s left';
  }

  @override
  String registrationUpTo(int max) {
    return 'Up to $max';
  }

  @override
  String get registrationLeft => ' left';

  @override
  String get registrationOpenBanner => 'REGISTRATION OPEN';

  @override
  String get registrationOpenLabel => 'Registration open';

  @override
  String registrationClosesIn(int seconds) {
    return 'Registration closes in ${seconds}s';
  }

  @override
  String registrationClosesInDuration(String duration) {
    return 'Registration closes in $duration';
  }

  @override
  String get registrationClosedPreparing => 'Starting...';

  @override
  String get preparingGameNoCartelas =>
      'Cartela registration is closed. The live round will begin shortly.';

  @override
  String preparingGameCartelasRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartelas registered. The live round will begin shortly.',
      one: '1 cartela registered. The live round will begin shortly.',
    );
    return '$_temp0';
  }

  @override
  String get liveNoGameTitle => 'No games in queue';

  @override
  String get liveNoGameMessage =>
      'No game is open right now. Pull down to refresh when the next round starts.';

  @override
  String get gameCheckingTitle => 'Checking bingo claim';

  @override
  String get gameCheckingMessage =>
      'A bingo claim is being checked. Hold on — do not mark new numbers yet.';

  @override
  String calledNumbersDrawnCount(int count) {
    return 'Drawn: $count';
  }

  @override
  String calledNumbersBallOrder(int order) {
    return '#$order';
  }

  @override
  String get calledNumbersSyncLive => 'Live';

  @override
  String get calledNumbersSyncCatchingUp => 'Catching up…';

  @override
  String get calledNumbersSyncHelp =>
      'Called numbers are synced from the server. A short delay on slow networks is normal.';

  @override
  String get calledNumbersSyncHelpTitle => 'Called numbers sync';

  @override
  String get calledNumbersSyncReconnecting => 'Reconnecting…';

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
    return 'Next ball · ${seconds}s';
  }

  @override
  String get calledNumbersNextBallLabel => 'Next ball';

  @override
  String get calledNumbersFirstBallLabel => 'First ball';

  @override
  String calledNumbersWaitingFirstBallIn(int seconds) {
    return 'Waiting for first ball · ${seconds}s';
  }

  @override
  String get calledNumbersCallingNext => 'Calling…';

  @override
  String get calledNumbersSyncingNextBall => 'Syncing next ball…';

  @override
  String calledNumbersDrawLabel(int order) {
    return 'Draw #$order';
  }

  @override
  String get calledNumbersSyncingMissed => 'Syncing missed numbers…';

  @override
  String get calledNumbersWaitingNextBall => 'Waiting for next ball…';

  @override
  String get calledNumbersAllBallsDrawn => 'All balls drawn';

  @override
  String get calledNumbersWillAppear => 'Numbers will appear here';

  @override
  String get calledNumbersCheckingBingo => 'Checking bingo…';

  @override
  String get calledNumbersClaimHoldNote =>
      'New numbers will appear after your claim is processed.';

  @override
  String get registrationSignUpToPlay => 'Sign up to play';

  @override
  String get bulkReviewTitle => 'Review your cartelas';

  @override
  String get bulkRegisteringTitle => 'Registering cartelas';

  @override
  String bulkCartelasTotal(int count, String total) {
    return '$count cartelas · $total total';
  }

  @override
  String bulkPerCartela(String fee) {
    return '$fee per cartela';
  }

  @override
  String get bulkConfirmNumbers =>
      'Confirm the numbers above, then register them together.';

  @override
  String get bulkStarting => 'Starting registration...';

  @override
  String bulkProgress(int completed, int total) {
    return 'Registering $completed of $total cartelas...';
  }

  @override
  String get bulkCancel => 'Cancel';

  @override
  String bulkRegister(int count) {
    return 'Register $count';
  }

  @override
  String get bulkRegistering => 'Registering...';

  @override
  String get bulkCouldNotRegister =>
      'Could not register selected cartelas. Please try again.';

  @override
  String bulkTakenNumbers(String numbers) {
    return 'Could not register selected cartelas. $numbers already taken.';
  }

  @override
  String get winnerBannerSyncingTitle => 'Syncing live game…';

  @override
  String get winnerBannerSyncingMessage =>
      'Updating the live round from the server.';

  @override
  String get winnerBannerWindowOpenTitle => 'Winner window open';

  @override
  String get winnerBannerWindowOpenMessage =>
      'Other players can still claim during the winner window.';

  @override
  String get winnerBannerYouWonTitle => 'You Won!';

  @override
  String winnerBannerWonWithPayout(String amount) {
    return 'Congratulations! You won $amount ETB. Next registration opens shortly.';
  }

  @override
  String get winnerBannerWonNoPayout =>
      'Congratulations! Your cartela won. Prize is being updated. Next registration opens shortly.';

  @override
  String get winnerBannerFinishedTitle => 'Game Finished';

  @override
  String get winnerBannerFinishedMessage =>
      'This game is finished. Better luck next time! Next registration opens shortly.';

  @override
  String get winnerBannerNoPlayersTitle => 'No Players Joined';

  @override
  String get winnerBannerNoPlayersMessage =>
      'No players joined this round. Next round starting…';

  @override
  String get winnerBannerCancelledTitle => 'Game Cancelled';

  @override
  String get winnerBannerCancelledMessage =>
      'This game was cancelled. Entry fees were refunded. Next round starting…';

  @override
  String get drawerSignInToPlay => 'Sign in to play and register cartelas';

  @override
  String get drawerBalance => 'Balance';

  @override
  String get drawerJoinTheGame => 'Join the game';

  @override
  String get drawerJoinTheGameBody =>
      'Create an account to register cartelas and manage your wallet.';

  @override
  String get drawerLiveGame => 'Live Game';

  @override
  String get drawerWallet => 'Wallet';

  @override
  String get drawerProfile => 'Profile';

  @override
  String get drawerHistory => 'History';

  @override
  String get drawerTransactionHistory => 'Transaction history';

  @override
  String get drawerGameHistory => 'Game history';

  @override
  String get drawerAppVersion => 'App version';

  @override
  String get drawerAppVersionUpToDate => 'Up to date';

  @override
  String get drawerAppVersionUpdateAvailable => 'Update available';

  @override
  String get drawerAppVersionUpdateRequired => 'Update required';

  @override
  String get drawerAppVersionChecking => 'Checking for updates…';

  @override
  String drawerAppVersionCurrent(String version) {
    return 'Installed: $version';
  }

  @override
  String get noUpdateAvailableTitle => 'No updates';

  @override
  String get noUpdateAvailableBody =>
      'You already have the latest version installed.';

  @override
  String get noUpdateAvailableOk => 'OK';

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
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateLater => 'Later';

  @override
  String get updateAction => 'Update';

  @override
  String updateAvailableMessage(String version) {
    return 'Version $version is available.';
  }

  @override
  String updateRequiredMessage(String version) {
    return 'A newer version ($version) is required to continue.';
  }

  @override
  String get updateLinkUnavailable => 'Update link is unavailable.';

  @override
  String get guestPromptTitle => 'Create an account to register this cartela';

  @override
  String get guestPromptMessage =>
      'Sign up or sign in to pick cartela numbers and join the game.';

  @override
  String get guestPromoModeLabel => 'Guest mode';

  @override
  String get guestPromoTitle => 'Catch the live draw, join the next round';

  @override
  String get guestPromoMessage =>
      'Watch numbers land in real time, then sign in or create your account to lock cartelas before the next queued play starts.';

  @override
  String get guestPromoFooter =>
      'Fast signup. Next-round access. Live bingo energy.';

  @override
  String get guestPromoRowLabel => 'Row line';

  @override
  String get guestPromoRowHelper => 'A full row closes first.';

  @override
  String get guestPromoColumnLabel => 'Column line';

  @override
  String get guestPromoColumnHelper => 'Then a full column lands cleanly.';

  @override
  String get guestPromoDiagonalLabel => 'Diagonal bingo';

  @override
  String get guestPromoDiagonalHelper =>
      'Finally the diagonal completes bingo.';

  @override
  String get guestPromoWinnerLabel => 'Winner';

  @override
  String get guestPromoCongratsTitle => 'Congratulations!';

  @override
  String guestPromoCongratsAmountWon(String amount) {
    return '$amount won';
  }

  @override
  String guestPromoCongratsReceived(String amount) {
    return 'You received $amount by CBE Bank.';
  }

  @override
  String get guestPromoCongratsWithdraw => 'Sign in or sign up to withdraw.';

  @override
  String get drawerTheme => 'Theme';

  @override
  String get drawerThemeLight => 'Light';

  @override
  String get drawerThemeDark => 'Dark';

  @override
  String get drawerThemeAuto => 'Auto';

  @override
  String get drawerLogout => 'Logout';

  @override
  String get drawerJoinGame => 'Join the game';

  @override
  String get drawerCreateAccount =>
      'Create an account to register cartelas and manage your wallet.';

  @override
  String get gameStats => 'Game stats';

  @override
  String get gameStatsHide => 'Hide game stats';

  @override
  String get gameStatsShow => 'Show game stats';

  @override
  String get gameInfoEntry => 'Entry';

  @override
  String get gameInfoPrize => 'Prize';

  @override
  String get gameInfoReg => 'Reg';

  @override
  String get gameInfoCalled => 'Called';

  @override
  String get gameInfoGame => 'Game';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusReconnecting => 'Reconnecting';

  @override
  String get statusOffline => 'Offline';

  @override
  String get gameHintGuest => 'Sign up to register cartelas';

  @override
  String get gameHintSelectMode => 'Tap numbers to select · Review when ready';

  @override
  String get gameHintSingleMode => 'Tap to preview · Hold to select multiple';

  @override
  String get gameClear => 'Clear';

  @override
  String gameReview(int count) {
    return 'Review ($count)';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '${seconds}s left';
  }

  @override
  String gameUpTo(int max) {
    return 'Up to $max';
  }

  @override
  String get gameBalanceLeft => 'left';

  @override
  String get gameSyncing => 'Syncing live game…';

  @override
  String get gameSyncingMessage => 'Updating the live round from the server.';

  @override
  String get gameWinnerWindowOpen => 'Winner window open';

  @override
  String get gameWinnerWindowMessage =>
      'Other players can still claim during the winner window.';

  @override
  String get gameWinnerWindowClosingTitle => 'Winner window closed';

  @override
  String get gameWinnerWindowClosingMessage =>
      'Finalizing results — the round summary will appear shortly.';

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
  String get gameYouWon => 'You Won!';

  @override
  String get gameNextRegistration => 'Next registration opens shortly.';

  @override
  String gameWonAmount(String amount) {
    return 'Congratulations! You won $amount ETB.';
  }

  @override
  String get gameWonPending =>
      'Congratulations! Your cartela won. Prize is being updated.';

  @override
  String get gameFinished => 'Game Finished';

  @override
  String get gameFinishedMessage =>
      'This game is finished. Better luck next time! Next registration opens shortly.';

  @override
  String postGameSummaryNextRoundIn(int seconds) {
    return 'Continue in ${seconds}s';
  }

  @override
  String get postGameSummaryTapToViewWinner => 'Tap to view winning cartela';

  @override
  String get postGameSummaryNextGame => 'Continue';

  @override
  String get postGameSummaryOpeningNextRound => 'Opening next round…';

  @override
  String finishedGamePrizeLine(String amount) {
    return 'For this game the prize is $amount';
  }

  @override
  String get reviewModeWinnerTitle => 'Winner';

  @override
  String reviewModeWinnerCartela(int number) {
    return 'Cartela #$number';
  }

  @override
  String reviewModeAdditionalWinners(int count) {
    return '+$count more winner(s)';
  }

  @override
  String get gameNoPlayers => 'No Players Joined';

  @override
  String get gameNoPlayersMessage =>
      'No players joined this round. Next round starting…';

  @override
  String get gameCancelled => 'Game Cancelled';

  @override
  String get gameCancelledMessage =>
      'This game was cancelled. Entry fees were refunded. Next round starting…';

  @override
  String get bulkConfirmHint =>
      'Tap to preview · X to remove · Register when ready';

  @override
  String bulkRemoveCartela(int number) {
    return 'Remove cartela #$number';
  }

  @override
  String get bulkReviewEmpty => 'Select at least one cartela to register.';

  @override
  String bulkRegisterCount(int count) {
    return 'Register $count';
  }

  @override
  String get bulkRegisterError =>
      'Could not register selected cartelas. Please try again.';

  @override
  String get bulkRegisterFailed => 'Could not register selected cartelas.';

  @override
  String bulkRegisterTaken(String numbers) {
    return 'Could not register selected cartelas. $numbers already taken.';
  }

  @override
  String depositHistoryRef(String ref) {
    return 'Ref: $ref';
  }

  @override
  String get depositHistoryRetry => 'Retry verification';

  @override
  String depositHistoryRetriedStatus(String status) {
    return 'Verification retried. Status: $status.';
  }

  @override
  String get depositHistoryCouldNotRetry => 'Could not retry verification.';

  @override
  String withdrawHistoryPhone(String phone) {
    return 'Phone: $phone';
  }

  @override
  String withdrawHistoryAccount(String account) {
    return 'Account: $account';
  }

  @override
  String withdrawHistoryNote(String note) {
    return 'Note: $note';
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
