import 'game_model.dart';

class RegistrationStateResponse {
  const RegistrationStateResponse({
    required this.sessionId,
    required this.registeredCartelasSummary,
    required this.myCartelaIds,
    this.reservedCartelasSummary = const [],
    this.category = GameCategory.normal,
    this.entryFee = '0',
    this.fixedPrizeAmount,
    this.maxCartelasPerPlayer,
    this.remainingFreeCartelas,
    this.registeredCartelasCount,
    this.reservedCartelasCount,
  });

  final String sessionId;
  final List<RegisteredCartelaSummary> registeredCartelasSummary;
  final List<RegisteredCartelaSummary> reservedCartelasSummary;
  final List<String> myCartelaIds;
  final GameCategory category;
  final String entryFee;
  final String? fixedPrizeAmount;
  final int? maxCartelasPerPlayer;
  final int? remainingFreeCartelas;
  final int? registeredCartelasCount;
  final int? reservedCartelasCount;

  factory RegistrationStateResponse.fromJson(Map<String, dynamic> json) {
    List<RegisteredCartelaSummary> parseSummaryList(Object? value) {
      if (value is! List) {
        return const [];
      }

      return value
          .whereType<Map<String, dynamic>>()
          .map(RegisteredCartelaSummary.fromJson)
          .toList(growable: false);
    }

    return RegistrationStateResponse(
      sessionId: json['sessionId'] as String,
      registeredCartelasSummary: parseSummaryList(
        json['registeredCartelasSummary'],
      ),
      reservedCartelasSummary: parseSummaryList(
        json['reservedCartelasSummary'],
      ),
      myCartelaIds: json['myCartelaIds'] is List
          ? (json['myCartelaIds'] as List).whereType<String>().toList(
              growable: false,
            )
          : const [],
      category: GameCategory.fromApi(json['category']?.toString()),
      entryFee: json['entryFee']?.toString() ?? '0',
      fixedPrizeAmount: json['fixedPrizeAmount']?.toString(),
      maxCartelasPerPlayer: (json['maxCartelasPerPlayer'] as num?)?.toInt(),
      remainingFreeCartelas: (json['remainingFreeCartelas'] as num?)?.toInt(),
      registeredCartelasCount: (json['registeredCartelasCount'] as num?)?.toInt(),
      reservedCartelasCount: (json['reservedCartelasCount'] as num?)?.toInt(),
    );
  }
}
