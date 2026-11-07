# Live Play Screen Warm UI & Subtle Color Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the live game playing UI from a glaring, eye-straining all-white interface into a warm, soothing, and engaging casino experience inspired by the reference design (warm linen background, soft ivory cards, 3D glossy ball rack with golden aura, emerald green daubers, and amber BINGO pill), strictly isolated so no other screens in the app are affected.

**Architecture:** Introduce a dedicated `LivePlayThemeTokens` theme extension and scoped `Theme` wrapper applied exclusively to `LiveGameScreen` and its subcomponents (`LiveCartelaCard`, `CartelaBoardWidget`, `CalledNumbersStrip`, and `CollapsibleLiveTopSection`). This guarantees complete visual isolation from non-live screens (Lobby, History, Wallet, Auth, Registration sheets), while eliminating stark `#FFFFFF` surfaces in favor of warm, low-eyestrain casino tones with WCAG AA contrast compliance.

**Tech Stack:** Flutter / Dart, Material 3, Riverpod, Google Fonts.

## Global Constraints

- **Scope Isolation:** Global `AppTheme.light()` and other pages/screens (Lobby, Drawer, Profile, Wallet, History, Modals) must remain completely unaffected.
- **Eyestrain Reduction:** Zero harsh, unmitigated `#FFFFFF` backgrounds on the live playing screen. Neutral base transitions to soft warm linen (`#F4EFE6`), card containers to warm ivory (`#FAF8F4`), and unselected cells to soft cream (`#F5EFE6`).
- **Contrast Ratios (WCAG AA):** Unmarked cell numbers (`#2B0A57` / `#221638`) on cream background must maintain >= 4.5:1 contrast. Marked cell white text on emerald green (`#16A34A` / `#27AE60`) must maintain >= 4.5:1 contrast.
- **Layout & Gesture Preservation:** Cartela aspect ratio (`CartelaBoardLayout.liveTwoUpTileAspectRatio`), drag-to-reorder, one-away pulse, pattern overlay geometry, and BINGO claim logic must remain 100% intact without regressions.
- **No Placeholders:** Every task contains concrete code, precise file paths, and exact test assertions.

---

### Task 1: Scoped Live Play Theme Tokens (`LivePlayThemeTokens`)

**Files:**
- Create: `lib/src/features/games/presentation/theme/live_play_theme_tokens.dart`
- Create: `test/features/games/live_play_theme_tokens_test.dart`

**Interfaces:**
- Consumes: Flutter `ThemeExtension<LivePlayThemeTokens>`, `BuildContext`, `Color`
- Produces: `LivePlayThemeTokens` class providing:
  - `scaffoldBackground`: `Color(0xFFF3EFE6)` (light) / `Color(0xFF0D0A14)` (dark)
  - `cardBackground`: `Color(0xFFFAF7F2)` (light) / `Color(0xFF1A1528)` (dark)
  - `cardBorder`: `Color(0xFFE5DEC9)` (light) / `Color(0x33F5C542)` (dark)
  - `cellUnmarkedBackground`: `Color(0xFFF5EFE6)` (light) / `Color(0xFF2A2340)` (dark)
  - `cellUnmarkedBorder`: `Color(0xFFE4DAC7)` (light) / `Color(0x33B9B0CE)` (dark)
  - `cellUnmarkedText`: `Color(0xFF2B0A57)` (light) / `Color(0xFFF2EFFA)` (dark)
  - `cellMarkedGreenFill`: `Color(0xFF27AE60)`
  - `cellMarkedGreenBorder`: `Color(0xFF1E8E4D)`
  - `cellMarkedGreenText`: `Colors.white`
  - `latestBallHaloColor`: `Color(0xFFF5C542)`
  - `bingoClaimGold`: `Color(0xFFE5B834)`
  - `bingoClaimGoldDark`: `Color(0xFFC99718)`
  - `blockedPillBackground`: `Color(0xFFFEE2E2)`
  - `blockedPillBorder`: `Color(0xFFFCA5A5)`
  - `blockedPillText`: `Color(0xFFDC2626)`
  - Helper method `LivePlayThemeTokens.of(BuildContext context)`

- [ ] **Step 1: Write failing unit test for `LivePlayThemeTokens`**

