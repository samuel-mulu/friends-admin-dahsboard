import '../data/models/game_cartela_model.dart';

class BulkRegisterFailure {
  const BulkRegisterFailure({
    required this.cartelaId,
    required this.cartelaNumber,
    required this.reason,
  });

  final String cartelaId;
  final int cartelaNumber;
  final String reason;
}

class BulkRegisterResult {
  const BulkRegisterResult({
    required this.successes,
    required this.failures,
  });

  final List<GameCartelaModel> successes;
  final List<BulkRegisterFailure> failures;

  bool get hasSuccesses => successes.isNotEmpty;
  bool get hasFailures => failures.isNotEmpty;
}
