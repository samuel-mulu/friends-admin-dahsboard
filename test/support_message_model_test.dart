import 'package:friends_bingo_app/src/features/support/data/models/support_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SupportMessageModel parses player message with admin reply', () {
    final message = SupportMessageModel.fromJson({
      'id': 'msg-1',
      'userId': 'user-1',
      'category': 'FEEDBACK',
      'message': 'Great app',
      'status': 'REPLIED',
      'adminReply': 'Thanks for the feedback!',
      'repliedAt': '2026-07-02T12:00:00.000Z',
      'createdAt': '2026-07-02T11:00:00.000Z',
      'updatedAt': '2026-07-02T12:00:00.000Z',
    });

    expect(message.category, SupportCategory.feedback);
    expect(message.status, SupportStatus.replied);
    expect(message.hasAdminReply, isTrue);
    expect(message.adminReply, 'Thanks for the feedback!');
  });
}