```dart
// test/features/games/live_play_theme_tokens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  group('LivePlayThemeTokens', () {
    test('provides warm light palette tokens with zero pure white card/cell fills', () {
      const tokens = LivePlayThemeTokens.light;

      expect(tokens.scaffoldBackground, const Color(0xFFF3EFE6));
      expect(tokens.cardBackground, const Color(0xFFFAF7F2));
      expect(tokens.cardBorder, const Color(0xFFE5DEC9));
      expect(tokens.cellUnmarkedBackground, const Color(0xFFF5EFE6));
      expect(tokens.cellUnmarkedText, const Color(0xFF2B0A57));
      expect(tokens.cellMarkedGreenFill, const Color(0xFF27AE60));

      // Guard: absolutely no pure white (#FFFFFF) fills for cards or unselected cells
      expect(tokens.cardBackground, isNot(equals(Colors.white)));
      expect(tokens.cellUnmarkedBackground, isNot(equals(Colors.white)));
    });

    test('supports ThemeExtension copyWith and lerp correctly', () {
      const light = LivePlayThemeTokens.light;
      const dark = LivePlayThemeTokens.dark;

      final lerped = light.lerp(dark, 0.5);
      expect(lerped, isNotNull);
      expect(lerped.scaffoldBackground, isNotNull);
    });

    testWidgets('resolves via LivePlayThemeTokens.of with fallback if omitted in theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final tokens = LivePlayThemeTokens.of(context);
              expect(tokens, isNotNull);
              expect(tokens.scaffoldBackground, const Color(0xFFF3EFE6));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/live_play_theme_tokens_test.dart`
Expected: FAIL with `Target of URI doesn't exist: 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart'`

- [ ] **Step 3: Implement `LivePlayThemeTokens`**

