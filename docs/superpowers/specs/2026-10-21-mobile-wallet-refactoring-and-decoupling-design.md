# Mobile Wallet Architecture Refactoring and Decoupling Design

**Date**: 2026-10-21  
**Project**: Friends Bingo Mobile (`friends-bingo-mobile`)  
**Scope**: Wallet Feature Refactoring (`withdraw_screen.dart` and `deposit_screen.dart`)  
**Pattern**: Feature-First Clean Architecture with Hybrid Riverpod Notifiers & Local Form Controllers  

---

## 1. Executive Summary & Goals

### 1.1 Problems in Current Implementation
1. **Monolithic Screens**:
   - `deposit_screen.dart`: ~1,585 lines handling SMS parsing, receipt OCR URL extraction, payment provider selection, real-time socket events, cooldown timers, verification retries, and history presentation.
   - `withdraw_screen.dart`: ~757 lines handling local storage persistence, phone number parsing, validation rules, password dialog triggers, and withdrawal history presentation.
2. **State & UI Coupling**: Business rules (cooldown timers, socket-driven status transitions, auto-persistence) are directly coupled to `_DepositScreenState` and `_WithdrawScreenState`, making headless unit testing impossible without pumping entire widget trees.
3. **Screen Size Constraints**: User requirement mandates that no single file exceed 600 lines, with modular, decoupled, and reusable widgets.

### 1.2 Architectural Targets
1. **Strict File Size Cap**: Every screen file must remain under 250 lines; extracted widgets remain under 250 lines.
2. **Clean Separation of Concerns**:
   - **Business Logic & Shared State**: Managed by testable Riverpod Notifiers (`WithdrawController`, `DepositController`).
   - **Form State**: Ephemeral UI controllers (`TextEditingController`, `FocusNode`) remain local to dedicated form components and are safely disposed.
   - **Presentation**: Modular, reusable widgets with single responsibilities.
3. **Zero Behavior Regression**: Preserve 100% of existing functionality including CBE manual URL handling, Telebirr smart message parsing, real-time socket reconciliation, and idempotency guarantees.

---

## 2. Target Directory & File Structure

```
lib/src/features/wallet/
├── data/
│   ├── models/
│   │   ├── deposit_model.dart
│   │   ├── withdrawal_model.dart
│   │   └── payment_provider.dart
│   └── wallet_repository.dart
├── domain/
│   └── wallet_amount_limits.dart
├── presentation/
│   ├── controllers/
│   │   ├── withdraw_controller.dart          // Riverpod Notifier for withdrawal flows
│   │   └── deposit_controller.dart           // Riverpod Notifier for deposit flows
│   ├── models/
│   │   ├── withdraw_state.dart               // Immutable state for withdrawal
│   │   ├── deposit_state.dart                // Immutable state for deposit
│   │   ├── withdrawal_confirmation_state.dart
│   │   └── deposit_confirmation_state.dart
│   ├── widgets/
│   │   ├── withdraw_balance_strip.dart       // Existing reusable balance header
│   │   ├── withdraw_provider_chips.dart      // Existing provider selection chips
│   │   ├── withdraw_form_section.dart        // Amount + Receiver fields, validation, submit button
│   │   ├── withdrawal_confirmation_banner.dart// Real-time status banner (approved/rejected/pending)
│   │   ├── withdrawal_requests_table.dart    // History table with status filters
│   │   ├── deposit_guide_steps.dart          // Step-by-step visual deposit guide
│   │   ├── deposit_settlement_account_card.dart // Bank/Telebirr account details card
│   │   ├── deposit_smart_section.dart        // SMS/URL paste area, parsed chips, quick amounts
│   │   ├── deposit_manual_section.dart       // Manual amount and reference entry
│   │   └── deposit_status_card.dart          // Verification spinner, cooldown countdown, retry
│   └── screens/
│       ├── withdraw_screen.dart              // Clean screen scaffold (< 180 lines)
│       └── deposit_screen.dart               // Clean screen scaffold (< 220 lines)
```

