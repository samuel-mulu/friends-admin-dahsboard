# Friends Bingo Mobile — Refactoring & Migration Baseline (Step 1)

> **Document**: Refactoring Baseline Record  
> **Target Branch**: `fix/cartela-registration-race`  
> **Timestamp**: 2026-10-22  
> **Status**: Baseline Verified (576/579 tests passing, 3 analyzer hints/warnings)

This baseline document records all critical application contracts, route paths, API endpoints, Riverpod providers, Socket.IO event names, local storage keys, and test baselines before any file relocation or architectural refactoring takes place.

---

## 1. Route Paths & Navigation Baseline

Governed by `lib/src/core/routing/app_router.dart`:

| Route Path | Screen Component | Protection / Guard |
|:---|:---|:---|
| `/loading` | `SplashScreen` | Public (Hold if mandatory update required) |
| `/login` | `LoginScreen` | Public (Redirects to target upon auth) |
| `/register` | `RegisterScreen` | Public |
| `/forgot-password` | `ForgotPasswordScreen` | Public |
| `/auth/telegram-phone` | `TelegramPhoneLinkScreen` | Public |
| `/support/contact` | `ContactUsScreen` | Public |
| `/support/my-feedback` | `MyFeedbackScreen` | Protected (Redirects to `/login`) |
| `/games` (Shell Tab 0) | `LiveGameScreen` | Public / Spectator (Bets require auth) |
| `/games/history` | `GameHistoryScreen` | Public / Spectator |
| `/games/big-game` | `BigGameScreen` | Public / Spectator |
| `/home` (Shell Tab 1) | `DashboardScreen` | Public |
| `/home/champions` | `HouseChampionsScreen` | Public |
| `/wallet` (Shell Tab 2) | `WalletScreen` | Protected (Redirects to `/login`) |
| `/wallet/deposit` | `DepositScreen` | Protected (Redirects to `/login`) |
| `/wallet/deposits` | `DepositHistoryScreen` | Protected (Redirects to `/login`) |
| `/wallet/withdraw` | `WithdrawScreen` | Protected (Redirects to `/login`) |
| `/wallet/withdrawals` | `WithdrawHistoryScreen` | Protected (Redirects to `/login`) |
| `/wallet/transactions` | `WalletTransactionsScreen` | Protected (Redirects to `/login`) |
| `/profile` (Shell Tab 3) | `ProfileScreen` | Protected (Redirects to `/login`) |

---

## 2. API Contracts & Endpoint Catalog

### A. Authentication & Sessions (`AuthRepository`, `SessionRepository`)
- `POST /auth/request-otp`
- `POST /auth/verify-otp`
- `POST /auth/request-register-otp`
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/request-password-reset-otp`
- `POST /auth/reset-password`
- `POST /auth/change-password`
- `POST /auth/request-set-password-otp`
- `POST /auth/set-password`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/telegram/start`
- `POST /auth/telegram/complete`
- `POST /auth/telegram/link`
- `POST /auth/telegram/unlink`
- `GET /auth/sessions`
- `DELETE /auth/sessions/:id`
- `POST /auth/sessions/logout-others`

### B. Games & Cartelas (`GamesRepository`)
- `GET /games`
- `GET /games/current/live`
- `GET /games/operations/current`
- `GET /games/big-game/current`
- `GET /games/slots/:id`
- `GET /games/sessions/:id`
- `GET /games/sessions/:id/winner-results`
- `GET /games/sessions/:id/round-winners`
- `GET /games/slots/:slotId/big-game/round-winners`
- `GET /games/sessions/:id/winner-result`
- `GET /games/sessions/:id/chain-rounds`
- `GET /games/sessions/:id/called-numbers`
- `GET /games/sessions/:id/registration-state`
- `POST /games/sessions/:id/register-cartela`
- `POST /games/slots/:slotId/register-cartela`
- `POST /games/slots/:slotId/register-cartelas-bulk`
- `POST /games/sessions/:id/reserve-cartelas-bulk`
- `POST /games/slots/:slotId/reserve-cartelas-bulk`
- `POST /games/sessions/:id/cartelas/:cartelaId/reserve`
- `POST /games/slots/:slotId/cartelas/:cartelaId/reserve`
- `POST /games/reservations/:id/confirm`
- `POST /games/reservations/:id/cancel`
- `POST /games/sessions/:id/bingo`
- `GET /games/sessions/:id/bingo-claims/:claimAttemptId`
- `GET /games/sessions/:id/my-cartelas`
- `GET /games/my-history`
- `GET /games/history`
- `GET /games/time-config`
- `GET /games/leaderboard/cartela-wins`
- `GET /cartelas`
- `GET /cartelas/:cartelaId/board`

