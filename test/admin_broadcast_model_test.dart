import 'package:flutter_test/flutter_test.dart';

import 'package:friends_bingo_app/src/features/messages/data/models/admin_broadcast_model.dart';

void main() {
  group('AdminBroadcastModel', () {
    test('fromJson parses broadcast payload with category', () {
      final model = AdminBroadcastModel.fromJson({
        'id': 'broadcast-1',
        'title': 'Maintenance',
        'body': 'Tonight at 10 PM',
        'createdAt': '2026-06-30T12:00:00.000Z',
        'category': 'FORCED',
      });

      expect(model.id, 'broadcast-1');
      expect(model.category, AdminBroadcastCategory.forced);
      expect(model.isForced, isTrue);
      expect(model.canDismiss, isFalse);
    });
  });

  group('PlayerBroadcastsResponse', () {
    test('fromJson splits inbox and forced broadcast', () {
      final response = PlayerBroadcastsResponse.fromJson({
        'broadcasts': [
          {
            'id': 'persistent-1',
            'title': 'Notice',
            'body': 'Always visible',
            'createdAt': '2026-06-30T12:00:00.000Z',
            'category': 'PERSISTENT',
          },
          {
            'id': 'dismissible-1',
            'title': 'Hello',
            'body': 'World',
            'createdAt': '2026-06-30T12:00:00.000Z',
            'category': 'DISMISSIBLE',
          },
        ],
        'forcedBroadcast': {
          'id': 'forced-1',
          'title': 'Maintenance',
          'body': 'Soon',
          'createdAt': '2026-06-30T12:00:00.000Z',
          'category': 'FORCED',
        },
        'unreadCount': 1,
      });

      expect(response.broadcasts, hasLength(2));
      expect(response.forcedBroadcast?.id, 'forced-1');
      expect(response.unreadCount, 1);
    });
    test('normalize splits forced messages out of inbox', () {
      final state = PlayerBroadcastsState.normalize(
        inboxBroadcasts: [
          AdminBroadcastModel.fromJson({
            'id': 'forced-1',
            'title': 'Maintenance',
            'body': 'Soon',
            'createdAt': '2026-06-30T12:00:00.000Z',
            'category': 'FORCED',
          }),
          AdminBroadcastModel.fromJson({
            'id': 'persistent-1',
            'title': 'Notice',
            'body': 'Pinned',
            'createdAt': '2026-06-30T12:00:00.000Z',
            'category': 'PERSISTENT',
          }),
        ],
      );

      expect(state.forcedBroadcast?.id, 'forced-1');
      expect(state.inboxBroadcasts, hasLength(1));
      expect(state.inboxBroadcasts.first.category,
          AdminBroadcastCategory.persistent);
      expect(state.unreadCount, 0);
    });
  });
}
