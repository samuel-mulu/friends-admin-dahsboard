# Friends Bingo Production Readiness Audit

Date: 2026-06-24

## Scope

This workspace contains the Flutter app only. No NestJS API or admin dashboard
 project was present in this repository during the audit.

## APK Size Snapshot

Baseline before cleanup:

- `app-release.apk` from `flutter build apk --release --target-platform android-arm64 --analyze-size`: 53.7 MB
- `app-arm64-v8a-release.apk` from `flutter build apk --release --split-per-abi`: 35.9 MB
- `app-armeabi-v7a-release.apk` from `flutter build apk --release --split-per-abi`: 29.8 MB

Current after cleanup:

- `app-release.apk` from `flutter build apk --release --target-platform android-arm64 --analyze-size --dart-define=API_BASE_URL=... --dart-define=SOCKET_URL=...`: 51.8 MB
- `app-arm64-v8a-release.apk` from `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info --dart-define=API_BASE_URL=... --dart-define=SOCKET_URL=...`: 32.6 MB
- `app-armeabi-v7a-release.apk` from the same split build: 26.2 MB
- `app-x86_64-release.apk` from the same split build: 34.6 MB

Recommended distribution target:

- Prefer `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Avoid shipping the universal APK when modern Android devices are the target

## Largest Contributors

From the latest `--analyze-size` snapshot:

- Native libs dominate size
  - `lib/arm64-v8a`: about 30 MB
  - `lib/x86_64`: about 11 MB
  - `lib/armeabi-v7a`: about 7 MB
- Largest Dart/package contributors
  - `package:flutter`: about 3 MB
  - `package:friends_bingo_app`: about 1 MB
  - `package:html`: about 229 KB
  - `package:flutter_localizations`: about 206 KB
  - `package:riverpod`: about 120 KB
  - `package:go_router`: about 89 KB
  - `package:socket_io_client`: about 76 KB
  - `package:dio`: about 49 KB

From APK contents:

- Largest native libraries
  - `libflutter.so`
  - `libmlkit_google_ocr_pipeline.so`
  - `libapp.so`
- Largest asset groups
  - ML Kit OCR models under `assets/mlkit-google-ocr-models`
  - Deposit guide images under `assets/flutter_assets/assets/deposit_guides`

## Cleanup Applied

- Added `AppLogger` for centralized debug-only logging
- Removed sensitive values from auth and Telebirr debug traces
  - no full phone numbers
  - no raw transaction refs
  - no raw receipt preview payloads
  - no raw deposit identifiers in logs
- Added release-time config guard so release builds cannot silently point at
  localhost defaults when `API_BASE_URL` is missing or still local
- Removed unused direct dev dependency on `riverpod`
- Converted nine deposit guide screenshots from PNG to WebP
  - asset footprint reduced from about 2270 KB to about 316 KB
  - about 86.1% reduction
- Updated asset tests and a live cartela widget test signature to match the
  current codebase

## Remaining Risks

- Release signing still uses the debug signing config in
  `android/app/build.gradle.kts`
  - this must be replaced with a real release keystore before production
- `google_mlkit_text_recognition` is still a major APK contributor
  - keep only if receipt scanning is a release requirement
- `flutter analyze` still reports pre-existing warnings in unrelated files
- `flutter test` still has unrelated failing tests in the current branch
  - examples observed during the run:
    - `test/cartela_number_chip_test.dart`
    - `test/cartela_pattern_progress_overlay_test.dart`
    - `test/mobile_auth_flow_test.dart`

## Verification Run

Successful:

- `flutter pub get`
- `flutter build apk --release --target-platform android-arm64 --analyze-size --dart-define=API_BASE_URL=https://friendsbingo.onrender.com --dart-define=SOCKET_URL=https://friendsbingo.onrender.com`
- `flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info --dart-define=API_BASE_URL=https://friendsbingo.onrender.com --dart-define=SOCKET_URL=https://friendsbingo.onrender.com`
- `flutter test test/telebirr_guide_assets_test.dart test/telebirr_receipt_preview_service_test.dart test/live_cartela_card_claim_test.dart`

Needs follow-up:

- `flutter analyze` returns warnings in unrelated files
- `flutter test` fails in unrelated existing tests in the current branch
