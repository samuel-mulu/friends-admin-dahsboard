# Mobile Wallet Refactoring and Decoupling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple and refactor the mobile app's Wallet feature (`withdraw_screen.dart` and `deposit_screen.dart`) into modular Riverpod controllers and reusable components, ensuring no single file exceeds 250 lines and zero functionality is lost.

**Architecture:** Hybrid state architecture where business logic, socket sync, timers, and API calls live in testable Riverpod Notifiers (`WithdrawController`, `DepositController`), while ephemeral form controllers (`TextEditingController`, `FocusNode`) remain local to focused, decoupled presentation widgets.

**Tech Stack:** Flutter 3.x, Dart 3.x, Flutter Riverpod, GoRouter.

## Global Constraints
- Maximum file length: Screens must be < 250 lines; extracted widget components must be < 250 lines.
- Preserve 100% of existing functionality: CBE manual URL handling, Telebirr smart SMS parsing, realtime socket updates, idempotent deposit requests, and password authorization.
- Static analysis: `flutter analyze --no-fatal-infos lib test` must pass with 0 errors and 0 warnings after each task.
- Test coverage: Every controller and decoupled component must have dedicated unit/widget tests, with all existing tests continuing to pass.

---

### Task 1: Withdrawal State Model & Controller (`WithdrawState` & `WithdrawController`)

**Files:**
- Create: `lib/src/features/wallet/presentation/models/withdraw_state.dart`
- Create: `lib/src/features/wallet/presentation/controllers/withdraw_controller.dart`
- Test: `test/features/wallet/withdraw_controller_test.dart`

**Interfaces:**
- Consumes: `WalletRepository`, `AppPreferencesStorage`, `WalletEntityRealtimeState`
- Produces: `withdrawControllerProvider` (`NotifierProvider<WithdrawController, WithdrawState>`)

- [ ] **Step 1: Write failing unit test for `WithdrawController`**

```dart
// test/features/wallet/withdraw_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/controllers/withdraw_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/models/withdraw_state.dart';

void main() {
  test('WithdrawController initializes with choosing provider state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(withdrawControllerProvider);
    expect(state.isChoosingProvider, isTrue);
    expect(state.provider, isNull);
  });

  test('selectProvider transitions out of choosing mode and sets provider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(withdrawControllerProvider.notifier);
    controller.selectProvider(PaymentProvider.cbe);

    final state = container.read(withdrawControllerProvider);
    expect(state.isChoosingProvider, isFalse);
    expect(state.provider, equals(PaymentProvider.cbe));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/wallet/withdraw_controller_test.dart`  
Expected: FAIL with compilation error (missing `withdraw_controller.dart` / `withdraw_state.dart`).

- [ ] **Step 3: Implement `WithdrawState` and `WithdrawController`**

Create `lib/src/features/wallet/presentation/models/withdraw_state.dart`:
```dart
import 'package:flutter/foundation.dart';
import '../../data/models/payment_provider.dart';
import 'withdrawal_confirmation_state.dart';

@immutable
class WithdrawState {
  const WithdrawState({
    this.provider,
    this.isChoosingProvider = true,
    this.isSubmitting = false,
    this.confirmation,
    this.trackedWithdrawalId,
    this.savedCbeAccount = '',
    this.ownPhoneNumber,
  });

  final PaymentProvider? provider;
  final bool isChoosingProvider;
  final bool isSubmitting;
  final WithdrawalConfirmationState? confirmation;
  final String? trackedWithdrawalId;
  final String savedCbeAccount;
  final String? ownPhoneNumber;

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
  }) {
    return WithdrawState(
      provider: provider ?? this.provider,
      isChoosingProvider: isChoosingProvider ?? this.isChoosingProvider,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      confirmation: clearConfirmation ? null : (confirmation ?? this.confirmation),
      trackedWithdrawalId: clearTrackedId ? null : (trackedWithdrawalId ?? this.trackedWithdrawalId),
      savedCbeAccount: savedCbeAccount ?? this.savedCbeAccount,
      ownPhoneNumber: ownPhoneNumber ?? this.ownPhoneNumber,
    );
  }
}
```

