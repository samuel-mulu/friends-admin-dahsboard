# Mobile CI/CD Build Guide: Android & iOS Workflows

This document explains the automated GitHub Actions workflows set up for **Friends Bingo Mobile**, allowing you to build installable packages for both Android (`.apk`) and iOS (`.ipa`).

---

## 1. Workflows Overview

The builds have been separated into two independent workflows:

| Workflow | File | Runner | Output | Primary Use |
| :--- | :--- | :--- | :--- | :--- |
| **Build Android APK** | [`.github/workflows/build-android.yml`](file:///.github/workflows/build-android.yml) | `ubuntu-latest` | `friends-bingo-*-release.apk` | Sideload directly to any Android device or publish to store |
| **Build iOS App** | [`.github/workflows/build-ios.yml`](file:///.github/workflows/build-ios.yml) | `macos-14` | `friends-bingo-*-release.ipa` | Install on iPhone/iPad via AltStore, Sideloadly, or Ad-Hoc/TestFlight |

### Why separate workflows?
1. **Runner Cost & Quota**: Android builds run on standard Linux runners (fast & free on public repos), whereas iOS builds run on macOS runners. Separating them saves GitHub Actions compute minutes.
2. **Independent Triggers**: You can build Android without waiting on iOS, and vice versa.
3. **Targeted Failure Isolation**: If an iOS CocoaPod requires attention, it will not block Android testing or deployment.

---

## 2. Compile-Time Configuration (`--dart-define`)

Both workflows inject the exact production flags specified in the project configuration:

```bash
--dart-define=API_BASE_URL=https://friendsbingo.onrender.com \
--dart-define=SOCKET_URL=https://friendsbingo.onrender.com \
--dart-define=DEBUG=false \
--dart-define=REALTIME_DEBUG=false \
--dart-define=CHAIN_DEBUG=false \
--dart-define=BIG_GAME_DEBUG=false \
--dart-define=TELEBIRR_DEPOSIT_DEBUG=false
```

When triggering manually through **Run workflow**, each flag is provided as an input with these production URLs and flags set as defaults. You can override any URL or debug flag on the fly before launching the build.

---

## 3. How to Trigger Builds

### Option A: Manual Trigger (Recommended for On-Demand Builds)
1. Go to your GitHub repository: `https://github.com/samuel-mulu/friends-admin-dahsboard`
2. Click on the **Actions** tab at the top.
3. In the left sidebar, choose either:
   - **Build Android APK**
   - **Build iOS App**
4. Click the **Run workflow** dropdown button on the right.
5. (Optional) Adjust the `API_BASE_URL` or toggle `create_github_release`.
6. Click **Run workflow**.

### Option B: Automatic Push Trigger
- Pushing commits to `main` or `master` triggers both builds.
- Pushing a version tag (e.g. `git tag v1.0.5 && git push origin v1.0.5`) triggers the build and automatically attaches the `.apk` and `.ipa` files to a new **GitHub Release**!

---

## 4. Downloading the Built Artifacts

1. Go to the **Actions** tab on GitHub.
2. Click on the completed workflow run.
3. Scroll down to the **Artifacts** section at the bottom of the summary page.
4. Download the zip archive:
   - Android: `friends-bingo-android-v1.0.4_5.zip` (extracts to `.apk`)
   - iOS: `friends-bingo-ios-v1.0.4_5.zip` (extracts to `.ipa`)

---

## 5. How to Install on Devices

### Android (`.apk`)
1. Send the `friends-bingo-*-release.apk` to the phone (via Telegram, WhatsApp, Google Drive, or USB).
2. Tap the APK file to install.
3. If prompted with *"Install unknown apps"*, tap **Settings** and enable permission for the app doing the installation (e.g. Chrome or Files).
4. Tap **Install**.

> **Note on Signing**: Out of the box, `android/app/build.gradle.kts` signs release builds with the debug keystore when no `key.properties` is present. This means the APK is **immediately installable** on any Android device without needing a paid developer account.

### iOS (`.ipa`)
Because iOS restricts sideloading without App Store certificates:
- **Zero-Config Installation (Without Paid Apple Developer Account)**:
  - Download [Sideloadly](https://sideloadly.io/) or [AltStore](https://altstore.io/) on your PC or Mac.
  - Connect your iPhone via USB.
  - Drag and drop `friends-bingo-*-release.ipa` into Sideloadly or AltStore to install directly onto your device with your free Apple ID!
- **With Apple Developer Account**:
  - Configure the repository secrets below to produce a signed Ad-Hoc / TestFlight build.

---

## 6. Optional: Setting Up Production Signing Secrets

To produce officially signed builds for Google Play or Apple App Store / TestFlight, add the following secrets in **GitHub Repo > Settings > Secrets and variables > Actions**:

### Android Secrets (For Play Store / Official Upload Key):
- `ANDROID_KEYSTORE_BASE64`: Base64 string of your `.jks` file (`base64 -w 0 upload-keystore.jks` or `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))` in PowerShell)
- `KEY_ALIAS`: Your keystore alias (e.g. `upload`)
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password

### iOS Secrets (For Apple Developer Certificate Signing):
- `BUILD_CERTIFICATE_BASE64`: Base64 string of your Apple Distribution or Development certificate `.p12` file
- `P12_PASSWORD`: The password for the `.p12` certificate
- `BUILD_PROVISION_PROFILE_BASE64`: Base64 string of your provisioning profile (`.mobileprovision`)
- `KEYCHAIN_PASSWORD`: Any temporary string to secure the runner keychain
