import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/leaderboard/data/models/house_champions_model.dart';

void main() {
  group('HouseChampionsResponse', () {
    test('parses full JSON payload with me entry correctly', () {
      final json = {
        'period': 'week',
        'timezone': 'Africa/Addis_Ababa',
        'periodStart': '2026-10-15T00:00:00.000Z',
        'periodEnd': '2026-10-22T23:59:59.000Z',
        'labelStart': 'Oct 15',
        'labelEnd': 'Oct 22',
        'updatedAt': '2026-10-22T12:00:00.000Z',
        'entries': [
          {
            'rank': 1,
            'userId': 'user-1',
            'displayName': 'Top Winner',
            'cartelaWins': 42,
            'gamesWon': 20,
          },
          {
            'rank': 2,
            'userId': 'user-2',
            'displayName': 'Runner Up',
            'cartelaWins': 30,
            'gamesWon': 15,
          },
        ],
        'me': {
          'rank': 5,
          'cartelaWins': 12,
          'gamesWon': 8,
        },
      };

      final response = HouseChampionsResponse.fromJson(json);

      expect(response.period, 'week');
      expect(response.timezone, 'Africa/Addis_Ababa');
      expect(response.periodStart, DateTime.parse('2026-10-15T00:00:00.000Z'));
      expect(response.periodEnd, DateTime.parse('2026-10-22T23:59:59.000Z'));
      expect(response.labelStart, 'Oct 15');
      expect(response.labelEnd, 'Oct 22');
      expect(response.entries.length, 2);
      expect(response.entries[0].rank, 1);
      expect(response.entries[0].displayName, 'Top Winner');
      expect(response.entries[0].cartelaWins, 42);
      expect(response.entries[0].gamesWon, 20);
      expect(response.me?.rank, 5);
      expect(response.me?.cartelaWins, 12);
      expect(response.me?.gamesWon, 8);
    });

    test('handles empty entries and null me gracefully', () {
      final json = {
        'period': 'today',
        'updatedAt': '2026-10-22T12:00:00.000Z',
        'entries': null,
      };

      final response = HouseChampionsResponse.fromJson(json);

      expect(response.period, 'today');
      expect(response.entries, isEmpty);
      expect(response.me, isNull);
      expect(response.labelStart, isNull);
    });
  });

  group('HouseChampionsPeriod', () {
    test('defines expected API string values', () {
      expect(HouseChampionsPeriod.today.apiValue, 'today');
      expect(HouseChampionsPeriod.week.apiValue, 'week');
      expect(HouseChampionsPeriod.lastWeek.apiValue, 'last_week');
      expect(HouseChampionsPeriod.last30Days.apiValue, 'last_30_days');
      expect(HouseChampionsPeriod.allTime.apiValue, 'all_time');
    });
  });
}
