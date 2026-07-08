import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/core/network/api_client.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/deposit_config_model.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/deposit_model.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/deposit_reference_check_result.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/payment_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/data/models/wallet_model.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/receipt_ocr_result.dart';
import 'package:friends_bingo_app/src/features/wallet/data/receipt_ocr/receipt_ocr_service.dart';
import 'package:friends_bingo_app/src/features/wallet/data/wallet_repository.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/providers/deposit_config_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:friends_bingo_app/src/features/wallet/presentation/screens/deposit_screen.dart';

void main() {
  testWidgets('scan affordance is hidden when OCR service is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: _FakeWalletRepository(),
        ocrService: const UnsupportedReceiptOcrService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.document_scanner_outlined), findsNothing);
  });

  testWidgets('scan affordance is visible when OCR service is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: _FakeWalletRepository(),
        ocrService: _FakeReceiptOcrService(isAvailable: true, result: null),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Scan receipt'), findsOneWidget);
  });

  testWidgets('OCR success fills amount and reference', (tester) async {
    final repository = _FakeWalletRepository();

    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: repository,
        ocrService: _FakeReceiptOcrService(
          isAvailable: true,
          result: const ReceiptOcrResult(
            reference: 'FT26174PCT3Q',
            amount: '10.00',
            rawText: 'Transferred Amount: 10.00 ETB\nRef FT26174PCT3Q',
            provider: 'CBE',
            confidence: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pump();
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      '10.00',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'FT26174PCT3Q',
    );
    expect(
      find.text('Receipt detected. Please review before submitting.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'I have checked the amount and reference number from my transaction',
      ),
      findsOneWidget,
    );
    expect(repository.checkDepositReferenceCalls, 0);
    expect(repository.createDepositCalls, 0);
  });

  testWidgets('OCR failure does not crash', (tester) async {
    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: _FakeWalletRepository(),
        ocrService: _FakeReceiptOcrService(
          isAvailable: true,
          result: const ReceiptOcrResult(
            reference: null,
            amount: null,
            rawText: 'noise',
            provider: 'CBE',
            confidence: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('Could not read receipt. Please type manually.'),
      findsOneWidget,
    );
  });

  testWidgets('user can still edit fields after OCR fill', (tester) async {
    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: _FakeWalletRepository(),
        ocrService: _FakeReceiptOcrService(
          isAvailable: true,
          result: const ReceiptOcrResult(
            reference: 'FT26174PCT3Q',
            amount: '10.00',
            rawText: 'Transferred Amount: 10.00 ETB\nRef FT26174PCT3Q',
            provider: 'CBE',
            confidence: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '25.00');
    await tester.enterText(fields.at(1), 'FT999999');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      '25.00',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'FT999999',
    );
  });

  testWidgets('submit still requires manual tap after OCR fill', (
    tester,
  ) async {
    final repository = _FakeWalletRepository();

    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: repository,
        ocrService: _FakeReceiptOcrService(
          isAvailable: true,
          result: const ReceiptOcrResult(
            reference: 'FT26174PCT3Q',
            amount: '10.00',
            rawText: 'Transferred Amount: 10.00 ETB\nRef FT26174PCT3Q',
            provider: 'CBE',
            confidence: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    expect(repository.checkDepositReferenceCalls, 0);
    expect(repository.createDepositCalls, 0);

    final submitButton = find.widgetWithText(FilledButton, 'Submit deposit');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.checkDepositReferenceCalls, 0);
    expect(repository.createDepositCalls, 0);

    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.checkDepositReferenceCalls, 1);
    expect(repository.createDepositCalls, 1);
  });

  testWidgets('partial OCR fills only detected field', (tester) async {
    await tester.pumpWidget(
      _wrapDepositScreen(
        repository: _FakeWalletRepository(),
        ocrService: _FakeReceiptOcrService(
          isAvailable: true,
          result: const ReceiptOcrResult(
            reference: null,
            amount: '10.00',
            rawText: 'Amount 10.00',
            provider: 'CBE',
            confidence: 0.70,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Scan receipt'));
    await tester.pump();
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      '10.00',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      isEmpty,
    );
    expect(find.text('Some details detected. Please review.'), findsOneWidget);
    expect(
      find.text(
        'I have checked the amount and reference number from my transaction',
      ),
      findsNothing,
    );
  });
}

Widget _wrapDepositScreen({
  required _FakeWalletRepository repository,
  ReceiptOcrService? ocrService,
}) {
  return ProviderScope(
    overrides: [
      myWalletProvider.overrideWith((ref) async => _walletModel()),
      depositConfigProvider.overrideWith((ref) async => _depositConfig()),
      walletRepositoryProvider.overrideWithValue(repository),
      if (ocrService != null)
        receiptOcrServiceProvider.overrideWithValue(ocrService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DepositScreen(),
    ),
  );
}

WalletModel _walletModel() {
  final now = DateTime(2026, 6, 23);
  return WalletModel(
    id: 'wallet-1',
    userId: 'user-1',
    balance: '500.00',
    lockedBalance: '0.00',
    bonusCartelaBalance: 0,
    isFirstTimePlayer: false,
    createdAt: now,
    updatedAt: now,
  );
}

DepositConfigModel _depositConfig() {
  return const DepositConfigModel(
    providers: [
      DepositProviderConfig(
        key: 'CBE',
        name: 'CBE',
        receiptCodeLabel: 'Reference number',
        helpText: '',
        requiresAmount: true,
        settlementAccount: '',
        receiverName: '',
      ),
      DepositProviderConfig(
        key: 'TELEBIRR',
        name: 'Telebirr',
        receiptCodeLabel: 'Receipt code',
        helpText: '',
        requiresAmount: true,
        settlementAccount: '',
        receiverName: '',
      ),
      DepositProviderConfig(
        key: 'AWASH',
        name: 'Awash',
        receiptCodeLabel: 'Reference number',
        helpText: '',
        requiresAmount: true,
        settlementAccount: '',
        receiverName: '',
      ),
      DepositProviderConfig(
        key: 'BOA',
        name: 'BOA',
        receiptCodeLabel: 'Reference number',
        helpText: '',
        requiresAmount: true,
        settlementAccount: '',
        receiverName: '',
      ),
    ],
    telebirr: TelebirrDepositConfig(
      providerName: 'Telebirr',
      receiptHelpText: '',
      receiptBaseUrl: 'https://transactioninfo.ethiotelecom.et/receipt',
      receiverPhoneLast4: '5678',
      receiverName: 'Friends Bingo',
    ),
  );
}

class _FakeReceiptOcrService implements ReceiptOcrService {
  _FakeReceiptOcrService({required this.isAvailable, required this.result});

  @override
  final bool isAvailable;

  final ReceiptOcrResult? result;

  @override
  Future<ReceiptOcrResult?> scanReceipt({
    required PaymentProvider provider,
  }) async {
    return result;
  }
}

class _FakeWalletRepository extends WalletRepository {
  _FakeWalletRepository() : super(ApiClient(Dio()));

  int checkDepositReferenceCalls = 0;
  int createDepositCalls = 0;

  @override
  Future<DepositReferenceCheckResult> checkDepositReference({
    required PaymentProvider provider,
    required String transactionRef,
  }) async {
    checkDepositReferenceCalls += 1;
    return const DepositReferenceCheckResult(code: 'OK', message: 'OK');
  }

  @override
  Future<DepositModel> createDeposit({
    required PaymentProvider provider,
    required String amount,
    required String transactionRef,
    receiptParseStatus,
    clientReceipt,
  }) async {
    createDepositCalls += 1;
    final now = DateTime(2026, 6, 23);
    return DepositModel(
      id: 'deposit-1',
      userId: 'user-1',
      provider: provider,
      amount: amount,
      transactionRef: transactionRef,
      status: DepositStatus.approved,
      rejectionReason: null,
      createdAt: now,
      verifiedAt: now,
      updatedAt: now,
    );
  }
}