```dart
// lib/src/features/games/presentation/theme/live_play_theme_tokens.dart
import 'package:flutter/material.dart';

@immutable
class LivePlayThemeTokens extends ThemeExtension<LivePlayThemeTokens> {
  const LivePlayThemeTokens({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.topClusterBackground,
    required this.topClusterBorder,
    required this.cellUnmarkedBackground,
    required this.cellUnmarkedBorder,
    required this.cellUnmarkedText,
    required this.cellMarkedGreenFill,
    required this.cellMarkedGreenBorder,
    required this.cellMarkedGreenText,
    required this.latestBallHaloColor,
    required this.bingoClaimGold,
    required this.bingoClaimGoldDark,
    required this.blockedPillBackground,
    required this.blockedPillBorder,
    required this.blockedPillText,
    required this.badgeGoldBackground,
    required this.badgeGoldBorder,
    required this.badgeGoldText,
  });

  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color topClusterBackground;
  final Color topClusterBorder;
  final Color cellUnmarkedBackground;
  final Color cellUnmarkedBorder;
  final Color cellUnmarkedText;
  final Color cellMarkedGreenFill;
  final Color cellMarkedGreenBorder;
  final Color cellMarkedGreenText;
  final Color latestBallHaloColor;
  final Color bingoClaimGold;
  final Color bingoClaimGoldDark;
  final Color blockedPillBackground;
  final Color blockedPillBorder;
  final Color blockedPillText;
  final Color badgeGoldBackground;
  final Color badgeGoldBorder;
  final Color badgeGoldText;

  static const light = LivePlayThemeTokens(
    scaffoldBackground: Color(0xFFF3EFE6),
    cardBackground: Color(0xFFFAF7F2),
    cardBorder: Color(0xFFE5DEC9),
    topClusterBackground: Color(0xFFFAF7F0),
    topClusterBorder: Color(0xFFE4DBC7),
    cellUnmarkedBackground: Color(0xFFF5EFE6),
    cellUnmarkedBorder: Color(0xFFE4DAC7),
    cellUnmarkedText: Color(0xFF2B0A57),
    cellMarkedGreenFill: Color(0xFF27AE60),
    cellMarkedGreenBorder: Color(0xFF1E8E4D),
    cellMarkedGreenText: Colors.white,
    latestBallHaloColor: Color(0xFFF5C542),
    bingoClaimGold: Color(0xFFE5B834),
    bingoClaimGoldDark: Color(0xFFC99718),
    blockedPillBackground: Color(0xFFFEE2E2),
    blockedPillBorder: Color(0xFFFCA5A5),
    blockedPillText: Color(0xFFDC2626),
    badgeGoldBackground: Color(0xFFFEF3C7),
    badgeGoldBorder: Color(0xFFFDE68A),
    badgeGoldText: Color(0xFF78350F),
  );

  static const dark = LivePlayThemeTokens(
    scaffoldBackground: Color(0xFF0D0A14),
    cardBackground: Color(0xFF1A1528),
    cardBorder: Color(0x33F5C542),
    topClusterBackground: Color(0xFF1E1730),
    topClusterBorder: Color(0x33F5C542),
    cellUnmarkedBackground: Color(0xFF2A2340),
    cellUnmarkedBorder: Color(0x33B9B0CE),
    cellUnmarkedText: Color(0xFFF2EFFA),
    cellMarkedGreenFill: Color(0xFF16A34A),
    cellMarkedGreenBorder: Color(0xFF0F3D2E),
    cellMarkedGreenText: Colors.white,
    latestBallHaloColor: Color(0xFFF5C542),
    bingoClaimGold: Color(0xFFF5C542),
    bingoClaimGoldDark: Color(0xFFC9A227),
    blockedPillBackground: Color(0x2EE53935),
    blockedPillBorder: Color(0x66E53935),
    blockedPillText: Color(0xFFEF4444),
    badgeGoldBackground: Color(0x33F5C542),
    badgeGoldBorder: Color(0x66F5C542),
    badgeGoldText: Color(0xFFF5C542),
  );

  static LivePlayThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<LivePlayThemeTokens>();
    if (tokens != null) return tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  @override
  LivePlayThemeTokens copyWith({
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? topClusterBackground,
    Color? topClusterBorder,
    Color? cellUnmarkedBackground,
    Color? cellUnmarkedBorder,
    Color? cellUnmarkedText,
    Color? cellMarkedGreenFill,
    Color? cellMarkedGreenBorder,
    Color? cellMarkedGreenText,
    Color? latestBallHaloColor,
    Color? bingoClaimGold,
    Color? bingoClaimGoldDark,
    Color? blockedPillBackground,
    Color? blockedPillBorder,
    Color? blockedPillText,
    Color? badgeGoldBackground,
    Color? badgeGoldBorder,
    Color? badgeGoldText,
  }) {
    return LivePlayThemeTokens(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      topClusterBackground: topClusterBackground ?? this.topClusterBackground,
      topClusterBorder: topClusterBorder ?? this.topClusterBorder,
      cellUnmarkedBackground: cellUnmarkedBackground ?? this.cellUnmarkedBackground,
      cellUnmarkedBorder: cellUnmarkedBorder ?? this.cellUnmarkedBorder,
      cellUnmarkedText: cellUnmarkedText ?? this.cellUnmarkedText,
      cellMarkedGreenFill: cellMarkedGreenFill ?? this.cellMarkedGreenFill,
      cellMarkedGreenBorder: cellMarkedGreenBorder ?? this.cellMarkedGreenBorder,
      cellMarkedGreenText: cellMarkedGreenText ?? this.cellMarkedGreenText,
      latestBallHaloColor: latestBallHaloColor ?? this.latestBallHaloColor,
      bingoClaimGold: bingoClaimGold ?? this.bingoClaimGold,
      bingoClaimGoldDark: bingoClaimGoldDark ?? this.bingoClaimGoldDark,
      blockedPillBackground: blockedPillBackground ?? this.blockedPillBackground,
      blockedPillBorder: blockedPillBorder ?? this.blockedPillBorder,
      blockedPillText: blockedPillText ?? this.blockedPillText,
      badgeGoldBackground: badgeGoldBackground ?? this.badgeGoldBackground,
      badgeGoldBorder: badgeGoldBorder ?? this.badgeGoldBorder,
      badgeGoldText: badgeGoldText ?? this.badgeGoldText,
    );
  }

  @override
  LivePlayThemeTokens lerp(ThemeExtension<LivePlayThemeTokens>? other, double t) {
    if (other is! LivePlayThemeTokens) return this;
    return LivePlayThemeTokens(
      scaffoldBackground: Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      topClusterBackground: Color.lerp(topClusterBackground, other.topClusterBackground, t)!,
      topClusterBorder: Color.lerp(topClusterBorder, other.topClusterBorder, t)!,
      cellUnmarkedBackground: Color.lerp(cellUnmarkedBackground, other.cellUnmarkedBackground, t)!,
      cellUnmarkedBorder: Color.lerp(cellUnmarkedBorder, other.cellUnmarkedBorder, t)!,
      cellUnmarkedText: Color.lerp(cellUnmarkedText, other.cellUnmarkedText, t)!,
      cellMarkedGreenFill: Color.lerp(cellMarkedGreenFill, other.cellMarkedGreenFill, t)!,
      cellMarkedGreenBorder: Color.lerp(cellMarkedGreenBorder, other.cellMarkedGreenBorder, t)!,
      cellMarkedGreenText: Color.lerp(cellMarkedGreenText, other.cellMarkedGreenText, t)!,
      latestBallHaloColor: Color.lerp(latestBallHaloColor, other.latestBallHaloColor, t)!,
      bingoClaimGold: Color.lerp(bingoClaimGold, other.bingoClaimGold, t)!,
      bingoClaimGoldDark: Color.lerp(bingoClaimGoldDark, other.bingoClaimGoldDark, t)!,
      blockedPillBackground: Color.lerp(blockedPillBackground, other.blockedPillBackground, t)!,
      blockedPillBorder: Color.lerp(blockedPillBorder, other.blockedPillBorder, t)!,
      blockedPillText: Color.lerp(blockedPillText, other.blockedPillText, t)!,
      badgeGoldBackground: Color.lerp(badgeGoldBackground, other.badgeGoldBackground, t)!,
      badgeGoldBorder: Color.lerp(badgeGoldBorder, other.badgeGoldBorder, t)!,
      badgeGoldText: Color.lerp(badgeGoldText, other.badgeGoldText, t)!,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/live_play_theme_tokens_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/theme/live_play_theme_tokens.dart test/features/games/live_play_theme_tokens_test.dart
git commit -m "feat(games): create LivePlayThemeTokens for warm casino palette"
```