### C. Wallet & Deposits (`WalletRepository`)
- `GET /wallet/me`
- `GET /wallet/transactions/me`
- `POST /deposits`
- `POST /deposits/check-ref`
- `GET /deposits/config`
- `GET /deposits/me`
- `GET /deposits/verification-attempts/active`
- `POST /deposits/verification-attempts/:attemptId/check`
- `POST /deposits/verification-attempts/:attemptId/cancel`
- `POST /withdrawals`
- `GET /withdrawals/me`

### D. System Services (`BroadcastsRepository`, `SupportRepository`, `FeatureSettingsRepository`, `VersionRepository`, `NotificationTokenRepository`)
- `GET /notifications/broadcasts`
- `DELETE /notifications/broadcasts/:id`
- `POST /support/messages`
- `GET /support/messages/me/unread-count`
- `POST /support/messages/me/mark-seen`
- `GET /support/messages/me`
- `GET /users/me/feature-settings`
- `PATCH /users/me/feature-settings`
- `GET /app-version/android`
- `POST /notifications/register-device`
- `DELETE /notifications/register-device`
- `PATCH /users/me/notification-preferences`

---

## 3. Realtime Socket.IO Events Baseline

- **Namespace**: `/realtime` | **Path**: `/socket.io`

### A. Emitted by Client
- `game:join` (`{ sessionId: string }`)
- `game:leave` (`{ sessionId: string }`)
- `realtime:ping` (`{}`)

### B. Listened by Client
- **Game State & Calls**:
  - `game:status_changed`
  - `game:operation_updated`
  - `game:number_called`
  - `game:cartelas:updated` (batched, 75ms)
  - `game:cartelas:summary`
  - `game:claim_created`
  - `game:winner_window_started`
  - `game:winner_window_finalized`
  - `game:finished`
  - `game:cancelled`
- **Chain Game Multi-Round**:
  - `chain:round_started`
  - `chain:round_finished`
  - `chain:round_paused`
  - `chain:break_extended`
- **Wallet & Account Updates**:
  - `wallet:updated`
  - `deposit:updated`
  - `withdrawal:updated`
  - `user:status_changed`
  - `user:feature_settings_updated`
- **Broadcasts & Support**:
  - `broadcast:new`
  - `broadcast:dismiss`
  - `support:new_message`

---

## 4. Riverpod Providers Baseline

### Foundational Core Providers
- `apiClientProvider`
- `socketServiceProvider`
- `secureTokenStorageProvider`
- `appPreferencesStorageProvider`
- `appRouterProvider`
- `goRouterRefreshProvider`
- `deviceSecurityControllerProvider`
- `screenAwakeControllerProvider`
- `firebaseNotificationServiceProvider`
- `notificationPreferencesControllerProvider`
- `soundPreferencesControllerProvider`
- `versionCheckControllerProvider`
- `serverClockProvider`

### Feature Providers
- **Auth**:
  - `authControllerProvider`
  - `authFlowProvider`
  - `accountBanProvider`
  - `telegramDeepLinkProvider`
  - `authRepositoryProvider`
  - `sessionRepositoryProvider`
- **Wallet**:
  - `walletProvider`
  - `depositControllerProvider`
  - `withdrawControllerProvider`
  - `depositConfigProvider`
  - `walletHistoryProviders` (deposit, withdraw, transactions)
  - `walletRepositoryProvider`
