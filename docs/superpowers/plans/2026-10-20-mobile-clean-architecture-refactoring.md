# Mobile Clean Architecture & Component Reusability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the mobile application (`friends-bingo-mobile`) into a feature/domain-driven clean code architecture with pure reusable presentation components, an immutable unidirectional Riverpod state machine, and resolution of all known build blockers, without modifying the backend.

**Architecture:** Deconstruct the 10,000+ line God Component (`LiveGameScreen` and its 5 part-files) into pure standalone presentation widgets (`CartelaBoardWidget`, `BingoBallBadge`, `CalledNumbersStrip`, `GameCountdownRing`), an immutable sealed state union (`LiveGameState`), and decoupled Riverpod Notifiers (`LiveGameSessionNotifier`, `CalledBallsNotifier`, `PlayerCartelasNotifier`, `RegistrationNotifier`).

**Tech Stack:** Flutter 3.x, Dart 3.x, Flutter Riverpod 3.x, Freezed, GoRouter, SharedPreferences, audioplayers.

## Global Constraints

- **Mobile Only:** Do NOT modify any file under `FriendsBingo-backend`.
- **Preserve Contracts:** Respect all existing REST schemas and Socket.IO event payloads (`game:number_called`, `game:status_changed`, `game:winner_window_started`, etc.).
- **Zero Impossible States:** The UI state machine must prevent simultaneous or contradictory UI phases (e.g. READY banner while PLAYING balls are visible).
- **Reusable Components:** Presentation widgets must have ZERO dependencies on `_LiveGameScreenState` or live game mixins.

---

## File Structure & Responsibility Map

```
lib/src/features/games/
├── domain/
│   ├── live_game_state.dart                 # Sealed state union (Loading, Ready, Playing, WinnerWindow, Finished, Cancelled)
│   └── models/                              # Existing domain models (GameModel, CartelaModel, etc.)
├── presentation/
│   ├── components/                          # 100% Reusable Presentation Widgets
│   │   ├── bingo_ball_badge.dart            # B-I-N-G-O ball with auto letter & colorway
│   │   ├── cartela_board_widget.dart        # Reusable 5x5 Grid (Live, Preview, History, Winner Dialog)
│   │   ├── called_numbers_strip.dart        # Auto-scrolling animated ball history
│   │   ├── game_countdown_ring.dart         # Circular/linear timer with audio integration
│   │   └── game_action_dock.dart            # Contextual floating action bar
│   ├── controllers/                         # Riverpod State Notifiers
│   │   ├── live_game_session_notifier.dart  # Session lifecycle & status transitions
│   │   ├── called_balls_notifier.dart       # Monotonic ball stream & animations
│   │   └── player_cartelas_notifier.dart    # Player cards, daubing, persistence & claims
│   └── screens/
│       └── live_game_screen.dart            # Refactored thin coordinator screen (< 400 lines)
test/features/games/
├── bingo_ball_badge_test.dart               # Tests for ball badge derivation & styling
├── cartela_board_widget_test.dart           # Tests for 5x5 board rendering & callbacks
├── called_numbers_strip_test.dart           # Tests for strip rendering & ordering
├── live_game_state_test.dart                # Tests for state machine transitions
└── live_game_notifiers_test.dart            # Tests for Riverpod notifiers
```

---

### Task 1: Environment Hygiene, Orphan Cleanup & Bank Option Enablement

**Files:**
- Modify: `lib/src/features/wallet/presentation/screens/deposit_screen.dart`
- Modify: `lib/src/features/games/presentation/utils/socket_payload_dartify_web.dart`
- Modify: `lib/src/features/games/data/games_repository.dart`
- Delete: `lib/src/features/gamess` (empty orphaned directory)
- Test: `test/features/wallet/deposit_screen_providers_test.dart`

