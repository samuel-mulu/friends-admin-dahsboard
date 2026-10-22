import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/wallet/deposits/data/models/deposit_model.dart';
import 'package:friends_bingo_app/src/features/wallet/shared/domain/entities/payment_provider.dart';

void main() {
  group('Deposit Idempotent Submission Contract', () {
    test('DepositModel deserializes approved idempotent response successfully', () {
      final json = {
        'id': 'dep-idempotent-1',
        'userId': 'user-1',
        'provider': 'TELEBIRR',
        'amount': '100.00',
        'transactionRef': 'REF987654321',
        'status': 'APPROVED',
        'createdAt': DateTime.now().toIso8601String(),
        'verifiedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final deposit = DepositModel.fromJson(json);

      expect(deposit.id, equals('dep-idempotent-1'));
      expect(deposit.provider, equals(PaymentProvider.telebirr));
      expect(deposit.status, equals(DepositStatus.approved));
      expect(deposit.amount, equals('100.00'));
    });

    test('DepositModel deserializes pending retry response successfully', () {
      final json = {
        'id': 'dep-pending-1',
        'userId': 'user-1',
        'provider': 'CBE',
        'amount': '250.00',
        'transactionRef': 'FT1234567890',
        'status': 'PENDING',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final deposit = DepositModel.fromJson(json);

      expect(deposit.id, equals('dep-pending-1'));
      expect(deposit.provider, equals(PaymentProvider.cbe));
      expect(deposit.status, equals(DepositStatus.pending));
    });
  });
}
