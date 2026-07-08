import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_socket_session_membership.dart';

void main() {
  group('LiveSocketSessionMembership', () {
    test('is idempotent when applying the same session', () {
      final membership = LiveSocketSessionMembership();
      final joins = <String>[];
      final leaves = <String>[];

      membership.apply(
        'session-1',
        join: joins.add,
        leave: leaves.add,
      );
      membership.apply(
        'session-1',
        join: joins.add,
        leave: leaves.add,
      );

      expect(membership.joinedSessionId, 'session-1');
      expect(joins, ['session-1']);
      expect(leaves, isEmpty);
    });

    test('leaves previous session before joining a new one', () {
      final membership = LiveSocketSessionMembership();
      final joins = <String>[];
      final leaves = <String>[];

      membership.apply('session-1', join: joins.add, leave: leaves.add);
      membership.apply('session-2', join: joins.add, leave: leaves.add);

      expect(membership.joinedSessionId, 'session-2');
      expect(leaves, ['session-1']);
      expect(joins, ['session-1', 'session-2']);
    });

    test('clearing membership leaves the active session', () {
      final membership = LiveSocketSessionMembership();
      final joins = <String>[];
      final leaves = <String>[];

      membership.apply('session-1', join: joins.add, leave: leaves.add);
      membership.apply(null, join: joins.add, leave: leaves.add);

      expect(membership.joinedSessionId, isNull);
      expect(leaves, ['session-1']);
      expect(joins, ['session-1']);
    });
  });
}