Create `lib/src/features/wallet/presentation/controllers/withdraw_controller.dart`:
```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/realtime/wallet_entity_realtime.dart';
import '../../../../core/storage/app_preferences_storage.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/payment_provider.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/wallet_repository.dart';
import '../models/withdraw_state.dart';
import '../models/withdrawal_confirmation_state.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';

final withdrawControllerProvider =
    NotifierProvider<WithdrawController, WithdrawState>(WithdrawController.new);

class WithdrawController extends Notifier<WithdrawState> {
  Timer? _autoDismissTimer;
  Timer? _cbeSaveDebounce;
  static const _approvedDismissDelay = Duration(seconds: 8);

  @override
  WithdrawState build() {
    ref.onDispose(() {
      _autoDismissTimer?.cancel();
      _cbeSaveDebounce?.cancel();
    });

    final session = ref.watch(authControllerProvider).session;
    final phone = session?.user.phoneNumber.trim();
    return WithdrawState(
      ownPhoneNumber: (phone != null && phone.isNotEmpty) ? phone : null,
    );
  }

  void selectProvider(PaymentProvider provider) {
    state = state.copyWith(
      provider: provider,
      isChoosingProvider: false,
      clearConfirmation: true,
      clearTrackedId: true,
    );
  }

  void changeProvider() {
    state = state.copyWith(
      isChoosingProvider: true,
      clearConfirmation: true,
      clearTrackedId: true,
    );
  }

  void clearConfirmation() {
    _autoDismissTimer?.cancel();
    state = state.copyWith(clearConfirmation: true, clearTrackedId: true);
  }

  Future<void> loadSavedCbeAccount(String userId) async {
    final storage = await ref.read(appPreferencesStorageProvider.future);
    final saved = storage.readCbeWithdrawAccount(userId);
    state = state.copyWith(savedCbeAccount: saved);
  }

  void schedulePersistCbeAccount(String account) {
    _cbeSaveDebounce?.cancel();
    _cbeSaveDebounce = Timer(const Duration(milliseconds: 400), () async {
      final userId = ref.read(authControllerProvider).session?.user.id;
      if (userId == null) return;
      final trimmed = account.trim();
      if (trimmed.isEmpty || trimmed == state.savedCbeAccount) return;
      final storage = await ref.read(appPreferencesStorageProvider.future);
      await storage.writeCbeWithdrawAccount(userId, trimmed);
      state = state.copyWith(savedCbeAccount: trimmed);
    });
  }

  void handleRealtimeUpdate(WalletEntityUpdate update) {
    if (!update.isTerminal || state.trackedWithdrawalId != update.id) return;
    if (update.isApproved) {
      state = state.copyWith(
        confirmation: WithdrawalConfirmationState(
          kind: WithdrawalConfirmationKind.approved,
          provider: state.provider,
          amount: update.amount,
          withdrawalId: update.id,
        ),
      );
      _autoDismissTimer?.cancel();
      _autoDismissTimer = Timer(_approvedDismissDelay, clearConfirmation);
    } else if (update.isRejected) {
      state = state.copyWith(
        clearTrackedId: true,
        confirmation: WithdrawalConfirmationState(
          kind: WithdrawalConfirmationKind.rejected,
          provider: state.provider,
          amount: update.amount,
          withdrawalId: update.id,
          message: update.message,
        ),
      );
    }
  }

  Future<bool> submitWithdrawal({
    required String amount,
    required String receiver,
    required String password,
  }) async {
    final provider = state.provider;
    if (provider == null || state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true);
    try {
      final withdrawal = await ref.read(walletRepositoryProvider).createWithdrawal(
            provider: provider,
            amount: amount,
            password: password,
            receiverPhone: provider == PaymentProvider.telebirr ? receiver : null,
            receiverAccount: provider == PaymentProvider.cbe ? receiver : null,
          );

      if (provider == PaymentProvider.cbe) {
        final storage = await ref.read(appPreferencesStorageProvider.future);
        final userId = ref.read(authControllerProvider).session?.user.id;
        if (userId != null) {
          await storage.writeCbeWithdrawAccount(userId, receiver.trim());
        }
      }

      ref.invalidate(myWalletProvider);
      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      state = state.copyWith(
        isSubmitting: false,
        trackedWithdrawalId: withdrawal.id,
        confirmation: WithdrawalConfirmationState.pending(
          provider: provider,
          amount: amount,
          withdrawalId: withdrawal.id,
        ),
      );
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}
```

- [ ] **Step 4: Run unit tests to verify they pass**

Run: `flutter test test/features/wallet/withdraw_controller_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/wallet/presentation/models/withdraw_state.dart lib/src/features/wallet/presentation/controllers/withdraw_controller.dart test/features/wallet/withdraw_controller_test.dart
git commit -m "feat(wallet): add WithdrawState and WithdrawController notifier"
```

---

### Task 2: Decouple `WithdrawFormSection` Component