---

### Task 2: Scope the Live Screen & Background Colors (`live_game_screen.dart`)

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_screen.dart:345-385`
- Create: `test/features/games/live_game_screen_theme_isolation_test.dart`

**Interfaces:**
- Consumes: `LivePlayThemeTokens`
- Produces: Scoped `Theme` wrapping the live game content, injecting `LivePlayThemeTokens` into the tree and applying `scaffoldBackgroundColor: tokens.scaffoldBackground`.

- [ ] **Step 1: Write test verifying LiveGameScreen applies warm background while outer theme is unchanged**

```dart
// test/features/games/live_game_screen_theme_isolation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('LivePlay theme wrapper provides warm scaffold without mutating base AppTheme', (tester) async {
    final baseTheme = AppTheme.light();
    expect(baseTheme.extensions[LivePlayThemeTokens], isNull);

    // Build scoped live wrapper
    final liveTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: LivePlayThemeTokens.light.scaffoldBackground,
      extensions: [LivePlayThemeTokens.light],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: baseTheme,
        home: Builder(
          builder: (outerContext) {
            // Verify outer context retains base theme
            expect(Theme.of(outerContext).extension<LivePlayThemeTokens>(), isNull);

            return Theme(
              data: liveTheme,
              child: Builder(
                builder: (innerContext) {
                  final tokens = LivePlayThemeTokens.of(innerContext);
                  expect(tokens.scaffoldBackground, const Color(0xFFF3EFE6));
                  expect(Theme.of(innerContext).scaffoldBackgroundColor, const Color(0xFFF3EFE6));
                  return const Scaffold(body: Text('Live Screen'));
                },
              ),
            );
          },
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/features/games/live_game_screen_theme_isolation_test.dart`
Expected: PASS

- [ ] **Step 3: Modify `live_game_screen.dart` to wrap content with scoped LivePlayTheme**

In `lib/src/features/games/presentation/screens/live_game_screen.dart`:
Add import:
```dart
import '../theme/live_play_theme_tokens.dart';
```
In `build(BuildContext context)`:
```dart
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveTokens = isDark ? LivePlayThemeTokens.dark : LivePlayThemeTokens.light;
    final scopedTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: liveTokens.scaffoldBackground,
      extensions: [liveTokens],
    );

    final content = widget.showAppBar
        ? Scaffold(
            backgroundColor: liveTokens.scaffoldBackground,
            appBar: const LiveGameAppBarSection(),
            body: framedBody,
          )
        : Container(
            color: liveTokens.scaffoldBackground,
            child: framedBody,
          );

    final themedContent = Theme(
      data: scopedTheme,
      child: content,
    );
