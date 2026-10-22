# Friends Bingo Mobile — Complete Architecture & Folder Structure Guide

> **Project**: Friends Bingo Mobile App (`friends_bingo_app`)  
> **Framework**: Flutter (Dart SDK `^3.11.4`)  
> **State Management**: Flutter Riverpod (`^3.3.1`)  
> **Navigation**: GoRouter (`^17.3.0`)  
> **Network & Realtime**: Dio (`^5.9.2`), Socket.IO Client (`^3.1.4`)  
> **Local Storage**: Flutter Secure Storage (`^10.3.1`), SharedPreferences (`^2.5.3`)  
> **Architecture Pattern**: Feature-First Clean Architecture (Presentation, Domain, Data)

---

## Table of Contents
1. [High-Level Architectural Overview](#1-high-level-architectural-overview)
2. [Complete Directory & File Structure](#2-complete-directory--file-structure)
3. [State Management Architecture (Riverpod 3)](#3-state-management-architecture-riverpod-3)
4. [Validation Architecture](#4-validation-architecture)
5. [Navigation & Routing (GoRouter)](#5-navigation--routing-gorouter)
6. [Realtime WebSocket & Synchronization Architecture](#6-realtime-websocket--synchronization-architecture)
7. [Local Storage & Caching Layer](#7-local-storage--caching-layer)
8. [Device Security & Hardware Control](#8-device-security--hardware-control)
9. [Localization (i18n) & Theming](#9-localization-i18n--theming)

---

## 1. High-Level Architectural Overview

`friends-bingo-mobile` is organized around a **Feature-Driven Layered Architecture**:

```
lib/
├── l10n/                 # Multi-language localization ARB files & generated classes
├── main.dart             # App entrypoint (initialization, provider scope, error zones)
└── src/
    ├── app.dart          # Root ConsumerWidget (Lifecycle, deep links, security gates)
    ├── core/             # Cross-cutting foundational infrastructure & services
    │   ├── config/       # App environments & backend endpoints
    │   ├── device/       # Wakelock, device integrity & root detection
    │   ├── l10n/         # Locale delegates & fallback providers
    │   ├── logging/      # Structured application logging
    │   ├── network/      # Dio HTTP client, envelopes, interceptors, pagination
    │   ├── notifications/# Firebase Cloud Messaging & local notifications
    │   ├── realtime/     # Socket.IO wrapper & lifecycle connection guards
    │   ├── routing/      # GoRouter configuration, route guards, redirect policies
    │   ├── sound/        # Audio playback engine for game effects & calls
    │   ├── storage/      # Secure token storage & shared preferences
    │   ├── sync/         # Lifecycle resume synchronizer (anti-stale recovery)
    │   ├── theme/        # Color schemes, typography, spacing & design tokens
    │   ├── time/         # Monotonic server clock sync & countdown trackers
    │   ├── utils/        # Formatters, date-time parsers, helpers
    │   ├── version/      # Force/optional update verifier & prompt dialogs
    │   └── widgets/      # Universal shared UI components
    └── features/         # Self-contained business domain modules
        ├── auth/         # Authentication, OTP, session management, account ban
        ├── games/        # Core Bingo gameplay, cartelas, live calls, claim engine
        ├── wallet/       # Balances, deposits (Telebirr/CBE parser), withdrawals
        ├── home/         # Dashboard, shell navigation, top app bar
        ├── profile/      # User profile, custom avatar presets
        ├── messages/     # Admin broadcast messages & announcements
        ├── settings/     # Locale, theme, feature toggles, first-launch gate
        ├── support/      # Feedback tickets & customer service chat
        └── shared/       # Splash screen, loading branding
```

---

## 2. Complete Directory & File Structure

Below is the exhaustive file-by-file map of the mobile application:

### `lib/` Root & Localization
```
lib/
├── main.dart                                         # Initializes Riverpod, dotenv, Firebase, runs runApp
├── l10n/
│   ├── app_am.arb                                    # Amharic localization strings
│   ├── app_en.arb                                    # English localization strings
│   ├── app_om.arb                                    # Afaan Oromo localization strings
│   ├── app_ti.arb                                    # Tigrinya localization strings
│   ├── app_localizations.dart                        # Abstract base generated localization class
│   ├── app_localizations_am.dart                     # Generated Amharic implementation
│   ├── app_localizations_en.dart                     # Generated English implementation
│   ├── app_localizations_om.dart                     # Generated Afaan Oromo implementation
│   └── app_localizations_ti.dart                     # Generated Tigrinya implementation
```

### `lib/src/core/` (Foundational Services)
```
lib/src/core/
├── config/
│   ├── app_config.dart                               # API base URLs, socket URLs, environment constants
│   └── app_support.dart                              # Customer support phone/telegram contact endpoints
├── device/
│   ├── android_device_security.dart                  # Checks for emulator, root access, debug flags
│   ├── device_security_controller.dart               # Riverpod controller managing device security state
│   ├── device_security_gate.dart                     # Blocking gate UI preventing tampered device execution
│   ├── screen_awake_controller.dart                  # Keeps phone screen on during live bingo gameplay
│   └── screen_awake_service.dart                     # WakelockPlus platform wrapper
├── l10n/
│   ├── app_locale.dart                               # Supported locales enum (en, am, om, ti) & helpers
│   └── fallback_global_localizations.dart            # Material/Cupertino localization fallbacks
├── logging/
│   └── app_logger.dart                               # Scoped log output formatter with log levels
├── network/
│   ├── api_client.dart                               # Dio instance with auth token headers & error interceptors
│   ├── api_envelope.dart                             # Standard backend envelope parser: { success, data, error }
│   ├── api_exception.dart                            # Custom typed network exception hierarchy
│   ├── paginated_response.dart                       # Generic paginated wrapper model
│   └── pagination_meta.dart                          # Pagination metadata (page, limit, totalPages, totalItems)
├── notifications/
│   ├── app_notification_category.dart                # Notification categories (game_start, deposit, win, etc.)
│   ├── app_push_message.dart                         # Push notification data model
│   ├── auth_notification_sync.dart                   # Syncs FCM device token with backend on login/logout
│   ├── firebase_notification_service.dart            # FirebaseMessaging initialization & foreground handler
│   ├── notification_display_policy.dart              # Suppresses in-app toasts when player is in active session
│   ├── notification_preferences.dart                 # Push notification toggles (always, registered_only, off)
│   ├── notification_token_repository.dart            # Saves and sends FCM device tokens to backend
│   └── push_route_resolver.dart                      # Resolves navigation route when tapping push notifications
├── realtime/
│   ├── socket_service.dart                           # Socket.IO connection manager, reconnect logic, event bus
│   ├── wallet_entity_realtime.dart                   # Realtime wallet event payloads
│   └── wallet_realtime_sync.dart                     # Subscribes to wallet:updated and auto-refreshes balance
├── routing/
│   ├── app_router.dart                               # GoRouter definition with StatefulShellRoute tabs
│   ├── auth_route_guard.dart                         # Determines route accessibility (guest vs authenticated)
│   └── go_router_refresh.dart                        # Listenable bridging Riverpod changes to GoRouter
├── sound/
│   ├── game_sound_service.dart                       # Audioplayers manager for ball call, win, countdown audio
│   ├── sound_event.dart                              # Audio event enum (ballCalled, claimSubmitted, winCheer)
│   └── sound_preferences.dart                        # User audio mute/volume preferences
├── storage/
│   ├── app_preferences_storage.dart                  # SharedPreferences wrapper (theme, language, audio)
│   └── secure_token_storage.dart                     # FlutterSecureStorage wrapper for access & refresh tokens
├── sync/
│   ├── app_resume_sync.dart                          # Coordinated re-fetch of game & wallet on AppLifecycleState.resumed
│   └── resume_sync_guard.dart                        # Prevents thundering herd duplicate sync requests
├── theme/
│   ├── app_branding.dart                             # Brand colors, primary golds, emerald greens, dark slates
│   ├── app_spacing.dart                              # Standard padding, radius, and margin constants
│   └── app_theme.dart                                # ThemeData generator for light and dark modes
├── time/
│   ├── countdown_target_tracker.dart                 # High-precision monotonic target timestamp tracker
│   ├── server_clock_provider.dart                    # Riverpod provider for calibrated current time
│   └── server_clock_service.dart                     # Computes server-to-client clock skew/offset
├── utils/
│   ├── api_date_time.dart                            # ISO-8601 parser and local converter
│   ├── external_links.dart                           # UrlLauncher wrappers for Telegram, browser, phone calls
│   ├── formatters.dart                               # Currency (ETB), number, and date string formatters
│   ├── l10n.dart                                     # Convenient BuildContext.l10n extension
│   └── uppercase_text_formatter.dart                 # TextInputFormatter enforcing uppercase input
├── version/
│   ├── android_app_version_model.dart                # Backend version check response model
│   ├── app_update_dialog.dart                        # Mandatory and optional update prompt modals
│   ├── app_version_info.dart                         # Reads local PackageInfo build and version
│   ├── version_check_controller.dart                 # Riverpod controller determining if update is required
│   ├── version_check_state.dart                      # State union (upToDate, optionalUpdate, forceUpdate)
│   ├── version_repository.dart                       # HTTP client fetching latest version from `/app-version/android`
│   ├── version_update_cache.dart                     # Caches version check to prevent duplicate prompts
│   └── version_update_resume_recheck.dart            # Triggers re-check when returning from browser download
└── widgets/
    ├── app_back_confirm_scope.dart                   # Intercepts Android back gestures to prevent accidental exits
    ├── compact.dart                                  # Compact UI helper layout wrapper
    ├── friends_bingo_loader.dart                     # Branded animated loading indicator
    └── friends_bingo_wordmark.dart                   # Custom styled SVG/Text logo wordmark
```

### `lib/src/features/` (Domain Features)

#### A. Auth Feature (`lib/src/features/auth/`)
```
features/auth/
├── data/
│   ├── auth_repository.dart                          # HTTP calls for login, register, OTP request/verify, reset
│   ├── device_meta.dart                              # Collects OS version, device brand, device ID
│   └── session_repository.dart                       # Manages active sessions and session revocation
├── domain/
│   ├── auth_device_session.dart                      # Active login session entity
│   ├── auth_session.dart                             # Access token, refresh token, user profile entity
│   ├── registration_draft.dart                       # Temporary state holding user registration input
│   └── user_profile.dart                             # Authenticated user model
├── presentation/
│   ├── controllers/
│   │   └── auth_controller.dart                      # AuthStateNotifier (login, logout, refresh, token check)
│   ├── providers/
│   │   ├── account_ban_provider.dart                 # Listens to realtime account ban notifications
│   │   ├── auth_flow_provider.dart                   # Manages multi-step registration & OTP state
│   │   └── telegram_deep_link_provider.dart          # Handles Telegram bot authentication link callbacks
│   ├── screens/
│   │   ├── forgot_password_screen.dart               # Phone entry, OTP verification, new password submission
│   │   ├── login_screen.dart                         # Phone and password login with guest browse mode
│   │   ├── register_screen.dart                      # Registration form with phone, password, full name
│   │   └── telegram_phone_link_screen.dart           # Screen linking Telegram account to mobile phone
│   └── widgets/
│       ├── account_ban_overlay.dart                  # Fullscreen blocking overlay when account is banned
│       ├── account_ban_realtime_sync.dart            # Subscribes to `user:status_changed` socket event
│       ├── active_sessions_sheet.dart                # Bottom modal showing other logged-in devices
│       ├── auth_brand_header.dart                    # Header with logo, title, and back navigation
│       ├── auth_error_listener.dart                  # Snack-bar and toast dispatcher for auth errors
│       ├── auth_form_field.dart                      # Reusable input field with styled borders and validation
│       ├── auth_home_back_button.dart                # Back button navigating directly to games hub
│       ├── auth_primary_button.dart                  # Golden gradient loading-aware action button
│       ├── auth_screen_scaffold.dart                 # Scaffold wrapper with keyboard dismiss & background
│       ├── auth_status_message_listener.dart         # Listens to auth notices (e.g. session expired)
│       ├── auth_validators.dart                      # Phone number, password length, and name regex checks
│       ├── forgot_password_reset_panel.dart          # Step panel for setting a new password
│       ├── guest_auth_prompt_sheet.dart              # Prompt modal asking guest to log in to place bet
│       ├── otp_code_input.dart                       # 4/6-digit PIN input fields with autofocus
│       ├── otp_resend_button.dart                    # Countdown timer preventing rapid OTP re-sending
│       ├── register_otp_panel.dart                   # Step panel for entering registration SMS code
│       ├── security_password_sheet.dart              # Password re-entry dialog for sensitive actions
│       └── sms_otp_hint_banner.dart                  # Informational banner on SMS delivery expectations
└── session/
    └── session_manager.dart                          # Coordinates token storage and auth state synchronization
```

#### B. Games Feature (`lib/src/features/games/`)
```
features/games/
├── data/
│   ├── big_game_summary_ledger_storage.dart         # Local storage cache for Big Game prize summaries
│   ├── bingo_claim_attempt_storage.dart              # Local idempotency cache for bingo claim attempts
│   ├── cartela_marks_storage.dart                    # Local persistence for marked cells (offline-resilient)
│   ├── games_repository.dart                         # HTTP client for game sessions, cartelas, claims, history
│   └── models/
│       ├── bingo_claim_result.dart                   # Claim outcome (VALID, INVALID, ALREADY_RESOLVED)
│       ├── bulk_reserve_cartelas_result.dart         # Result of multi-cartela reservation
│       ├── called_number_model.dart                  # Single called ball (number, letter, callIndex)
│       ├── called_numbers_snapshot.dart              # Complete array of called balls in session
│       ├── cartela_catalog_page.dart                 # Paginated list of available cartela IDs
│       ├── cartela_model.dart                        # 5x5 numbers grid layout for a cartela
│       ├── cartela_reservation_model.dart            # Active reservation countdown with hold token
│       ├── chain_round_plan_model.dart               # Multi-round Chain Game rules & prize allocation
│       ├── completed_pattern_model.dart              # Detected pattern (Line, Full House, Shape)
│       ├── game_cartela_model.dart                   # Registered cartela linked to player and game
│       ├── game_model.dart                           # Game session details (status, category, fee, prize)
│       ├── game_timing_config_model.dart             # Countdown durations and ball call intervals
│       ├── house_champions_model.dart                # Leaderboard winners data
│       ├── registration_state_model.dart             # Public registration status, count, and progress
│       ├── round_winner_history_model.dart           # Past round winner records
│       ├── session_outcome_summary_model.dart        # Final game summary with payout breakdown
│       └── session_winner_result_model.dart          # Verified winners list and winning patterns
├── domain/
│   ├── attended_game_history_entry.dart              # Player's participation record
│   ├── attended_game_history_state.dart              # History query pagination state
│   ├── backend_called_number_identity.dart           # Identity comparator for ball call monotonicity
│   ├── big_game_phase.dart                           # Phased state enum for daily Big Game
│   ├── big_shape_patterns.dart                       # Specific geometric pattern definitions
│   ├── bingo_claim_source.dart                       # Claim trigger source (MANUAL vs AUTO_BINGO)
│   ├── bulk_register_result.dart                     # Bulk registration execution result
│   ├── cartela_availability.dart                     # Cartela state (available, reserved, registered)
│   ├── cartela_board_preview_cache.dart              # In-memory board numbers cache
│   ├── cartela_catalog_shuffle.dart                  # Pseudo-random cartela selector helper
│   ├── cartela_catalog_state.dart                    # Catalog pagination and selection state
│   ├── cartela_mark_color.dart                       # Player-selected dabber color enum
│   ├── cartela_payment_source.dart                   # Balance source (MONEY_WALLET, BONUS_CARTELA, TICKET)
│   ├── extended_game_patterns.dart                   # Letters and shapes (L, T, X, Corner, Center)
│   ├── game_category_theme.dart                      # Styling and badges by category (NORMAL, BIG, CHAIN)
│   ├── game_rule_localized_name.dart                 # Translated names for rules
│   ├── game_rule_pattern_preview.dart                # 5x5 visual representation of winning pattern
│   ├── games_hub_snapshot.dart                       # Overview snapshot of all current slots
│   ├── live_connection_status.dart                   # Socket connection enum (connecting, connected, retrying)
│   ├── live_game_state.dart                          # Immutable model of active live game state
│   ├── registration_state_patch.dart                 # Socket patch updating registered cartela counts
│   ├── resolved_cartela_availability.dart            # Final resolved state of each cartela
│   └── winning_ball_cell.dart                        # Coordinates of winning cell on 5x5 board
├── presentation/
│   ├── components/
│   │   ├── bingo_ball_badge.dart                     # Distinctive B-I-N-G-O colored ball circle
│   │   └── bingo_claim_button.dart                   # Prominent animated claim button with pulse state
│   ├── controllers/
│   │   ├── called_balls_notifier.dart                # Maintains monotonic stream of called numbers
│   │   ├── live_bingo_claim_coordinator.dart         # Coordinates claim request, debounce, and response dialogs
│   │   ├── live_called_numbers_controller.dart       # Handles ball stream animation timing
│   │   ├── live_chain_game_coordinator.dart          # Manages inter-round transitions in Chain Games
│   │   ├── live_countdown_controller.dart            # Ticks countdowns (registration, round start, next ball)
│   │   ├── live_countdown_tick_context.dart          # Elapsed and remaining duration context
│   │   ├── live_game_controllers.dart                # Composite live game controller exports
│   │   ├── live_game_host.dart                       # Root orchestration layer for active game screen
│   │   ├── live_realtime_controller.dart             # Bridges socket events to game state
│   │   ├── live_registration_controller.dart         # Cartela selection, reservation timer, and registration
│   │   ├── live_resume_sync_coordinator.dart         # Reconciles live state on app resume or reconnect
│   │   ├── live_review_controller.dart               # Post-game winner review state
│   │   ├── live_transition_controller.dart           # Smooth UI mode transitions (Waiting -> Playing -> Finished)
│   │   ├── live_winner_celebration_coordinator.dart  # Fireworks, confetti, and sound coordinator on win
│   │   ├── missed_preview_controller.dart            # Shows missed balls if player entered mid-game
│   │   ├── player_cartelas_notifier.dart             # Maintains player's registered cartelas and marks
│   │   ├── registration_action_result.dart           # UI feedback state after registration attempt
│   │   └── registration_panel_session.dart           # State of open registration bottom sheet
│   ├── providers/
│   │   ├── big_game_prompt_dismiss_provider.dart     # Tracks dismissed Big Game promotional banners
│   │   ├── big_game_summary_ledger_provider.dart     # Provides cached Big Game results
│   │   ├── cartela_catalog_provider.dart             # Paginated cartelas catalog provider
│   │   ├── cartela_mark_color_provider.dart          # Active dabber mark color provider
│   │   ├── cartela_marks_storage_provider.dart       # Persistence provider for marked cells
│   │   ├── cartela_sort_mode_provider.dart           # Sorting provider (by number, nearest to win)
│   │   ├── current_big_game_provider.dart            # Active Big Game details provider
│   │   ├── current_game_operations_provider.dart     # Realtime slot operations snapshot provider
│   │   ├── game_announcement_dismiss_provider.dart   # Dismissed banner tracker
│   │   ├── game_history_provider.dart                # Past games pagination provider
│   │   ├── game_operations_sync_coordinator.dart     # Syncs operations updates with local providers
│   │   ├── games_providers.dart                      # Primary games repository & service providers
│   │   ├── has_active_registered_cartelas_provider.dart # Fast boolean check if user is playing
│   │   ├── house_champions_provider.dart             # Champions leaderboard provider
│   │   ├── live_game_state_provider.dart             # Primary live game state provider
│   │   ├── realtime_connection_provider.dart         # Socket connection state provider
│   │   ├── registration_cartela_grid_summary_provider.dart # Summary of cartela selection in grid
│   │   └── registration_state_patch_provider.dart    # Realtime delta patch provider
│   ├── screens/
│   │   ├── big_game_live_host.dart                   # Big Game live event host container
│   │   ├── big_game_phase_views.dart                 # Phased views (Upcoming, Registering, Live, Results)
│   │   ├── big_game_screen.dart                      # Dedicated screen for daily scheduled Big Bingo
│   │   ├── game_history_screen.dart                  # User's past games and winnings list
│   │   ├── house_champions_screen.dart               # Top winners & leaderboards screen
│   │   ├── live_game_called_numbers.dart             # Live ball strip and call history view
│   │   ├── live_game_orchestration.dart              # Orchestrates game views based on status
│   │   ├── live_game_realtime.dart                   # Realtime socket connector wrapper
│   │   ├── live_game_registration.dart               # Cartela selection & registration screen
│   │   ├── live_game_screen.dart                     # Main live bingo playing screen
│   │   └── live_game_winner_window.dart              # Multi-winner claim review window view
│   ├── utils/
│   │   ├── auto_bingo_runtime.dart                   # Client-side auto-bingo detection & claim emitter
│   │   ├── big_game_countdown.dart                   # Formatter for Big Game start countdown
│   │   ├── big_game_live_bootstrap.dart              # Prepares state when joining Big Game
│   │   ├── big_game_live_presentation.dart           # Visual presentation helpers for Big Game
│   │   ├── big_game_navigation.dart                  # Routing helpers for Big Game deep links
│   │   ├── bingo_claim_eligibility.dart              # Validates if player can submit claim
│   │   ├── blocked_cartela_reason.dart               # Translates cartela blocking reason codes
│   │   ├── cartela_board_layout.dart                 # Generates 5x5 grid layout with FREE center
│   │   ├── cartela_display_order.dart                # Sorts cartelas (best progress first)
│   │   ├── cartela_mark_helpers.dart                 # Toggles cell mark state
│   │   ├── cartela_marked_pattern_evaluator.dart     # Evaluates if marked cells satisfy winning pattern
│   │   ├── cartela_outcome_public_visibility.dart    # Rules on when winners are shown publicly
│   │   ├── cartela_pattern_progress_overlay.dart     # Computes 1-away / 2-away progress percentage
│   │   ├── cartela_play_helpers.dart                 # Helpers for cell tap interactions
│   │   ├── cartela_selection_cap.dart                # Enforces max selectable cartelas limit
│   │   ├── chain_round_cartela_state.dart            # Carries forward cartelas across Chain Game rounds
│   │   ├── current_cartela_snapshot_guard.dart       # Protects cartela snapshot during round changes
│   │   ├── game_operations_resume_cache.dart         # Caches operations snapshot across app pause/resume
│   │   ├── live_api_failure_log.dart                 # Diagnostic error logger for live game calls
│   │   ├── live_called_number_monotonic.dart         # Enforces strictly increasing call sequence
│   │   ├── live_called_number_sync.dart              # Syncs called number array with incoming socket events
│   │   ├── live_embedded_operations_snapshot.dart    # Extracts embedded operational parameters
│   │   ├── live_game_event_guard.dart                # Drops duplicate or out-of-order socket events
│   │   ├── live_game_finish_transition.dart          # Manages transition to finished state
│   │   ├── live_game_resume_owner_registry.dart      # Tracks ownership of active live resume tasks
│   │   ├── live_preparing_poll_sync_gate.dart        # Polls game status during NEXT state transition
│   │   ├── live_presentation_phase.dart              # Computes current presentation stage
│   │   ├── live_primary_game_selection.dart          # Selects primary active game among multiple slots
│   │   ├── live_ready_atomic_visibility.dart         # Coordinates READY screen visibility
│   │   ├── live_ready_transition_lock.dart           # Mutex lock preventing double transitions to READY
│   │   ├── live_registration_metrics_patch.dart      # Updates player counts and prize pools live
│   │   ├── live_registration_target.dart             # Target session resolver for registration
│   │   ├── live_registration_visibility.dart         # Controls registration dock display
│   │   ├── live_resume_conditional_fetch.dart        # Evaluates whether HTTP fetch is needed on resume
│   │   ├── live_resume_provider_policy.dart          # Defines which providers to invalidate on resume
│   │   ├── live_resume_sync.dart                     # Core resume sync execution logic
│   │   ├── live_resume_terminal_gate.dart            # Halts sync if game reached terminal state
│   │   ├── live_round_break.dart                     # Inter-round pause countdown calculator
│   │   ├── live_session_ownership.dart               # Checks if current session belongs to active slot
│   │   ├── live_socket_session_membership.dart       # Manages Socket.IO room joining and leaving
│   │   ├── live_status_socket_patch.dart             # Applies status changes from socket payload
│   │   ├── live_sync_trigger_action.dart             # Triggers targeted refresh actions
│   │   ├── live_terminal_apply.dart                  # Handles game completion cleanup
│   │   ├── live_terminal_enter_policy.dart           # Determines when to exit live game room
│   │   ├── live_ui_mode.dart                         # Active UI mode (Registering, Playing, Claiming, Winner)
│   │   ├── merge_registered_cartelas.dart            # Merges incoming registered cartelas without losing marks
│   │   ├── missed_live_preview_numbers.dart          # Formats missed balls for late-joining players
│   │   ├── missed_live_preview_resolver.dart         # Computes missed balls count
│   │   ├── missed_live_preview_sync.dart             # Synchronizes catch-up state
│   │   ├── missed_overlap_lifecycle.dart             # Manages overlap between missed balls and live calls
│   │   ├── missed_preview_foreign_session_sync.dart  # Resets preview if user switches session
│   │   ├── next_ball_countdown.dart                  # Calculates remaining seconds until next call
│   │   ├── next_ball_stale_guard.dart                # Prevents stale ball call animation glitches
│   │   ├── number_called_schedule_patch.dart         # Updates ball call schedule
│   │   ├── registration_cartela_grid_index.dart      # Maps grid index to cartela ID
│   │   ├── registration_cartela_grid_layout.dart     # Responsive grid columns and aspect ratio
│   │   ├── registration_error_helpers.dart           # Translates registration errors into user messages
│   │   ├── registration_reg_display_count.dart       # Formats display of registered vs total cartelas
│   │   ├── registration_ux_metrics.dart              # User engagement metrics during registration
│   │   ├── round_winner_history_adapters.dart        # Formats round winner records
│   │   ├── session_winner_results_for_display.dart   # Groups winners by pattern and prize share
│   │   ├── socket_payload_dartify_stub.dart          # Platform stub for JS-to-Dart payload conversion
│   │   ├── socket_payload_dartify_web.dart           # Web-specific JS object converter
│   │   ├── socket_payload_normalizer.dart            # Normalizes socket JSON payloads across platforms
│   │   ├── winner_cartela_live_display.dart          # Formats winning cartela preview
│   │   └── winner_pattern_clear_policy.dart          # Governs pattern highlight cleanup
│   └── widgets/
│       ├── all_rounds_winner_cards.dart              # Multi-round winner cards for Chain Games
│       ├── big_game_info_strip.dart                  # Banner showing Big Game schedule and pot
│       ├── big_game_live_prompt_banner.dart          # Floating prompt to jump to live Big Game
│       ├── blocked_cartela_reason_dialog.dart        # Dialog explaining why cartela was blocked
│       ├── bonus_game_info_strip.dart                # Info bar for free-to-play Bonus games
│       ├── bulk_cartela_review_sheet.dart            # Review sheet before confirming bulk buy
│       ├── called_numbers_strip.dart                 # Horizontal scrolling strip of recent called balls
│       ├── cartela_board_preview.dart                # 5x5 interactive cartela board widget
│       ├── cartela_number_badge.dart                 # Badge displaying cartela number ID (#12)
│       ├── cartela_number_chip.dart                  # Selectable cartela chip in registration grid
│       ├── cartela_number_dialog.dart                # Dialog to jump directly to specific cartela number
│       ├── cartela_pattern_progress_painter.dart     # Custom painter showing winning pattern line overlays
│       ├── cartela_preview_sheet.dart                # Modal previewing cartela board before purchase
│       ├── cartela_registration_sheet.dart           # Bottom sheet for selecting and registering cartelas
│       ├── chain_game_info_strip.dart                # Multi-round progress bar for Chain Games
│       ├── chain_game_rounds_dialog.dart             # Dialog showing rules & prizes of all rounds
│       ├── chain_round_break_banner.dart             # Inter-round break countdown banner
│       ├── chain_round_winners_bar.dart              # Strip showing winners of previous rounds
│       ├── collapsible_live_top_section.dart         # Expandable header holding game details & pot
│       ├── collapsible_registered_cartela_chips.dart # Quick selector chips for player's cartelas
│       ├── game_announcement_banner.dart             # Top banner for admin broadcast notices
│       ├── game_category_badge.dart                  # Color-coded badge (NORMAL, BIG GAME, CHAIN)
│       ├── game_compact_info_bar.dart                # Compact bar showing players count & prize
│       ├── game_countdown.dart                       # Circular/linear countdown widget
│       ├── game_empty_state.dart                     # Empty state illustration when no games active
│       ├── game_header.dart                          # App bar header for live game screen
│       ├── game_history_detail_dialog.dart           # Detail view of a completed game from history
│       ├── game_player_status_chip.dart              # Player participation chip (Playing, Spectating)
│       ├── game_rule_detail_dialog.dart              # Explains pattern rules with preview grid
│       ├── game_timeline.dart                        # Visual timeline of game stages
│       ├── guest_spectator_section.dart              # Banner for guest users prompting registration
│       ├── history_cartela_detail_dialog.dart        # Shows full board of past played cartela
│       ├── house_champions_list.dart                 # List view of top winners
│       ├── latest_call_pulse.dart                    # Large pulsing ball showing the latest call
│       ├── leave_live_game_dialog.dart               # Confirmation dialog before leaving active game
│       ├── live_cartela_card.dart                    # Primary playing card widget with interactive dabber
│       ├── live_game_status_widgets.dart             # Status chips (Ready, Playing, Winner Window)
│       ├── live_next_round_registration_section.dart # Quick-register panel for next round
│       ├── live_registered_cartela_list.dart         # Horizontal pager of all player's cards
│       ├── live_status_chip.dart                     # Animated pulse chip indicating live connection
│       ├── missed_live_game_preview.dart             # Catch-up overlay for late-joining players
│       ├── realtime_branding_overlay.dart            # Watermark branding behind live game board
│       ├── registration_action_dock.dart             # Bottom docked bar with Register Button & Total Cost
│       ├── registration_cartela_grid.dart            # Grid view of all 100/200/500 cartela numbers
│       ├── registration_grid_scroll_isolation.dart   # Isolates scroll gestures in dense grid
│       ├── registration_open_pulse.dart              # Animated glow when registration opens
│       ├── registration_tap_hint.dart                # Subtle tutorial hint explaining how to pick cards
│       ├── removable_cartela_number_chip.dart        # Chip with 'X' to unselect a chosen card
│       ├── round_finished_banner.dart                # Banner indicating current round has ended
│       ├── rule_pattern_preview_grid.dart            # 5x5 mini grid showing winning pattern targets
│       ├── winner_cartela_dialog.dart                # Pop-up showing the winning cartela & player name
│       ├── winner_cartela_number_strip.dart          # Horizontal strip of winning cartela numbers
│       ├── winner_window_countdown.dart              # 15s countdown ring for submitting simultaneous claims
│       └── winning_pattern_cartela_grid.dart         # Full board highlighting the winning completed line
```

#### C. Wallet Feature (`lib/src/features/wallet/`)
```
features/wallet/
├── data/
│   ├── telebirr_receipt_preview_service.dart         # Previews and parses Telebirr SMS & transaction codes
│   ├── wallet_repository.dart                        # API calls for wallet balance, deposits, withdrawals
│   └── models/
│       ├── deposit_config_model.dart                 # Active payment accounts (Telebirr & CBE account numbers)
│       ├── deposit_model.dart                        # Deposit record (amount, provider, reference, status)
│       ├── deposit_reference_check_result.dart       # Pre-validation result of transaction reference
│       ├── payment_provider.dart                     # Enum: TELEBIRR, CBE, AWASH, BOA
│       ├── pending_deposit_verification.dart         # Active asynchronous verification attempt
│       ├── telebirr_client_receipt_payload.dart      # Client-parsed receipt payload
│       ├── telebirr_receipt_preview.dart             # Parsed Telebirr receipt preview model
│       ├── wallet_model.dart                         # Player wallet (balance, bonus, locked, active bets)
│       ├── wallet_transaction_model.dart             # Transaction ledger entry
│       └── withdrawal_model.dart                     # Withdrawal record (amount, fee, provider, status)
├── domain/
│   ├── wallet_amount_limits.dart                     # Min/max limits, step values, currency formatting
│   └── wallet_balance_math.dart                      # Balance math and deduction calculations
├── presentation/
│   ├── controllers/
│   │   ├── deposit_controller.dart                   # Manages smart/manual deposit submission state
│   │   └── withdraw_controller.dart                  # Manages withdrawal request submission state
│   ├── debug/
│   │   └── telebirr_deposit_debug.dart               # Debug logging tool for Telebirr deposit payloads
│   ├── guides/
│   │   └── deposit_guide_config.dart                 # Step-by-step instructions for paying via Telebirr & CBE
│   ├── models/
│   │   ├── deposit_confirmation_state.dart           # Confirmation modal state
│   │   ├── deposit_state.dart                        # Deposit form state (mode, provider, amount, reference)
│   │   ├── withdrawal_confirmation_state.dart        # Withdrawal confirmation modal state
│   │   └── withdraw_state.dart                       # Withdrawal form state (amount, provider, receiver)
│   ├── providers/
│   │   ├── deposit_config_provider.dart              # Provides active settlement accounts
│   │   ├── wallet_history_providers.dart             # Deposit, withdrawal, and transaction history providers
│   │   └── wallet_provider.dart                      # Primary wallet balance provider
│   ├── screens/
│   │   ├── deposit_history_screen.dart               # List of user's past deposit attempts
│   │   ├── deposit_screen.dart                       # Main deposit screen (Smart SMS Paste vs Manual)
│   │   ├── wallet_screen.dart                        # Wallet overview with Balance Cards & Quick Actions
│   │   ├── wallet_transactions_screen.dart           # Detailed financial transaction ledger
│   │   ├── withdraw_history_screen.dart              # List of user's past withdrawal requests
│   │   └── withdraw_screen.dart                      # Withdrawal request submission form
│   ├── utils/
│   │   ├── cbe_manual_receipt_reference.dart         # Extracts CBE reference from manual input
│   │   ├── cbe_smart_deposit_parser.dart             # Regex parser for CBE mobile banking SMS messages
│   │   ├── deposit_receipt_code.dart                 # Validates reference code formats
│   │   ├── deposit_submission_preparer.dart          # Normalizes payloads before sending to backend
│   │   ├── smart_deposit_parse_result.dart           # Outcome of SMS auto-parsing (amount, ref, sender)
│   │   ├── telebirr_smart_deposit_parser.dart        # High-accuracy regex parser for Telebirr SMS messages
│   │   ├── wallet_validation_utils.dart              # Validates amount, phone match, CBE 1000... numbers
│   │   └── youtube_video_id.dart                     # Helper extracting tutorial video IDs
│   └── widgets/
│       ├── deposit_confirmation_banner.dart          # Success confirmation banner
│       ├── deposit_form_section.dart                 # Amount input and settlement account display
│       ├── deposit_guide_steps.dart                  # Visual accordion guide explaining how to transfer
│       ├── deposit_manual_section.dart               # Manual reference code and amount entry inputs
│       ├── deposit_provider_chips.dart               # Provider selector chips (Telebirr vs CBE)
│       ├── deposit_settlement_account_card.dart      # Copyable admin account numbers with copy button
│       ├── deposit_smart_feedback.dart               # Realtime feedback indicating parsed SMS values
│       ├── deposit_smart_section.dart                # One-click paste SMS input box
│       ├── deposit_status_card.dart                  # Card showing status of ongoing verification
│       ├── wallet_balance_card.dart                  # Gold card showing playable balance and cash out button
│       ├── wallet_breakdown_card.dart                # Breakdown of real money vs bonus cartela balance
│       ├── wallet_review_status_icon.dart            # Status icon (Pending clock, Approved check, Rejected X)
│       ├── wallet_state_card.dart                    # Quick glance wallet status widget
│       ├── welcome_bonus_banner.dart                 # Promotional banner for new registered users
│       ├── withdrawal_confirmation_banner.dart       # Withdrawal request placed banner
│       ├── withdrawal_requests_table.dart            # Table of pending and completed withdrawals
│       ├── withdraw_balance_strip.dart               # Strip showing available balance for withdrawal
│       ├── withdraw_confirm_dialog.dart              # Final review dialog before debiting wallet
│       ├── withdraw_form_section.dart                # Amount and destination account input fields
│       └── withdraw_provider_chips.dart              # Payout provider selector chips
```

#### D. Home, Profile, Messages, Settings, Support, Shared
```
features/
├── home/
│   └── presentation/
│       ├── screens/
│       │   ├── dashboard_screen.dart                 # Home dashboard screen with game slots & announcements
│       │   └── home_shell_screen.dart                # Persistent bottom navigation shell (Games, Home, Wallet, Profile)
│       └── widgets/
│           └── app_shell_app_bar.dart                # Custom app bar with wallet balance & settings drawer trigger
├── profile/
│   ├── domain/
│   │   └── avatar_preset.dart                        # Predefined avatar asset models
│   └── presentation/
│       ├── providers/
│       │   └── profile_avatar_provider.dart          # Selected user avatar provider
│       ├── screens/
│       │   └── profile_screen.dart                   # Profile details, phone number, security options, logout
│       └── widgets/
│           └── profile_avatar.dart                   # Stylized avatar circle with border
├── messages/
│   ├── data/
│   │   ├── models/
│   │   │   └── admin_broadcast_model.dart            # System broadcast notice entity
│   │   └── repositories/
│   │       └── broadcasts_repository.dart            # Fetches active broadcasts from `/notifications/broadcasts`
│   └── presentation/
│       ├── providers/
│       │   ├── broadcast_banner_provider.dart        # Controls active top banner message
│       │   └── broadcasts_provider.dart              # Active broadcast list provider
│       └── widgets/
│           ├── admin_messages_modal.dart             # Modal listing all system messages
│           ├── broadcast_message_ui.dart             # Formatted message card with priority badges
│           ├── broadcast_realtime_sync.dart          # Listens to `broadcast:new` and `broadcast:dismiss`
│           ├── broadcast_top_banner.dart             # Dismissible marquee/banner at screen top
│           └── forced_broadcast_overlay.dart         # Urgent fullscreen message requiring acknowledgment
├── settings/
│   ├── data/
│   │   └── feature_settings_repository.dart          # Persists user settings (auto-mark, auto-bingo) to backend
│   ├── domain/
│   │   └── feature_settings.dart                     # User feature grants model
│   └── presentation/
│       ├── providers/
│       │   ├── feature_settings_provider.dart        # Feature settings state notifier
│       │   ├── first_launch_preferences_provider.dart# Tracks whether first-launch onboarding was completed
│       │   ├── locale_provider.dart                  # Active locale notifier (en, am, om, ti)
│       │   └── theme_mode_provider.dart              # Theme mode notifier (System, Dark, Light)
│       ├── screens/
│       │   └── first_launch_preferences_screen.dart  # Language and theme selection on first open
│       └── widgets/
│           ├── app_settings_drawer.dart              # Hamburger drawer containing preferences, rules, terms
│           ├── drawer_app_version_card.dart          # Displays installed app version and build number
│           ├── drawer_preferences_card.dart          # In-drawer toggles for sounds, auto-mark, language
│           ├── drawer_preference_icons.dart          # Stylized icon containers for settings items
│           ├── feature_settings_realtime_sync.dart   # Realtime sync for admin-granted features
│           ├── first_launch_preferences_gate.dart    # Redirects new users to setup screen on first boot
│           ├── language_picker_sheet.dart            # Modal bottom sheet for switching language
│           ├── language_placeholder_sheet.dart       # Placeholder for upcoming languages
│           ├── terms_conditions_dialog.dart          # Legal terms and rules modal
│           └── theme_mode_menu_button.dart           # Dropdown or segmented button for theme toggle
├── support/
│   ├── data/
│   │   ├── models/
│   │   │   └── support_message_model.dart            # Customer ticket entity
│   │   └── repositories/
│   │       └── support_repository.dart               # HTTP calls for ticket submit, list, and unread counts
│   └── presentation/
│       ├── providers/
│       │   ├── support_messages_provider.dart        # Player support tickets provider
│       │   └── support_unread_provider.dart          # Unread support messages counter provider
│       ├── screens/
│       │   ├── contact_us_screen.dart                # Contact information, phone, and direct Telegram links
│       │   └── my_feedback_screen.dart               # Ticket history and chat-like reply view
│       └── widgets/
│           ├── send_feedback_form.dart               # Form for submitting feedback or complaints
│           ├── support_feedback_modals.dart          # Success confirmation dialogs
│           ├── support_message_tile.dart             # Message bubble showing user text and admin reply
│           └── support_realtime_sync.dart            # Listens to `support:new_message` socket event
└── shared/
    └── presentation/
        ├── screens/
        │   └── splash_screen.dart                    # Initial loading screen with version checking
        └── widgets/
            └── branding_splash_view.dart             # Glowing logo animation during startup
```

---

## 3. State Management Architecture (Riverpod 3)

The application uses **Riverpod 3** exclusively, avoiding global singletons or mutable inherited widgets.

### Pattern Classification

1. **StateNotifiers & Notifiers (Business Logic & Mutations)**:
   - `AuthController` (`authControllerProvider`): Manages user credentials, token refresh cycles, and authentication status.
   - `DepositController` (`depositControllerProvider`): Manages form inputs, smart paste parsing, and API submission for deposits.
   - `WithdrawController` (`withdrawControllerProvider`): Manages withdrawal amount validation, recipient checks, and submission.
   - `PlayerCartelasNotifier` (`playerCartelasNotifierProvider`): Holds registered cartelas, tracks active marked numbers, and preserves marked cells across round breaks.
   - `CalledBallsNotifier` (`calledBallsNotifierProvider`): Receives real-time numbers, enforces monotonic sequence integrity, and drives visual roll animations.

2. **Coordinators (Multi-Event Orchestration)**:
   - `LiveBingoClaimCoordinator`: Decouples button UI from claim network delays, handling optimistic claim locks, server verification responses, and multi-winner split dialogs.
   - `LiveChainGameCoordinator`: Controls multi-round lifecycle in Chain Games, carrying over cartelas and displaying inter-round countdowns.
   - `LiveResumeSyncCoordinator`: Detects when app returns from background or recovers from bad networks, safely triggering reconciliations without race conditions.
   - `LiveWinnerCelebrationCoordinator`: Drives celebratory animations (confetti, sounds, winner boards) upon game completion.

3. **Data Providers (`FutureProvider` / `StreamProvider`)**:
   - `walletProvider`: Asynchronously loads and caches wallet balance.
   - `gamesProviders`: Provides game catalog, active slots, and session details.
   - `cartelaCatalogProvider`: Paginates through 100/200/500 cartelas catalog.
   - `houseChampionsProvider`: Fetches leaderboard statistics.

4. **Synchronous Selectors (`Provider`)**:
   - `hasActiveRegisteredCartelasProvider`: Fast boolean selector checking if the logged-in user owns registered cartelas in the current session.
   - `registrationCartelaGridSummaryProvider`: Computes count of selected cards and total ETB fee.

---

## 4. Validation Architecture

Validation is implemented across three strict layers:

### A. Presentation Form Validation (`auth_validators.dart`, `wallet_validation_utils.dart`)
- **Phone Numbers**: Must be 10–15 digits matching Ethiopian telecommunications patterns (`validatePhoneNumber`).
- **Passwords**: Minimum 6 characters required (`validatePassword`).
- **Full Name**: Minimum 3 characters, no numeric characters allowed (`validateFullName`).
- **CBE Accounts**: Must be numeric only and begin with `1000` (`WalletValidationUtils.validateReceiver`).
- **Telebirr Accounts**: Must match valid phone digits (`WalletValidationUtils.validateReceiver`).
- **Withdrawal Amounts**: Must be positive numbers between `WalletAmountLimits.minWithdraw` and `WalletAmountLimits.maxWithdraw`, not exceeding `availableBalance`.

### B. Smart Text / SMS Parsers
- `TelebirrSmartDepositParser`: Regex parser extracting transaction amount, transaction ID, date, and sender phone from Telebirr SMS receipts.
- `CbeSmartDepositParser`: Regex parser extracting CBE transaction reference, amount, and debtor/creditor info from Commercial Bank of Ethiopia SMS messages.
- `DepositSubmissionPreparer`: Validates that parsed references meet length and alphanumeric criteria before dispatching network verification requests.

### C. Game Rule & Claim Invariant Validation
- `BingoClaimEligibility`: Pre-submission check verifying that the game status is `PLAYING` or `WINNER_WINDOW`, at least 5 balls have been called, and no claim is already checking.
- `CartelaMarkedPatternEvaluator`: Client-side pattern checker validating whether marked cells on a 5x5 board fulfill the active game rule (Full House, Horizontal, Vertical, Diagonal, Shape).
- `CartelaSelectionCap`: Enforces maximum allowed cartelas per player per session.

---

## 5. Navigation & Routing (GoRouter)

Defined in [`lib/src/core/routing/app_router.dart`](lib/src/core/routing/app_router.dart):

### Route Map
```
/loading                                       # SplashScreen (initial bootstrap & update check)
/login                                         # LoginScreen
/register                                      # RegisterScreen
/forgot-password                               # ForgotPasswordScreen
/auth/telegram-phone                           # TelegramPhoneLinkScreen
/support/contact                               # ContactUsScreen
/support/my-feedback                           # MyFeedbackScreen

StatefulShellRoute.indexedStack (Persistent bottom navigation shell)
├── Branch 0: /games                           # LiveGameScreen (Session gameplay)
│   ├── /games/history                         # GameHistoryScreen
│   └── /games/big-game                        # BigGameScreen (Daily Big Bingo)
├── Branch 1: /home                            # DashboardScreen (Slots list & news)
│   └── /home/champions                        # HouseChampionsScreen (Leaderboards)
├── Branch 2: /wallet                          # WalletScreen (Balances & quick links)
│   ├── /wallet/deposit                        # DepositScreen (Smart SMS & Manual)
│   ├── /wallet/deposits                       # DepositHistoryScreen
│   ├── /wallet/withdraw                       # WithdrawScreen
│   ├── /wallet/withdrawals                    # WithdrawHistoryScreen
│   └── /wallet/transactions                   # WalletTransactionsScreen
└── Branch 3: /profile                         # ProfileScreen (Preferences & account)
```

### Route Guards & Redirection
- **Force Update Guard**: If backend reports mandatory update required, app locks on `/loading` showing non-dismissible `AppUpdateDialog`.
- **Auth Guard**: Unauthenticated access to protected routes (`/wallet/*`, `/profile`) automatically redirects to `/login?redirect=<target>` while preserving back-stack.
- **Guest Access**: Guest players can freely view `/games`, `/home`, `/games/history`, and `/home/champions` as spectators.

---

## 6. Realtime WebSocket & Synchronization Architecture

- **Technology**: Socket.IO client connecting to backend namespace `/realtime` on path `/socket.io`.
- **Authentication**: JWT token passed via `auth: { token: 'Bearer ...' }` handshake.
- **Room Subscriptions**:
  - `games:public`: Global game status and countdown updates.
  - `session:<sessionId>`: Active game room receiving called balls, claim alerts, and winner announcements.
  - `user:<userId>`: Private channel for personal wallet updates, deposit status changes, and account bans.
- **Batched Updates**: Handles high-frequency `game:cartelas:updated` batches cleanly using `SocketPayloadNormalizer` to prevent UI stutter.
- **Monotonic Sequence Guard**: `LiveCalledNumberMonotonic` drops duplicate or retrogressive ball calls caused by packet jitter.
- **Lifecycle Reconnection**: When mobile app resumes (`AppLifecycleState.resumed`), `AppResumeSync` reconciles server clock, re-fetches game operations, and updates wallet balances.

---

## 7. Local Storage & Caching Layer

1. **FlutterSecureStorage (`SecureTokenStorage`)**:
   - Access Token (`jwt_token`)
   - Refresh Token (`refresh_token`)
2. **SharedPreferences (`AppPreferencesStorage`)**:
   - Selected Locale (`app_locale`: `en`, `am`, `om`, `ti`)
   - Theme Mode (`theme_mode`: `system`, `dark`, `light`)
   - Sound FX volume & mute state
   - Dismissed announcements and Big Game banners
   - First launch onboarding flag
3. **Local In-Memory & File Caches**:
   - `CartelaMarksStorage`: Persists marked cells locally so network dropouts do not erase player marks.
   - `BingoClaimAttemptStorage`: Caches claim attempt receipts to prevent double-submissions.

---

## 8. Device Security & Hardware Control

- **Screen Awake Management (`ScreenAwakeController`, `ScreenAwakeService`)**:
  - Uses `WakelockPlus` to keep phone screen awake while user is actively viewing a live bingo game.
  - Automatically releases wakelock when app is backgrounded or when user returns to dashboard.
- **Device Security Gate (`AndroidDeviceSecurity`, `DeviceSecurityGate`)**:
  - Detects if device is rooted, running inside an unauthorized emulator, or has active debugging hooks in production release builds.
  - Displays a security blocker preventing execution if device integrity checks fail.

---

## 9. Localization (i18n) & Theming

- **Localization**: Uses official Flutter `intl` & ARB generation.
  - Four fully supported languages: **Amharic** (`am`), **English** (`en`), **Afaan Oromo** (`om`), and **Tigrinya** (`ti`).
  - Access via clean extension: `context.l10n.someStringKey`.
- **Theming**:
  - Dark Mode & Light Mode support via `AppTheme`.
  - Brand Palette: Deep Charcoal / Slate backgrounds (`#0B0F19`), Royal Gold accents (`#FFD700`, `#E5A910`), Emerald Green wins (`#10B981`), and Crisp White typography.
  - Custom responsive layout tokens in `AppSpacing`.