---

## 3. State & Controller Architecture

### 3.1 Withdrawal Architecture

#### `WithdrawState`
```dart
@immutable
class WithdrawState {
  final PaymentProvider? provider;
  final bool isChoosingProvider;
  final bool isSubmitting;
  final WithdrawalConfirmationState? confirmation;
  final String? trackedWithdrawalId;
  final String savedCbeAccount;
  final String? ownPhoneNumber;

  const WithdrawState({
    this.provider,
    this.isChoosingProvider = true,
    this.isSubmitting = false,
    this.confirmation,
    this.trackedWithdrawalId,
    this.savedCbeAccount = '',
    this.ownPhoneNumber,
  });

  WithdrawState copyWith({
    PaymentProvider? provider,
    bool? isChoosingProvider,
    bool? isSubmitting,
    WithdrawalConfirmationState? confirmation,
    bool clearConfirmation = false,
    String? trackedWithdrawalId,
    bool clearTrackedId = false,
    String? savedCbeAccount,
    String? ownPhoneNumber,
  });
}
```

#### `WithdrawController`
- Extends `Notifier<WithdrawState>`.
- **Methods**:
  - `void selectProvider(PaymentProvider provider)`: Sets provider, leaves choosing mode, clears previous confirmation, and applies default account/phone.
  - `void changeProvider()`: Returns to choosing mode and resets fields.
  - `Future<void> loadSavedCbeAccount(String userId)`: Loads saved CBE account from `AppPreferencesStorage`.
  - `void schedulePersistCbeAccount(String account)`: Debounces writing CBE account to storage (400ms).
  - `void handleRealtimeUpdate(WalletEntityUpdate update)`: Automatically transitions confirmation to `approved` or `rejected` when websocket pushes an update.
  - `Future<bool> submitWithdrawal({ required String amount, required String receiver, required String password })`:
    - Calls `walletRepository.createWithdrawal(...)`.
    - Automatically invalidates `myWalletProvider`, `withdrawalHistoryProvider`, and `walletTransactionsProvider`.
    - Sets confirmation state to `pending` and tracks the created withdrawal ID.
    - Sets up auto-dismiss timer on approval (8s).

---

### 3.2 Deposit Architecture

#### `DepositState`
```dart
enum DepositEntryTab { smart, regular }

@immutable
class DepositState {
  final PaymentProvider? provider;
  final bool isChoosingProvider;
  final DepositEntryTab entryTab;
  final SmartDepositParseResult? smartParseResult;
  final bool isSubmitting;
  final bool checkInFlight;
  final int checkAgainCooldownSeconds;
  final DepositConfirmationState? confirmation;
  final String? trackedDepositId;
  final String? amountServerError;
  final String? transactionRefServerError;

  const DepositState({
    this.provider,
    this.isChoosingProvider = true,
    this.entryTab = DepositEntryTab.smart,
    this.smartParseResult,
    this.isSubmitting = false,
    this.checkInFlight = false,
    this.checkAgainCooldownSeconds = 0,
    this.confirmation,
    this.trackedDepositId,
    this.amountServerError,
    this.transactionRefServerError,
  });

  DepositState copyWith({ ... });
}
```

#### `DepositController`
- Extends `Notifier<DepositState>`.
- **Methods**:
  - `void selectProvider(PaymentProvider provider)`: Sets active provider, defaults to Smart tab if supported, and clears previous submission state.
  - `void switchTab(DepositEntryTab tab)`: Toggles between Smart and Regular entry tabs.
  - `void parseSmartMessage(String input)`: Executes `parseTelebirrSmartDepositInput` or `parseCbeSmartDepositInput`, extracting reference and amount into `smartParseResult`.
  - `Future<void> restorePendingAttempt()`: Queries `walletRepository.getPendingDepositVerification()` on screen initialization to recover in-flight verification attempts after app restarts.
  - `Future<void> submitDeposit({ required String amount, required String transactionRef, ... })`:
    - Single-pass idempotent call directly to `walletRepository.createDeposit(...)`.
    - Handles status transitions for `APPROVED`, `PENDING_VERIFICATION`, `UNDER_REVIEW`, and `ALREADY_USED`.
  - `Future<void> checkVerificationAgain()`: Enforces 10-second cooldown timer, performs status lookup, and updates confirmation state.
  - `void handleSocketWalletUpdate()`: Refreshes balance and dismisses pending cards when deposit is credited.