- **Games**:
  - `liveGameStateProvider`
  - `playerCartelasNotifierProvider`
  - `calledBallsNotifierProvider`
  - `liveGameControllersProvider`
  - `liveRegistrationControllerProvider`
  - `liveBingoClaimCoordinatorProvider`
  - `liveCalledNumbersControllerProvider`
  - `liveCountdownControllerProvider`
  - `liveWinnerCelebrationCoordinatorProvider`
  - `liveChainGameCoordinatorProvider`
  - `liveResumeSyncCoordinatorProvider`
  - `liveRealtimeControllerProvider`
  - `liveReviewControllerProvider`
  - `liveTransitionControllerProvider`
  - `missedPreviewControllerProvider`
  - `currentGameOperationsProvider`
  - `currentBigGameProvider`
  - `cartelaCatalogProvider`
  - `cartelaMarkColorProvider`
  - `cartelaSortModeProvider`
  - `hasActiveRegisteredCartelasProvider`
  - `registrationCartelaGridSummaryProvider`
  - `registrationStatePatchProvider`
  - `houseChampionsProvider`
  - `gameHistoryProvider`
  - `gamesRepositoryProvider`
  - `cartelaMarksStorageProvider`
  - `bingoClaimAttemptStorageProvider`
  - `bigGameSummaryLedgerProvider`
  - `gameOperationsSyncCoordinatorProvider`
- **Profile, Messages, Settings, Support**:
  - `profileAvatarProvider`
  - `broadcastsProvider`
  - `broadcastBannerProvider`
  - `localeProvider`
  - `themeModeProvider`
  - `featureSettingsProvider`
  - `firstLaunchPreferencesProvider`
  - `supportMessagesProvider`
  - `supportUnreadProvider`

---

## 5. Storage Keys Baseline

### A. FlutterSecureStorage (`SecureTokenStorage`)
- `access_token`: JWT access token string
- `refresh_token`: Refresh token string
- `device_id`: Generated UUIDv4 hardware ID
- `user_profile`: JSON encoded `UserProfile` object

### B. SharedPreferences (`AppPreferencesStorage`, etc.)
- `theme_mode`: `'light'`, `'dark'`, `'system'`
- `app_locale`: `'en'`, `'am'`, `'om'`, `'ti'`
- `first_launch_preferences_completed`: `bool`
- `realtime_branding_splash_seen`: `bool`
- `cartela_mark_color`: `'green'`, `'red'`, `'amber'`, etc.
- `cartela_sort_mode`: `'manual'`, `'best_remains'`
- `cartela_sort_max_remains`: `int` (1..4)
- `profile_avatar_<userId>`: Avatar preset key
- `dismissed_game_announcements`: `List<String>`
- `cbe_withdraw_account_<userId>`: String (e.g. `1000...`)
- `pending_deposit_attempt_<userId>`: String (`attemptId|provider|amount|ref`)
- `friends_bingo_marks_v1:<userId>:<sessionId>`: JSON set of marked cells
- `friends_bingo_attempt_v1:<userId>:<sessionId>:<cartelaId>`: JSON claim identity
- `friends_bingo_bg_summary_v1:<userId>:<slotId>:<sessionId>`: Big Game summary
- `friends_bingo_bg_summary_idx_v1:<userId>`: Big Game summary index list
- `sounds.enabled`, `sounds.called_number_enabled`, `sounds.game_start_enabled`, `sounds.winner_window_enabled`, `sounds.valid_bingo_enabled`, `sounds.vibrate_enabled`: `bool`
- `notifications.push_enabled`, `notifications.game_push_mode`, `notifications.deposit_approved_enabled`, `notifications.withdrawal_approved_enabled`, `notifications.withdrawal_rejected_enabled`, `notifications.system_enabled`: `bool`/`String`

---

## 6. Pre-Refactor Test & Analysis Baseline

- **Total Test Count**: 579 tests executed.
- **Passing Tests**: 576 tests passing.
- **Pre-existing Failures (3)**:
  1. `test/features/games/bingo_claim_recovery_lifecycle_test.dart` (UUID relock expectation)
  2. `test/features/games/live_registration_controller_snapshot_guard_test.dart` (remote snapshot acceptance condition)
  3. `test/features/wallet/telebirr_receipt_preview_service_test.dart` (missing `--dart-define=API_BASE_URL` in test runner)
- **Pre-existing Lints/Warnings (3)**:
  1. `lib/src/features/games/presentation/screens/big_game_phase_views.dart:513` - `use_null_aware_elements` (info)
  2. `lib/src/features/games/presentation/screens/live_game_called_numbers.dart:412` - `use_build_context_synchronously` (info)
  3. `lib/src/features/games/presentation/screens/live_game_realtime.dart:646` - `unused_element` (warning)