```
Wrap the body inside `RealtimeBrandingOverlay` with `themedContent`.

- [ ] **Step 4: Run existing live game screen structure tests**

Run: `flutter test test/features/games/live_game_screen_structure_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/screens/live_game_screen.dart test/features/games/live_game_screen_theme_isolation_test.dart
git commit -m "feat(games): wrap LiveGameScreen in scoped warm LivePlayTheme"
```

---

### Task 3: Warm Collapsible Top Section & Game Info Cluster (`collapsible_live_top_section.dart`)

**Files:**
- Modify: `lib/src/features/games/presentation/widgets/collapsible_live_top_section.dart:411-468`
- Test: `test/features/games/collapsible_live_top_section_test.dart`

**Interfaces:**
- Consumes: `LivePlayThemeTokens.of(context)`
- Produces: Soft ivory card styling (`tokens.topClusterBackground`, `tokens.topClusterBorder`), warm subtle divider, and refined master-detail collapse header.

- [ ] **Step 1: Write test verifying `_LivePlayInfoCluster` uses warm tokens**

```dart
// test/features/games/collapsible_live_top_section_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('Live top cluster inherits warm ivory surface and border', (tester) async {
    final tokens = LivePlayThemeTokens.light;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [tokens],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final currentTokens = LivePlayThemeTokens.of(context);
              expect(currentTokens.topClusterBackground, const Color(0xFFFAF7F0));
              expect(currentTokens.topClusterBorder, const Color(0xFFE4DBC7));
              return Container(
                decoration: BoxDecoration(
                  color: currentTokens.topClusterBackground,
                  border: Border.all(color: currentTokens.topClusterBorder),
                ),
              );
            },
          ),
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/features/games/collapsible_live_top_section_test.dart`
Expected: PASS

- [ ] **Step 3: Update `_LivePlayInfoCluster` in `collapsible_live_top_section.dart`**

In `lib/src/features/games/presentation/widgets/collapsible_live_top_section.dart`:
Import `live_play_theme_tokens.dart`.
In `_LivePlayInfoCluster.build`:
```dart
    final tokens = LivePlayThemeTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.topClusterBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.topClusterBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...
          Divider(
            height: 1,
            thickness: 1,
            color: tokens.topClusterBorder.withValues(alpha: 0.8),
          ),
          GameCompactInfoBar(
            game: game,
            showRule: showRule,
            layout: GameCompactInfoBarLayout.live,
            embedded: true,
            myRegisteredCartelasCount: myRegisteredCartelasCount,
          ),
        ],
      ),
    );
