import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:friends_bingo_app/src/features/wallet/data/models/wallet_model.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/widgets/welcome_bonus_banner.dart';

void main() {
  WalletModel buildWallet({
    bool isFirstTimePlayer = true,
    int bonusCartelaBalance = 10,
  }) {
    return WalletModel(
      id: 'wallet-1',
      userId: 'user-1',
      balance: '0.00',
      lockedBalance: '0.00',
      bonusCartelaBalance: bonusCartelaBalance,
      isFirstTimePlayer: isFirstTimePlayer,
      createdAt: DateTime.utc(2026, 7, 2),
      updatedAt: DateTime.utc(2026, 7, 2),
    );
  }

  testWidgets('shows welcome banner for first-time players with bonus cartelas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WelcomeBonusBanner(wallet: buildWallet()),
        ),
      ),
    );

    expect(find.textContaining('Welcome bonus'), findsOneWidget);
    expect(find.textContaining('10 bonus cartelas'), findsOneWidget);
  });

  testWidgets('hides welcome banner after first registration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WelcomeBonusBanner(
            wallet: buildWallet(isFirstTimePlayer: false),
          ),
        ),
      ),
    );

    expect(find.textContaining('Welcome bonus'), findsNothing);
  });
}