---

## 4. Component Decomposition Details

### 4.1 Withdraw Screen Decomposition
1. **`WithdrawScreen` (< 180 lines)**:
   - Sets up `ref.listen` on `walletEntityRealtimeProvider` for real-time push events.
   - Watches `myWalletProvider` and renders `WithdrawBalanceStrip`.
   - Renders `WithdrawProviderChips`.
   - Embeds `WithdrawFormSection` when a provider is selected.
   - Embeds `WithdrawalConfirmationBanner` when confirmation state exists.
   - Renders `WithdrawalRequestsTable` with recent transactions.
2. **`WithdrawFormSection` (< 220 lines)**:
   - Houses `_amountController` and `_receiverController`.
   - Validates amount against min/max limits and available balance.
   - Provides "Use mine" shortcut button for Telebirr.
   - Prompts for password via `showWithdrawConfirmDialog` or `showSecurityPasswordSheet`.
   - Dispatches `submitWithdrawal` to `WithdrawController`.

### 4.2 Deposit Screen Decomposition
1. **`DepositScreen` (< 220 lines)**:
   - High-level layout orchestrator with `SingleChildScrollView`.
   - Renders `DepositGuideSteps` and `DepositSettlementAccountCard`.
   - Renders `DepositProviderChips`.
   - Renders segmented tab controller (Smart vs Regular).
   - Renders `DepositSmartFormSection` or `DepositManualFormSection`.
   - Renders `DepositStatusCard`.
   - Renders transaction history list.
2. **`DepositSmartFormSection` (< 220 lines)**:
   - Multi-line text field for pasting SMS or CBE receipt URLs.
   - Real-time parse triggers with pill chips showing extracted amount and reference.
   - Quick-select amount buttons (e.g. 50, 100, 200, 500, 1000 ETB).
   - Single submit action triggering `DepositController.submitDeposit`.
3. **`DepositManualFormSection` (< 180 lines)**:
   - Amount text field with decimal limiters.
   - Reference text field (CBE receipt code or Telebirr transaction number).
   - Validation feedback.
4. **`DepositStatusCard` (< 140 lines)**:
   - Displays `DepositConfirmationBanner`.
   - If `verificationInProgress`, shows circular loader, "Check Again" button with countdown ticker, and "Change" link.

---

## 5. Verification & Testing Plan

1. **Unit Tests for Controllers**:
   - `test/features/wallet/withdraw_controller_test.dart`:
     - Test provider selection and auto-reset.
     - Test debounced CBE account saving.
     - Test withdrawal submission and wallet cache invalidation.
     - Test realtime entity update transitions (approved, rejected).
   - `test/features/wallet/deposit_controller_test.dart`:
     - Test smart message parsing for Telebirr and CBE.
     - Test single-pass idempotent submission without pre-flight checks.
     - Test check-again cooldown timer countdown.
     - Test pending verification restoration.
2. **Widget Tests**:
   - Verify `WithdrawScreen` renders form, balance, and provider chips correctly.
   - Verify `DepositScreen` switches between Smart and Manual tabs without losing context.
3. **Static Analysis & Line Count Verification**:
   - Run `flutter analyze lib test` (0 errors, 0 warnings).
   - Run line-count check verifying `withdraw_screen.dart` < 200 lines and `deposit_screen.dart` < 250 lines.