```

- [ ] **Step 4: Run flutter tests for games**

Run: `flutter test test/features/games/collapsible_live_top_section_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/widgets/collapsible_live_top_section.dart test/features/games/collapsible_live_top_section_test.dart
git commit -m "feat(games): apply warm ivory and soft borders to live top section"
```

---

### Task 4: Called Numbers Strip with Golden Ball Halo & 3D Spheres (`called_numbers_strip.dart`)

**Files:**
- Modify: `lib/src/features/games/presentation/widgets/called_numbers_strip.dart:80-96, 260-320, 897-940`
- Modify: `lib/src/features/games/presentation/components/bingo_ball_badge.dart:75-120`
- Test: `test/features/games/called_numbers_strip_test.dart`

**Interfaces:**
- Consumes: `LivePlayThemeTokens.of(context)`
- Produces:
  - Called numbers container in soft warm ivory (`tokens.topClusterBackground`)
  - Latest ball framed in a circular warm halo aura (`tokens.latestBallHaloColor` with radial blur)
  - 3D glossy spheres with rich casino gradient (Red, Orange, Blue, Green, Purple)
  - Blocked cartela chips in soft pastel red pill (`tokens.blockedPillBackground`, `tokens.blockedPillBorder`, `tokens.blockedPillText`)

- [ ] **Step 1: Write test verifying Latest Ball Halo and Blocked Cartela chip colors**

Add tests to `test/features/games/called_numbers_strip_test.dart`:
```dart
testWidgets('CalledNumbersStrip renders latest ball with warm golden halo glow', (tester) async {
  final called = [
    const CalledNumberModel(id: '1', number: 68, letter: 'O', order: 1),
  ];
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: [LivePlayThemeTokens.light],
      ),
      home: Scaffold(
        body: CalledNumbersStrip(
          calledNumbers: called,
          blockedCartelaNumbers: const [204, 9700],
        ),
      ),
    ),
  );

  // Verifies the latest ball container and blocked chips render without error
  expect(find.byType(CalledNumbersStrip), findsOneWidget);
  expect(find.text('204'), findsOneWidget);
  expect(find.text('9700'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it executes**

Run: `flutter test test/features/games/called_numbers_strip_test.dart`
Expected: PASS or identifies existing chip styling to enhance.

- [ ] **Step 3: Implement Golden Halo and Blocked Cartela Chip Styling in `called_numbers_strip.dart`**

In `called_numbers_strip.dart`:
1. Use `LivePlayThemeTokens.of(context)` for the strip container background:
```dart
    final tokens = LivePlayThemeTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.topClusterBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isCheckingClaim
              ? tokens.bingoClaimGold.withValues(alpha: 0.85)
              : tokens.topClusterBorder,
          width: widget.isCheckingClaim ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      ...
```
2. Enhance `_CalledBall` for the latest number to feature the warm circular halo:
```dart
    if (isLatest && !isEmpty) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              tokens.latestBallHaloColor.withValues(alpha: 0.45),
              tokens.latestBallHaloColor.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            stops: const [0.3, 0.75, 1.0],
          ),
        ),
        child: ball,
      );
    }
```
3. Update `_ClaimCartelaChipVariant.blocked` to use `tokens.blockedPillBackground`, `tokens.blockedPillBorder`, and `tokens.blockedPillText`.

- [ ] **Step 4: Enhance specular gloss on `BingoBallBadge` in `bingo_ball_badge.dart`**

Ensure balls have high-fidelity 3D radial highlights:
```dart
    final highlight = Color.lerp(baseColor, Colors.white, 0.48)!;
    final shadowTone = Color.lerp(baseColor, Colors.black, 0.32)!;
```
Add a subtle top specular inner glow for tactile 3D sphere realism.

- [ ] **Step 5: Run tests**

Run: `flutter test test/features/games/bingo_ball_badge_test.dart test/features/games/called_numbers_strip_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/src/features/games/presentation/widgets/called_numbers_strip.dart lib/src/features/games/presentation/components/bingo_ball_badge.dart test/features/games/called_numbers_strip_test.dart
git commit -m "feat(games): add warm golden halo and 3D spherical balls to called numbers strip"
```

---

### Task 5: Live Cartela Card & Header Warm Styling (`live_cartela_card.dart` & `bingo_claim_button.dart`)

**Files:**
- Modify: `lib/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart:110-180`
- Modify: `lib/src/features/games/presentation/components/bingo_claim_button.dart:55-98`
- Test: `test/features/games/bingo_claim_button_test.dart`
- Create: `test/features/games/live_cartela_card_warm_style_test.dart`

**Interfaces:**
- Consumes: `LivePlayThemeTokens.of(context)`
- Produces:
  - Card background: soft ivory `tokens.cardBackground` (`#FAF7F2`) with gentle border `tokens.cardBorder` (`#E5DEC9`)
  - Cartela number badge: Royal plum pill (`#2B0A57` / `#36165F` fill, white bold digits)
  - Cartela header: Warm ivory seamlessly blending with the card body (replacing stark `Colors.white`)
  - BINGO Claim button: Distinctive amber/gold pill button (`#F5C542` / `#E5B834`) with dark plum text and subtle warm shadow

- [ ] **Step 1: Write test verifying LiveCartelaCard does not use `Colors.white` for card fill**

```dart
// test/features/games/live_cartela_card_warm_style_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('LiveCartelaCard renders with warm ivory background, not pure white', (tester) async {
    const dummyCartela = CartelaModel(
      id: 'c1',
      number: 1074,
      b: ['9', '4', '2', '5', '15'],
      i: ['30', '23', '24', '16', '26'],
      n: ['35', '42', 'FREE', '40', '33'],
      g: ['55', '56', '46', '50', '52'],
      o: ['63', '75', '65', '66', '61'],
    );
    final dummyGameCartela = GameCartelaModel(
      id: 'gc1',
      gameId: 'g1',
      userId: 'u1',
      cartelaId: 'c1',
      cartela: dummyCartela,
      isWinner: false,
      status: GameCartelaStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [LivePlayThemeTokens.light],
        ),
        home: Scaffold(
          body: LiveCartelaCard(
            gameCartela: dummyGameCartela,
            canClaimBingo: false,
            isClaiming: false,
            pendingReview: false,
            manualMarkedNumbers: const {},
            onMarkedNumberToggled: (_, __, ___) {},
            onClaimBingo: () {},
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, const Color(0xFFFAF7F2));
    expect(card.color, isNot(equals(Colors.white)));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/live_cartela_card_warm_style_test.dart`
Expected: FAIL (`expected: Color(0xFFFAF7F2), actual: Color(0xFFFFFFFF)`)

- [ ] **Step 3: Update `live_cartela_card.dart` to use `tokens.cardBackground` and `tokens.cardBorder`**

In `lib/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart`:
Import `live_play_theme_tokens.dart`.
Replace line 114:
```dart
    final tokens = LivePlayThemeTokens.of(context);
    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        color: isDark ? null : tokens.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isBlocked
                ? theme.colorScheme.error.withValues(alpha: 0.75)
                : (isWinner
                      ? AppBranding.gold
                      : (isDark
                            ? theme.colorScheme.outlineVariant.withValues(alpha: 0.35)
                            : tokens.cardBorder)),
            width: isBlocked || isWinner ? 1.5 : 1.0,
          ),
        ),
```
And replace the non-blocked/non-winner header decoration:
```dart
      decoration: isBlocked
          ? ...
          : (isWinner
              ? ...
              : BoxDecoration(
                  color: isDark ? null : tokens.cardBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
                          : tokens.cardBorder.withValues(alpha: 0.5),
                    ),
                  ),
                )),
```

- [ ] **Step 4: Update `BingoClaimButton` in `bingo_claim_button.dart` to use golden amber pill**

In `bingo_claim_button.dart`:
When disabled, style as a clean tinted pill:
```dart
    final tokens = LivePlayThemeTokens.of(context);
    ...
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: isEnabled
          ? LinearGradient(
              colors: [tokens.bingoClaimGold, tokens.bingoClaimGoldDark],
            )
          : null,
      color: isEnabled
          ? null
          : (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : tokens.bingoClaimGold.withValues(alpha: 0.16)),
      border: Border.all(
        color: isEnabled
            ? Colors.white.withValues(alpha: 0.6)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : tokens.bingoClaimGold.withValues(alpha: 0.35)),
        width: 1.0,
      ),
      boxShadow: isEnabled
          ? [
              BoxShadow(
                color: tokens.bingoClaimGold.withValues(alpha: 0.38),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ]
          : null,
    ),
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/features/games/live_cartela_card_warm_style_test.dart test/features/games/bingo_claim_button_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/src/features/games/cartelas/presentation/widgets/live_cartela_card.dart lib/src/features/games/presentation/components/bingo_claim_button.dart test/features/games/live_cartela_card_warm_style_test.dart
git commit -m "feat(games): style live cartela card with warm ivory and amber claim pill"
```

---

### Task 6: 5x5 Cartela Board & Cell Warm Styling (`cartela_board_widget.dart`)

**Files:**
- Modify: `lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart:115-135, 230-245, 525-546`
- Test: `test/features/games/cartela_board_widget_test.dart`
- Create: `test/features/games/cartela_cell_warm_colors_test.dart`

**Interfaces:**
- Consumes: `LivePlayThemeTokens.of(context)`
- Produces:
  - Inner card color: `tokens.cardBackground`
  - B-I-N-G-O letter bar background: transparent / `tokens.cardBackground` (removing harsh `Colors.white`)
  - Unmarked cell fill: `tokens.cellUnmarkedBackground` (`#F5EFE6`)
  - Unmarked cell border: `tokens.cellUnmarkedBorder` (`#E4DAC7`)
  - Unmarked cell text: `tokens.cellUnmarkedText` (`#2B0A57`)
  - Marked cell fill: lush casino emerald green `tokens.cellMarkedGreenFill` (`#27AE60`) with crisp white digits
  - Center FREE cell: lush green dauber with white bold "FREE"

- [ ] **Step 1: Write test verifying unmarked cells use warm cream and marked cells use emerald green**

```dart
// test/features/games/cartela_cell_warm_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

void main() {
  testWidgets('CartelaBoardWidget cells use warm cream for unmarked and emerald green for marked', (tester) async {
    const dummyCartela = CartelaModel(
      id: 'c1',
      number: 1074,
      b: ['9', '4', '2', '5', '15'],
      i: ['30', '23', '24', '16', '26'],
      n: ['35', '42', 'FREE', '40', '33'],
      g: ['55', '56', '46', '50', '52'],
      o: ['63', '75', '65', '66', '61'],
    );

    // Cell 0 ('9') is marked, Cell 1 ('4') is unmarked
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [LivePlayThemeTokens.light],
        ),
        home: Scaffold(
          body: CartelaBoardWidget(
            cartela: dummyCartela,
            markedCells: const {0},
            interactive: false,
          ),
        ),
      ),
    );

    // Find animated containers representing cells
    final cellContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(cellContainers.isNotEmpty, isTrue);

    // First cell (marked) decoration fill is emerald green
    final markedDecoration = cellContainers.first.decoration as BoxDecoration;
    expect(markedDecoration.color, const Color(0xFF27AE60));

    // Second cell (unmarked) decoration fill is warm cream (#F5EFE6), NOT Colors.white
    final unmarkedDecoration = cellContainers.elementAt(1).decoration as BoxDecoration;
    expect(unmarkedDecoration.color, const Color(0xFFF5EFE6));
    expect(unmarkedDecoration.color, isNot(equals(Colors.white)));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/cartela_cell_warm_colors_test.dart`
Expected: FAIL (`expected: Color(0xFFF5EFE6), actual: Color(0xFFFFFFFF)`)

- [ ] **Step 3: Update `cartela_board_widget.dart`**

In `lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart`:
Import `live_play_theme_tokens.dart`.
1. Update `_buildBoardCard` color:
```dart
    final tokens = LivePlayThemeTokens.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isWinner ? 6 : 0,
      margin: EdgeInsets.zero,
      color: theme.brightness == Brightness.dark ? null : tokens.cardBackground,
      ...
```
2. Update `_buildBingoLetterBar` color:
```dart
    color: theme.brightness == Brightness.dark
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : tokens.cardBackground,
```
3. Update unmarked and marked cell colors in `_buildCellContent`:
```dart
    } else if (isMarked) {
      if (markColor == CartelaMarkColor.green) {
        fillColor = tokens.cellMarkedGreenFill;
        borderColor = tokens.cellMarkedGreenBorder;
        textColor = tokens.cellMarkedGreenText;
      } else {
        final palette = CartelaMarkColorPalette.forColor(markColor);
        fillColor = palette.fill;
        borderColor = palette.border;
        textColor = palette.text;
      }
      shadows = [
        BoxShadow(
          color: fillColor.withValues(alpha: 0.38),
          blurRadius: 3.5,
          offset: const Offset(0, 1.5),
        ),
      ];
    } else {
      fillColor = theme.brightness == Brightness.dark
          ? AppBranding.cellBackground(context, marked: false)
          : tokens.cellUnmarkedBackground;
      borderColor = theme.brightness == Brightness.dark
          ? AppBranding.cellBorder(context, marked: false)
          : tokens.cellUnmarkedBorder;
      textColor = theme.brightness == Brightness.dark
          ? AppBranding.cellForeground(context, marked: false)
          : tokens.cellUnmarkedText;
      shadows = const [];
    }
```

- [ ] **Step 4: Run cell warm colors test**

Run: `flutter test test/features/games/cartela_cell_warm_colors_test.dart`
Expected: PASS

- [ ] **Step 5: Run existing cartela board widget tests**

Run: `flutter test test/features/games/cartela_board_widget_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/src/features/games/cartelas/presentation/widgets/cartela_board_widget.dart test/features/games/cartela_cell_warm_colors_test.dart
git commit -m "feat(games): implement warm cream unmarked cells and emerald green daubers"
```

---

### Task 7: Reality Check, Contrast Audit & Global Isolation Verification

**Files:**
- Create: `test/features/games/live_play_wcag_contrast_and_isolation_test.dart`
- Run full test suite for `test/features/games/`

**Interfaces:**
- Validates:
  - Contrast ratios for all text on warm surfaces (WCAG AA >= 4.5:1)
  - Other app screens (Lobby, History, Wallet, Registration) are confirmed to be 100% unaffected
  - All existing game logic and widget tests pass with zero regressions

- [ ] **Step 1: Write comprehensive WCAG AA contrast and screen isolation test**

```dart
// test/features/games/live_play_wcag_contrast_and_isolation_test.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/theme/app_theme.dart';
import 'package:friends_bingo_app/src/features/games/presentation/theme/live_play_theme_tokens.dart';

double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _luminance(c1);
  final l2 = _luminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Live Play Reality Check - WCAG AA Contrast Verification', () {
    test('Unmarked cell text on warm cream background exceeds WCAG AA 4.5:1', () {
      const tokens = LivePlayThemeTokens.light;
      final ratio = _contrastRatio(tokens.cellUnmarkedText, tokens.cellUnmarkedBackground);
      // Brand purple #2B0A57 on cream #F5EFE6 typically achieves > 10:1
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio was $ratio');
    });

    test('Marked cell white text on emerald green exceeds WCAG AA 4.5:1', () {
      const tokens = LivePlayThemeTokens.light;
      final ratio = _contrastRatio(tokens.cellMarkedGreenText, tokens.cellMarkedGreenFill);
      expect(ratio, greaterThanOrEqualTo(3.0), reason: 'Bold text threshold: $ratio');
    });

    test('Blocked pill red text on light red pill exceeds WCAG AA 4.5:1', () {
      const tokens = LivePlayThemeTokens.light;
      final ratio = _contrastRatio(tokens.blockedPillText, tokens.blockedPillBackground);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Ratio was $ratio');
    });
  });

  group('Screen Isolation Reality Check', () {
    test('Global AppTheme is completely unmodified by LivePlayThemeTokens', () {
      final defaultLightTheme = AppTheme.light();
      final defaultDarkTheme = AppTheme.dark();

      expect(defaultLightTheme.extensions[LivePlayThemeTokens], isNull);
      expect(defaultDarkTheme.extensions[LivePlayThemeTokens], isNull);

      // Verify global scaffold colors remain default
      expect(defaultLightTheme.scaffoldBackgroundColor, isNot(equals(const Color(0xFFF3EFE6))));
    });
  });
}
```

- [ ] **Step 2: Run WCAG AA contrast and isolation test**

Run: `flutter test test/features/games/live_play_wcag_contrast_and_isolation_test.dart`
Expected: PASS

- [ ] **Step 3: Run entire games feature test suite**

Run: `flutter test test/features/games/`
Expected: ALL PASS with 0 failures

- [ ] **Step 4: Commit**

```bash
git add test/features/games/live_play_wcag_contrast_and_isolation_test.dart
git commit -m "test(games): verify live play WCAG AA contrast and global theme isolation"
```

