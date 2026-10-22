class HouseChampionsEntry {
  const HouseChampionsEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.cartelaWins,
    required this.gamesWon,
  });

  final int rank;
  final String userId;
  final String displayName;
  final int cartelaWins;
  final int gamesWon;

  factory HouseChampionsEntry.fromJson(Map<String, dynamic> json) {
    return HouseChampionsEntry(
      rank: json['rank'] as int,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Player',
      cartelaWins: json['cartelaWins'] as int,
      gamesWon: json['gamesWon'] as int,
    );
  }
}

class HouseChampionsMe {
  const HouseChampionsMe({
    required this.rank,
    required this.cartelaWins,
    required this.gamesWon,
  });

  final int rank;
  final int cartelaWins;
  final int gamesWon;

  factory HouseChampionsMe.fromJson(Map<String, dynamic> json) {
    return HouseChampionsMe(
      rank: json['rank'] as int,
      cartelaWins: json['cartelaWins'] as int,
      gamesWon: json['gamesWon'] as int,
    );
  }
}

class HouseChampionsResponse {
  const HouseChampionsResponse({
    required this.period,
    required this.timezone,
    required this.periodStart,
    required this.periodEnd,
    required this.labelStart,
    required this.labelEnd,
    required this.updatedAt,
    required this.entries,
    this.me,
  });

  final String period;
  final String timezone;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? labelStart;
  final String? labelEnd;
  final DateTime updatedAt;
  final List<HouseChampionsEntry> entries;
  final HouseChampionsMe? me;

  factory HouseChampionsResponse.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'];
    return HouseChampionsResponse(
      period: json['period'] as String,
      timezone: json['timezone'] as String? ?? 'Africa/Addis_Ababa',
      periodStart: _parseDate(json['periodStart'] as String?),
      periodEnd: _parseDate(json['periodEnd'] as String?),
      labelStart: json['labelStart'] as String?,
      labelEnd: json['labelEnd'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      entries: entriesRaw is List
          ? entriesRaw
                .whereType<Map<String, dynamic>>()
                .map(HouseChampionsEntry.fromJson)
                .toList(growable: false)
          : const [],
      me: json['me'] is Map<String, dynamic>
          ? HouseChampionsMe.fromJson(json['me'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}

enum HouseChampionsPeriod {
  today('today'),
  week('week'),
  lastWeek('last_week'),
  last30Days('last_30_days'),
  allTime('all_time');

  const HouseChampionsPeriod(this.apiValue);

  final String apiValue;
}