**Interfaces:**
- Consumes: `PaymentProvider` enum (`TELEBIRR`, `CBE`, `AWASH`, `BOA`)
- Produces: Active provider selector supporting Awash Bank and Bank of Abyssinia alongside CBE and Telebirr; zero analyzer errors in Flutter toolchain.

- [x] **Step 1: Delete orphaned directory and fix analyzer error in `socket_payload_dartify_web.dart`**

Delete the empty vestigial directory `lib/src/features/gamess`. In `socket_payload_dartify_web.dart`, replace obsolete `dart:js_util` with modern `dart:js_interop` (or safe type guards) to eliminate the analyzer compilation error. In `games_repository.dart:223`, add missing `await` inside the try-catch block.

- [x] **Step 2: Write test verifying Awash and BOA are selectable in deposit options**

```dart
// test/features/wallet/deposit_screen_providers_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/screens/deposit_screen.dart';

void main() {
  testWidgets('Deposit screen renders Awash and BOA as active selectable providers', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DepositScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Awash Bank'), findsOneWidget);
    expect(find.text('Bank of Abyssinia'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNothing);
  });
}
```

- [x] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/wallet/deposit_screen_providers_test.dart`  
Expected: FAIL (Awash and BOA are currently marked "Coming Soon" or disabled).

- [x] **Step 4: Enable Awash and BOA in `deposit_screen.dart`**

Remove "Coming Soon" chips from Awash and BOA options, wire account number and deposit guide dialogs to match backend provider configs.

- [x] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/wallet/deposit_screen_providers_test.dart`  
Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add lib/src/features/wallet/presentation/screens/deposit_screen.dart test/features/wallet/deposit_screen_providers_test.dart
git commit -m "fix(wallet): enable Awash and BOA deposit options and remove orphaned gamess directory"
```

---

### Task 2: Standalone Reusable `BingoBallBadge`

**Files:**
- Create: `lib/src/features/games/presentation/components/bingo_ball_badge.dart`
- Test: `test/features/games/bingo_ball_badge_test.dart`

**Interfaces:**
- Consumes: `number: int` (1–75), optional `size: double`, `isLatest: bool`, `animated: bool`
- Produces: `BingoBallBadge` widget deriving letter (`B`, `I`, `N`, `G`, `O`) and standard colorway.

- [x] **Step 1: Write the failing test for `BingoBallBadge`**

```dart
// test/features/games/bingo_ball_badge_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/bingo_ball_badge.dart';

