import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/claims/data/models/bingo_claim_result.dart';
import 'package:friends_bingo_app/src/features/games/claims/domain/bingo_claim_source.dart';

/// Result of applying a terminal (or non-terminal) claim outcome through the
/// single Flutter claim owner. Cartela list mutation and pending cleanup are
/// computed together so callers can apply both in one UI frame.
class ClaimResolution {
  const ClaimResolution({
    required this.applied,
    required this.cartelas,
    this.cartelaStatus,
  });

  final bool applied;
  final List<GameCartelaModel> cartelas;
  final GameCartelaStatus? cartelaStatus;
}

/// Called-number strip state, reconciliation buffers, and claim holds.
class BingoClaimAttempt {
  BingoClaimAttempt({
    required this.userId,
    required this.sessionId,
    required this.gameCartelaId,
    required this.claimAttemptId,
    required this.roundIndex,
    this.claimSource = BingoClaimSource.manual,
    this.autoBingoAttemptKey,
  });

  final String userId;
  final String sessionId;
  final String gameCartelaId;
  final String claimAttemptId;
  final int roundIndex;
  final BingoClaimSource claimSource;
  final String? autoBingoAttemptKey;
  bool terminal = false;
  BingoClaimStatus? terminalStatus;
  String? serverClaimId;
  bool terminalPresentationEnriched = false;
  Future<void>? presentationReconciliation;
  bool postInFlight = true;
  int recoveryErrors = 0;

  /// Bounded same-UUID POST retries after recovery GET 404 (idempotent on Nest).
  int sameUuidPostRetries = 0;
  static const maxSameUuidPostRetries = 2;

  /// True only when the original POST's own TCP connect() never completed —
  /// by HTTP semantics no request bytes could have left the device. This
  /// alone is never sufficient proof; it is only combined with an
  /// independent, simultaneous recovery-GET connection failure before a
  /// claim is ever cleared without an authoritative server response.
  bool postConnectNeverCompleted = false;
  DateTime? nextRecoveryAt;
  Future<void>? recoveryInFlight;

  Map<String, dynamic> get identity => {
    'userId': userId,
    'sessionId': sessionId,
    'gameCartelaId': gameCartelaId,
    'claimAttemptId': claimAttemptId,
    'roundIndex': roundIndex,
    'claimSource': claimSource.apiValue,
    'retryDenied': terminal,
  };
}