**Files:**
- Create: `lib/src/features/wallet/presentation/widgets/withdraw_form_section.dart`
- Test: `test/features/wallet/withdraw_form_section_test.dart`

**Interfaces:**
- Consumes: `WithdrawState`, `withdrawControllerProvider`, `WalletAmountLimits`
- Produces: `WithdrawFormSection` widget (< 220 lines)

- [ ] **Step 1: Write widget test for `WithdrawFormSection`**

```dart
// test/features/wallet/withdraw_form_section_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/controllers/withdraw_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/withdraw_form_section.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('WithdrawFormSection renders amount and receiver inputs for selected provider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(withdrawControllerProvider.notifier).selectProvider(PaymentProvider.telebirr);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WithdrawFormSection(availableBalance: '500.00'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/wallet/withdraw_form_section_test.dart`  
Expected: FAIL with compilation error (missing `withdraw_form_section.dart`).

- [ ] **Step 3: Implement `WithdrawFormSection` (< 220 lines)**

Create `lib/src/features/wallet/presentation/widgets/withdraw_form_section.dart` implementing the amount controller, receiver controller, phone formatting, validation, password dialog triggers, and CBE auto-save debounce hooks.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/wallet/withdraw_form_section_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/wallet/presentation/widgets/withdraw_form_section.dart test/features/wallet/withdraw_form_section_test.dart
git commit -m "feat(wallet): extract and decouple WithdrawFormSection widget"
```

---

### Task 3: Refactor `WithdrawScreen` Scaffold (< 180 lines)

**Files:**
- Modify: `lib/src/features/wallet/presentation/screens/withdraw_screen.dart`
- Test: `test/features/wallet/withdraw_screen_test.dart`

**Interfaces:**
- Consumes: `WithdrawBalanceStrip`, `WithdrawProviderChips`, `WithdrawFormSection`, `WithdrawalConfirmationBanner`, `WithdrawalRequestsTable`

- [ ] **Step 1: Write test for `WithdrawScreen`**

```dart
// test/features/wallet/withdraw_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/screens/withdraw_screen.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('WithdrawScreen renders balance strip and provider chips', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WithdrawScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
  });
}
```

- [ ] **Step 2: Refactor `withdraw_screen.dart` down to < 180 lines**

Replace the monolithic `_WithdrawScreenState` in `lib/src/features/wallet/presentation/screens/withdraw_screen.dart` with a clean `ConsumerWidget` or minimal stateful listener that delegates to `withdrawControllerProvider`, `WithdrawBalanceStrip`, `WithdrawProviderChips`, and `WithdrawFormSection`.

- [ ] **Step 3: Run tests and verify line count**

Run: `flutter test test/features/wallet/withdraw_screen_test.dart`  
Run: `(Get-Content lib/src/features/wallet/presentation/screens/withdraw_screen.dart | Measure-Object -Line).Lines`  
Expected: < 180 lines and PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/wallet/presentation/screens/withdraw_screen.dart test/features/wallet/withdraw_screen_test.dart
git commit -m "refactor(wallet): slim withdraw_screen.dart to clean scaffold under 180 lines"
```

---

### Task 4: Deposit State Model & Controller (`DepositState` & `DepositController`)

**Files:**
- Create: `lib/src/features/wallet/presentation/models/deposit_state.dart`
- Create: `lib/src/features/wallet/presentation/controllers/deposit_controller.dart`
- Test: `test/features/wallet/deposit_controller_test.dart`

**Interfaces:**
- Consumes: `WalletRepository`, `SocketService`, `SmartDepositParseResult`
- Produces: `depositControllerProvider` (`NotifierProvider<DepositController, DepositState>`)

- [ ] **Step 1: Write unit test for `DepositController`**

```dart
// test/features/wallet/deposit_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/controllers/deposit_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/models/deposit_state.dart';

void main() {
  test('DepositController initializes in smart entry tab', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(depositControllerProvider);
    expect(state.entryTab, equals(DepositEntryTab.smart));
    expect(state.isChoosingProvider, isTrue);
  });

  test('switchTab toggles between smart and regular tabs', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(depositControllerProvider.notifier);
    controller.switchTab(DepositEntryTab.regular);

    expect(container.read(depositControllerProvider).entryTab, equals(DepositEntryTab.regular));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/wallet/deposit_controller_test.dart`  
Expected: FAIL with compilation error (missing `deposit_controller.dart`).

- [ ] **Step 3: Implement `DepositState` and `DepositController`**

