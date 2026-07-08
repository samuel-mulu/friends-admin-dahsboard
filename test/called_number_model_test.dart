import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/data/models/called_number_model.dart';

void main() {
  test('parses slotId and playerStatus from draw payload', () {
    final calledNumber = CalledNumberModel.fromJson({
      'id': 'cn-1',
      'gameSessionId': 'session-1',
      'slotId': 'slot-1',
      'letter': 'I',
      'number': 25,
      'order': 6,
      'createdAt': '2026-06-12T12:00:06.000Z',
      'playerStatus': 'playing',
    });

    expect(calledNumber.sessionId, 'session-1');
    expect(calledNumber.slotId, 'slot-1');
    expect(calledNumber.playerStatus, 'playing');
    expect(calledNumber.order, 6);
  });
}