void main() {
  group('BingoBallBadge Tests', () {
    testWidgets('derives B for number 12 and applies correct label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BingoBallBadge(number: 12)),
        ),
      );
      expect(find.text('B'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('derives O for number 75', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BingoBallBadge(number: 75)),
        ),
      );
      expect(find.text('O'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    test('static helper derives correct letters and colors', () {
      expect(BingoBallBadge.getLetter(1), 'B');
      expect(BingoBallBadge.getLetter(15), 'B');
      expect(BingoBallBadge.getLetter(16), 'I');
      expect(BingoBallBadge.getLetter(30), 'I');
      expect(BingoBallBadge.getLetter(31), 'N');
      expect(BingoBallBadge.getLetter(45), 'N');
      expect(BingoBallBadge.getLetter(46), 'G');
      expect(BingoBallBadge.getLetter(60), 'G');
      expect(BingoBallBadge.getLetter(61), 'O');
      expect(BingoBallBadge.getLetter(75), 'O');
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/bingo_ball_badge_test.dart`  
Expected: FAIL (file does not exist).

- [x] **Step 3: Implement `BingoBallBadge`**

```dart
// lib/src/features/games/presentation/components/bingo_ball_badge.dart
import 'package:flutter/material.dart';

class BingoBallBadge extends StatelessWidget {
  const BingoBallBadge({
    super.key,
    required this.number,
    this.size = 44.0,
    this.isLatest = false,
    this.animated = true,
  });

  final int number;
  final double size;
  final bool isLatest;
  final bool animated;

  static String getLetter(int number) {
    if (number <= 15) return 'B';
    if (number <= 30) return 'I';
    if (number <= 45) return 'N';
    if (number <= 60) return 'G';
    return 'O';
  }

  static Color getColor(int number) {
    if (number <= 15) return const Color(0xFFE53935); // B - Red
    if (number <= 30) return const Color(0xFFFB8C00); // I - Orange
    if (number <= 45) return const Color(0xFF1E88E5); // N - Blue
    if (number <= 60) return const Color(0xFF43A047); // G - Green
    return const Color(0xFF8E24AA);                   // O - Purple
  }

  @override
  Widget build(BuildContext context) {
    final letter = getLetter(number);
    final baseColor = getColor(number);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            baseColor.withValues(alpha: 0.85),
            baseColor,
          ],
        ),
        boxShadow: [
          if (isLatest)
            BoxShadow(
              color: baseColor.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(
          color: isLatest ? Colors.white : Colors.white.withValues(alpha: 0.3),
          width: isLatest ? 2.0 : 1.0,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              letter,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
                fontSize: size * 0.24,
                height: 1.0,
              ),
            ),
            Text(
              number.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.36,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/bingo_ball_badge_test.dart`  
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/components/bingo_ball_badge.dart test/features/games/bingo_ball_badge_test.dart
git commit -m "feat(games): create standalone reusable BingoBallBadge component"
```

---

### Task 3: Standalone Reusable `CartelaBoardWidget`

**Files:**
- Create: `lib/src/features/games/presentation/components/cartela_board_widget.dart`
- Test: `test/features/games/cartela_board_widget_test.dart`

**Interfaces:**
- Consumes: `cartela: CartelaModel`, `markedCells: Set<int>`, optional `winningPatternCells: Set<int>?`, `isBlocked: bool`, `isWinner: bool`, `onCellTapped: Function(int)?`
- Produces: Completely decoupled, pure presentation 5x5 Bingo Board usable across Live Game, Catalog Preview, Review Sheet, Winner Dialog, and Game History.

- [x] **Step 1: Write the failing test for `CartelaBoardWidget`**

```dart
// test/features/games/cartela_board_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/cartela_board_widget.dart';

void main() {
  final sampleCartela = CartelaModel(
    id: 'test-cartela-1',
    number: 42,
    b: [1, 2, 3, 4, 5],
    i: [16, 17, 18, 19, 20],
    n: [31, 32, 0, 34, 35], // 0 is Free Space
    g: [46, 47, 48, 49, 50],
    o: [61, 62, 63, 64, 65],
  );

  testWidgets('CartelaBoardWidget renders B-I-N-G-O headers and numbers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaBoardWidget(
            cartela: sampleCartela,
            markedCells: const {1, 16},
          ),
        ),
      ),
    );

    expect(find.text('B'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    expect(find.text('42'), findsOneWidget); // Card header number
    expect(find.text('FREE'), findsOneWidget); // Center Free space
  });

  testWidgets('CartelaBoardWidget triggers onCellTapped callback on number tap', (tester) async {
    int? tappedNumber;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CartelaBoardWidget(
            cartela: sampleCartela,
            markedCells: const {},
            onCellTapped: (num) => tappedNumber = num,
          ),
        ),
      ),
    );

    await tester.tap(find.text('1'));
    expect(tappedNumber, 1);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/games/cartela_board_widget_test.dart`  
Expected: FAIL.

- [x] **Step 3: Implement `CartelaBoardWidget`**

```dart
// lib/src/features/games/presentation/components/cartela_board_widget.dart
import 'package:flutter/material.dart';
import '../../data/models/cartela_model.dart';
import 'bingo_ball_badge.dart';

enum CartelaBoardSize { compact, standard, large }

class CartelaBoardWidget extends StatelessWidget {
  const CartelaBoardWidget({
    super.key,
    required this.cartela,
    required this.markedCells,
    this.winningPatternCells,
    this.winningBallNumber,
    this.isBlocked = false,
    this.isWinner = false,
    this.interactive = true,
    this.onCellTapped,
    this.boardSize = CartelaBoardSize.standard,
    this.cardHeaderTrailing,
  });

  final CartelaModel cartela;
  final Set<int> markedCells;
  final Set<int>? winningPatternCells;
  final int? winningBallNumber;
  final bool isBlocked;
  final bool isWinner;
  final bool interactive;
  final void Function(int number)? onCellTapped;
  final CartelaBoardSize boardSize;
  final Widget? cardHeaderTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = [
      cartela.b,
      cartela.i,
      cartela.n,
      cartela.g,
      cartela.o,
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isWinner ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isWinner
              ? Colors.amber
              : isBlocked
                  ? Colors.red
                  : theme.dividerColor.withValues(alpha: 0.2),
          width: isWinner ? 2.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Cartela # and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.style_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '#${cartela.number}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (cardHeaderTrailing != null) cardHeaderTrailing!,
              ],
            ),
          ),
          // B-I-N-G-O Title Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: ['B', 'I', 'N', 'G', 'O'].map((letter) {
                return Expanded(
                  child: Center(
                    child: Text(
                      letter,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 5x5 Matrix
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: List.generate(5, (colIdx) {
                final colData = columns[colIdx];
                return Expanded(
                  child: Column(
                    children: List.generate(5, (rowIdx) {
                      final isFreeSpace = colIdx == 2 && rowIdx == 2;
                      final number = isFreeSpace ? 0 : colData[rowIdx];
                      final isMarked = isFreeSpace || markedCells.contains(number);
                      final isWinningCell = winningPatternCells?.contains(number) ?? false;
                      final isWinningBall = winningBallNumber != null && winningBallNumber == number;

                      return _buildCell(
                        context: context,
                        number: number,
                        isFreeSpace: isFreeSpace,
                        isMarked: isMarked,
                        isWinningCell: isWinningCell,
                        isWinningBall: isWinningBall,
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required int number,
    required bool isFreeSpace,
    required bool isMarked,
    required bool isWinningCell,
    required bool isWinningBall,
  }) {
    final theme = Theme.of(context);

    Color bgColor = Colors.transparent;
    Color textColor = theme.colorScheme.onSurface;

    if (isWinningBall) {
      bgColor = Colors.amber;
      textColor = Colors.black;
    } else if (isWinningCell) {
      bgColor = Colors.amber.withValues(alpha: 0.4);
      textColor = theme.colorScheme.primary;
    } else if (isMarked) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.85);
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: InkWell(
          onTap: (interactive && !isFreeSpace && onCellTapped != null)
              ? () => onCellTapped!(number)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWinningBall
                    ? Colors.orange
                    : isMarked
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.3),
                width: isWinningBall ? 2 : 1,
              ),
            ),
            child: Center(
              child: isFreeSpace
                  ? Text(
                      'FREE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Text(
                      number.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isMarked ? FontWeight.w900 : FontWeight.w600,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/games/cartela_board_widget_test.dart`  
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/src/features/games/presentation/components/cartela_board_widget.dart test/features/games/cartela_board_widget_test.dart
git commit -m "feat(games): implement standalone reusable CartelaBoardWidget"
```

---

### Task 4: Standalone Reusable `CalledNumbersStrip` & `GameCountdownRing`

**Files:**
- Create: `lib/src/features/games/presentation/components/called_numbers_strip.dart`
- Create: `lib/src/features/games/presentation/components/game_countdown_ring.dart`
- Test: `test/features/games/called_numbers_strip_test.dart`

**Interfaces:**
- Consumes: `calledNumbers: List<CalledNumberModel>`, `remaining: Duration`, `total: Duration`
- Produces: Auto-scrolling animated ball strip and circular/linear countdown with audio tick callbacks.

- [x] **Step 1: Write tests for `CalledNumbersStrip`**

```dart
// test/features/games/called_numbers_strip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/components/called_numbers_strip.dart';

void main() {
  testWidgets('CalledNumbersStrip renders all called numbers in reverse order', (tester) async {
    final balls = [
      const CalledNumberModel(id: '1', letter: 'B', number: 10, order: 1),
      const CalledNumberModel(id: '2', letter: 'I', number: 25, order: 2),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalledNumbersStrip(calledNumbers: balls),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
  });
}
```

- [x] **Step 2: Implement `CalledNumbersStrip` and `GameCountdownRing`**

```dart
// lib/src/features/games/presentation/components/called_numbers_strip.dart
import 'package:flutter/material.dart';
import '../../data/models/called_number_model.dart';
import 'bingo_ball_badge.dart';

class CalledNumbersStrip extends StatelessWidget {
  const CalledNumbersStrip({
    super.key,
    required this.calledNumbers,
    this.onBallTap,
    this.height = 64.0,
  });

  final List<CalledNumberModel> calledNumbers;
  final void Function(CalledNumberModel ball)? onBallTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (calledNumbers.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Waiting for first call...',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    final reversed = calledNumbers.reversed.toList();

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: reversed.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ball = reversed[index];
          final isLatest = index == 0;

          return GestureDetector(
            onTap: onBallTap != null ? () => onBallTap!(ball) : null,
            child: BingoBallBadge(
              number: ball.number,
              size: isLatest ? 48 : 40,
              isLatest: isLatest,
            ),
          );
        },
      ),
    );
  }
}
```

- [x] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/games/called_numbers_strip_test.dart`  
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/components/called_numbers_strip.dart lib/src/features/games/presentation/components/game_countdown_ring.dart test/features/games/called_numbers_strip_test.dart
git commit -m "feat(games): implement standalone CalledNumbersStrip and GameCountdownRing components"
```

---

### Task 5: Domain State Machine (`LiveGameState`)

**Files:**
- Create: `lib/src/features/games/domain/live_game_state.dart`
- Test: `test/features/games/live_game_state_test.dart`

**Interfaces:**
- Produces: Sealed union `LiveGameState` with variants `initial`, `loading`, `ready`, `playing`, `winnerWindow`, `finished`, `cancelled`, and `error`.

- [x] **Step 1: Write unit tests for `LiveGameState`**

```dart
// test/features/games/live_game_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/domain/live_game_state.dart';

void main() {
  test('LiveGameState handles status variants cleanly', () {
    const state = LiveGameState.initial();
    expect(state.isLoading, false);
    expect(state.isPlaying, false);

    const readyState = LiveGameState.ready(
      remainingSeconds: 60,
      registeredCount: 5,
    );
    expect(readyState.isReady, true);
    expect(readyState.isPlaying, false);
  });
}
```

- [x] **Step 2: Implement `LiveGameState`**

```dart
// lib/src/features/games/domain/live_game_state.dart
import '../data/models/called_number_model.dart';
import '../data/models/game_cartela_model.dart';
import '../data/models/game_model.dart';
import '../data/models/session_winner_result_model.dart';

sealed class LiveGameState {
  const LiveGameState();

  const factory LiveGameState.initial() = _Initial;
  const factory LiveGameState.loading() = _Loading;
  const factory LiveGameState.ready({
    GameModel? game,
    required int remainingSeconds,
    required int registeredCount,
  }) = LiveGameReadyState;
  const factory LiveGameState.playing({
    required GameModel game,
    required List<CalledNumberModel> calledNumbers,
    required List<GameCartelaModel> myCartelas,
    required Map<String, Set<int>> markedCellsByCartelaId,
    required bool isClaiming,
  }) = LiveGamePlayingState;
  const factory LiveGameState.winnerWindow({
    required GameModel game,
    required int windowSecondsRemaining,
    required List<String> winnerNames,
  }) = LiveGameWinnerWindowState;
  const factory LiveGameState.finished({
    required GameModel game,
    required SessionWinnerResultModel results,
  }) = LiveGameFinishedState;
  const factory LiveGameState.cancelled({
    required String reason,
  }) = LiveGameCancelledState;
  const factory LiveGameState.error(String message) = _Error;

  bool get isLoading => this is _Loading;
  bool get isReady => this is LiveGameReadyState;
  bool get isPlaying => this is LiveGamePlayingState;
  bool get isWinnerWindow => this is LiveGameWinnerWindowState;
  bool get isFinished => this is LiveGameFinishedState;
  bool get isCancelled => this is LiveGameCancelledState;
}

class _Initial extends LiveGameState {
  const _Initial();
}

class _Loading extends LiveGameState {
  const _Loading();
}

class LiveGameReadyState extends LiveGameState {
  const LiveGameReadyState({
    this.game,
    required this.remainingSeconds,
    required this.registeredCount,
  });
  final GameModel? game;
  final int remainingSeconds;
  final int registeredCount;
}

class LiveGamePlayingState extends LiveGameState {
  const LiveGamePlayingState({
    required this.game,
    required this.calledNumbers,
    required this.myCartelas,
    required this.markedCellsByCartelaId,
    required this.isClaiming,
  });
  final GameModel game;
  final List<CalledNumberModel> calledNumbers;
  final List<GameCartelaModel> myCartelas;
  final Map<String, Set<int>> markedCellsByCartelaId;
  final bool isClaiming;
}

class LiveGameWinnerWindowState extends LiveGameState {
  const LiveGameWinnerWindowState({
    required this.game,
    required this.windowSecondsRemaining,
    required this.winnerNames,
  });
  final GameModel game;
  final int windowSecondsRemaining;
  final List<String> winnerNames;
}

class LiveGameFinishedState extends LiveGameState {
  const LiveGameFinishedState({
    required this.game,
    required this.results,
  });
  final GameModel game;
  final SessionWinnerResultModel results;
}

class LiveGameCancelledState extends LiveGameState {
  const LiveGameCancelledState({
    required this.reason,
  });
  final String reason;
}

class _Error extends LiveGameState {
  const _Error(this.message);
  final String message;
}
```

- [x] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/games/live_game_state_test.dart`  
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/src/features/games/domain/live_game_state.dart test/features/games/live_game_state_test.dart
git commit -m "feat(games): implement sealed LiveGameState domain state machine"
```

---

### Task 6: Application Layer Riverpod Notifiers

**Files:**
- Create: `lib/src/features/games/presentation/controllers/called_balls_notifier.dart`
- Create: `lib/src/features/games/presentation/controllers/player_cartelas_notifier.dart`
- Test: `test/features/games/live_game_notifiers_test.dart`

**Interfaces:**
- `CalledBallsNotifier`: Manages incoming balls stream, guarantees monotonic draw order (`order > lastOrder`), triggers sound effects.
- `PlayerCartelasNotifier`: Manages active user cartelas, marked cells, auto-daub toggles, local persistence, and BINGO claim submissions.

- [x] **Step 1: Write unit tests for `CalledBallsNotifier` and `PlayerCartelasNotifier`**

```dart
// test/features/games/live_game_notifiers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';
import 'package:friends_bingo_app/src/features/games/presentation/controllers/called_balls_notifier.dart';

void main() {
  test('CalledBallsNotifier adds balls in monotonic sequence and ignores duplicates', () {
    final notifier = CalledBallsNotifier();
    expect(notifier.state, isEmpty);

    notifier.addBall(const CalledNumberModel(id: '1', letter: 'B', number: 5, order: 1));
    expect(notifier.state.length, 1);

    // Duplicate order ignored
    notifier.addBall(const CalledNumberModel(id: '2', letter: 'B', number: 5, order: 1));
    expect(notifier.state.length, 1);

    // Next monotonic ball added
    notifier.addBall(const CalledNumberModel(id: '3', letter: 'I', number: 20, order: 2));
    expect(notifier.state.length, 2);
  });
}
```

- [x] **Step 2: Implement `CalledBallsNotifier`**

```dart
// lib/src/features/games/presentation/controllers/called_balls_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/called_number_model.dart';

class CalledBallsNotifier extends Notifier<List<CalledNumberModel>> {
  @override
  List<CalledNumberModel> build() => [];

  void setInitialBalls(List<CalledNumberModel> balls) {
    final sorted = List<CalledNumberModel>.from(balls)
      ..sort((a, b) => a.order.compareTo(b.order));
    state = sorted;
  }

  void addBall(CalledNumberModel ball) {
    if (state.any((b) => b.order == ball.order || b.number == ball.number)) {
      return;
    }
    state = [...state, ball];
  }

  void clear() {
    state = [];
  }
}

final calledBallsNotifierProvider =
    NotifierProvider<CalledBallsNotifier, List<CalledNumberModel>>(
  CalledBallsNotifier.new,
);
```

- [x] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/games/live_game_notifiers_test.dart`  
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/controllers/called_balls_notifier.dart test/features/games/live_game_notifiers_test.dart
git commit -m "feat(games): implement Riverpod CalledBallsNotifier with monotonic sequence protection"
```

---

### Task 7: Coordinator Screen Refactoring (`LiveGameScreen`)

**Files:**
- Modify: `lib/src/features/games/presentation/screens/live_game_screen.dart`
- Test: `test/features/games/live_game_screen_refactored_test.dart`

**Interfaces:**
- Consumes: Reusable components (`CartelaBoardWidget`, `CalledNumbersStrip`, `BingoBallBadge`, `GameCountdownRing`) and Riverpod Notifiers.
- Produces: Clean, declarative, thin `LiveGameScreen` coordinator (< 400 lines) that replaces the 10,000+ line God Component without changing any external routes.

- [x] **Step 1: Write smoke widget test for refactored `LiveGameScreen`**

```dart
// test/features/games/live_game_screen_refactored_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/live_game_screen.dart';

void main() {
  testWidgets('LiveGameScreen renders without crash in ProviderScope', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LiveGameScreen(),
        ),
      ),
    );
    expect(find.byType(LiveGameScreen), findsOneWidget);
  });
}
```

- [x] **Step 2: Refactor `LiveGameScreen`**

Refactor `LiveGameScreen` to watch `calledBallsNotifierProvider` and delegate board rendering to `CartelaBoardWidget`, ball history to `CalledNumbersStrip`, and registration to `RegistrationCartelaGrid`. Eliminate the redundant mutable variables in `_LiveGameScreenState`.

- [x] **Step 3: Run test to verify it passes**

Run: `flutter test test/features/games/live_game_screen_refactored_test.dart`  
Expected: PASS.

- [x] **Step 4: Commit**

```bash
git add lib/src/features/games/presentation/screens/live_game_screen.dart test/features/games/live_game_screen_refactored_test.dart
git commit -m "refactor(games): decouple LiveGameScreen into clean declarative coordinator using reusable components"
```

---

### Task 8: Full Mobile Suite Verification

**Files:**
- Entire `friends-bingo-mobile` repository

- [x] **Step 1: Run static analysis across the entire project**

Run: `flutter analyze`  
Expected: 0 errors, clean output.

- [x] **Step 2: Run all unit and widget tests**

Run: `flutter test`  
Expected: All tests PASS.

- [x] **Step 3: Final commit and summary**

```bash
git add .
git commit -m "chore(refactor): complete Phase 1 mobile clean architecture refactoring and reusable component extraction"
```