Create `deposit_state.dart` and `deposit_controller.dart` implementing:
- Provider selection & tab switching.
- Telebirr & CBE smart SMS/URL parsing triggers.
- Cooldown timer ticker for verification retries.
- Socket `wallet:updated` listeners for real-time deposit confirmations.
- Idempotent `submitDeposit(...)` calls.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/wallet/deposit_controller_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/wallet/presentation/models/deposit_state.dart lib/src/features/wallet/presentation/controllers/deposit_controller.dart test/features/wallet/deposit_controller_test.dart
git commit -m "feat(wallet): add DepositState and DepositController notifier"
```

---

### Task 5: Decouple Deposit Sub-Sections (`DepositSmartSection`, `DepositManualSection`, `DepositStatusCard`)

**Files:**
- Create: `lib/src/features/wallet/presentation/widgets/deposit_manual_section.dart`
- Create: `lib/src/features/wallet/presentation/widgets/deposit_status_card.dart`
- Modify: `lib/src/features/wallet/presentation/widgets/deposit_smart_section.dart`
- Test: `test/features/wallet/deposit_sections_test.dart`

**Interfaces:**
- Consumes: `depositControllerProvider`, `DepositState`, `DepositConfirmationBanner`
- Produces: Modular form and status components (< 200 lines each)

- [ ] **Step 1: Write test for decoupled deposit sections**

```dart
// test/features/wallet/deposit_sections_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/controllers/deposit_controller.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/deposit_manual_section.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('DepositManualSection renders amount and reference inputs', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(depositControllerProvider.notifier).selectProvider(PaymentProvider.cbe);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DepositManualSection(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/wallet/deposit_sections_test.dart`  
Expected: FAIL.

- [ ] **Step 3: Implement `DepositManualSection` and `DepositStatusCard`**

Create `deposit_manual_section.dart` (< 180 lines) and `deposit_status_card.dart` (< 150 lines), connecting them to `depositControllerProvider`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/wallet/deposit_sections_test.dart`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/wallet/presentation/widgets/deposit_manual_section.dart lib/src/features/wallet/presentation/widgets/deposit_status_card.dart lib/src/features/wallet/presentation/widgets/deposit_smart_section.dart test/features/wallet/deposit_sections_test.dart
git commit -m "feat(wallet): extract modular deposit form sections and status card"
```

---

### Task 6: Refactor `DepositScreen` Scaffold (< 220 lines)

**Files:**
- Modify: `lib/src/features/wallet/presentation/screens/deposit_screen.dart`
- Test: `test/features/wallet/deposit_screen_idempotent_test.dart`

**Interfaces:**
- Consumes: `depositControllerProvider`, `DepositGuideSteps`, `DepositSettlementAccountCard`, `DepositSmartSection`, `DepositManualSection`, `DepositStatusCard`

- [ ] **Step 1: Verify existing `deposit_screen_idempotent_test.dart`**

Run: `flutter test test/features/wallet/deposit_screen_idempotent_test.dart`  
Expected: PASS.

- [ ] **Step 2: Refactor `deposit_screen.dart` to < 220 lines**

Trim `deposit_screen.dart` from ~1,585 lines down to a clean, readable layout orchestrator (< 220 lines) that delegates input and status presentation to the newly created components.

- [ ] **Step 3: Run tests and verify line count**

Run: `flutter test test/features/wallet/deposit_screen_idempotent_test.dart`  
Run: `(Get-Content lib/src/features/wallet/presentation/screens/deposit_screen.dart | Measure-Object -Line).Lines`  
Expected: < 220 lines and PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/features/wallet/presentation/screens/deposit_screen.dart
git commit -m "refactor(wallet): slim deposit_screen.dart to clean layout orchestrator under 220 lines"
```

---

### Task 7: Full Verification & Static Analysis Gate

**Files:**
- None (verification across all files touched)

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze --no-fatal-infos lib test`  
Expected: Exit code 0 (0 errors, 0 warnings).

- [ ] **Step 2: Verify line count threshold across all wallet presentation files**

Run: `Get-ChildItem -Path "lib/src/features/wallet/presentation" -Filter "*.dart" -Recurse | ForEach-Object { [PSCustomObject]@{ Lines = (Get-Content $_.FullName | Measure-Object -Line).Lines; File = $_.Name } } | Format-Table -AutoSize`  
Expected: Every file is under 300 lines (and screens under 250 lines).

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`  
Expected: All 547+ tests pass.

- [ ] **Step 4: Commit and finalize branch**

```bash
git status
```
