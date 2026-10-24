import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/network/api_exception.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_called_numbers_controller.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/storage/bingo_claim_attempt_storage.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_attempt.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_source.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';

class _FakeLiveGameHost extends Fake implements LiveGameHost {}

class _MemoryClaimStorage extends BingoClaimAttemptStorage {
  final Map<String, Map<String, dynamic>> records = {};

  @override
  Future<List<Map<String, dynamic>>> load(String user, String session) async =>
      records.values
          .where((v) => v['userId'] == user && v['sessionId'] == session)
          .toList();

  @override
  Future<void> save(Map<String, dynamic> identity) async {
    records[identity['gameCartelaId'] as String] = Map.of(identity);
  }

  @override
  Future<void> remove(Map<String, dynamic> identity) async {
    final key = identity['gameCartelaId'] as String;
    if (records[key]?['claimAttemptId'] == identity['claimAttemptId']) {
      records.remove(key);
    }
  }
}

void main() {
  group('LiveCalledNumbersController Claim Lock & Freeze Prevention', () {
    test('clearing claimingCartelaIds unlocks claim for subsequent attempts', () {
      final host = _FakeLiveGameHost();
      final controller = LiveCalledNumbersController(host);
      const cartelaId = 'cartela-123';

      controller.claimingCartelaIds.add(cartelaId);
      controller.claimStripHoldActive = true;
      expect(controller.claimingCartelaIds.contains(cartelaId), isTrue);
      expect(controller.claimStripHoldActive, isTrue);

      // Unconditional clear in finally block
      controller.claimStripHoldActive = false;
      controller.claimingCartelaIds.remove(cartelaId);
      controller.preClaimNextAutoCallAt = null;

      expect(controller.claimingCartelaIds.contains(cartelaId), isFalse);
      expect(controller.claimStripHoldActive, isFalse);
    });

    test('rememberBlockedCartelaReason captures code and message', () {
      final host = _FakeLiveGameHost();
      final controller = LiveCalledNumbersController(host);
      const cartelaId = 'cartela-456';

      controller.rememberBlockedCartelaReason(
        gameCartelaId: cartelaId,
        reasonCode: 'INVALID_LATE_CLAIM',
        serverReason: 'Pattern was completed on ball 22',
      );

      expect(controller.blockedReasonCodeFor(cartelaId), equals('INVALID_LATE_CLAIM'));
      expect(controller.blockedServerReasonFor(cartelaId), equals('Pattern was completed on ball 22'));
    });

    testWidgets(
      'simulates dropped response: recovers via GET every 700ms, treats CHECKING as waiting, resets locks and spinner',
      (tester) async {
        final host = _FakeLiveGameHost();
        final storage = _MemoryClaimStorage();
        var recoveryGets = 0;

        final controller = LiveCalledNumbersController(
          host,
          claimStorage: storage,
          claimNow: tester.binding.clock.now,
          recoverClaim: (sessionId, uuid) async {
            recoveryGets++;
            final isChecking = recoveryGets == 1;
            return BingoClaimAttemptStatus(
              claimAttemptId: uuid,
              status: isChecking
                  ? BingoClaimStatus.checking
                  : BingoClaimStatus.valid,
              gameCartelaStatus: isChecking
                  ? GameCartelaStatus.registered
                  : GameCartelaStatus.winner,
              gameStatus: isChecking
                  ? GameStatus.playing
                  : GameStatus.winnerWindow,
              isWinner: !isChecking,
              retryAllowed: isChecking,
            );
          },
        );

        await controller.bindClaimRecoveryScope('user-1', 'session-1');

        // User initiates claim: spinner/locks activate
        final attempt = controller.beginClaimAttempt(
          gameCartelaId: 'gc-1',
          claimAttemptId: 'attempt-uuid-1',
          roundIndex: 1,
          claimSource: BingoClaimSource.manual,
        )!;

        expect(controller.claimingCartelaIds.contains('gc-1'), isTrue);
        expect(controller.claimStripHoldActive, isTrue);
        expect(controller.isConfirmingClaim('gc-1'), isTrue);

        // POST simulation: dropped response / 4s receiveTimeout
        controller.finishClaimSubmission(attempt);
        // Under ambiguous failure, recoverClaimAttempt runs
        await controller.recoverClaimAttempt(attempt);

        // 1st recovery GET reports CHECKING: treated as "keep waiting"
        expect(recoveryGets, 1);
        expect(controller.isConfirmingClaim('gc-1'), isTrue);
        expect(attempt.nextRecoveryAt, isNotNull);

        // Advance by 700ms polling interval
        await tester.pump(const Duration(milliseconds: 700));

        // 2nd recovery GET reports VALID (terminal): locks clear, spinner resets
        expect(recoveryGets, 2);
        expect(controller.isConfirmingClaim('gc-1'), isFalse);
        expect(controller.claimingCartelaIds, isEmpty);
        expect(controller.confirmingOrClaimingCartelaIds, isEmpty);
        expect(controller.claimStripHoldActive, isFalse);

        controller.dispose();
      },
    );
  });
}
