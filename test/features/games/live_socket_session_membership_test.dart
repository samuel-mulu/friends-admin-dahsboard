import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/features/games/presentation/utils/live_socket_session_membership.dart';

void main() {
  testWidgets('membership waits for the existing server ACK', (t) async {
    final m = LiveSocketSessionMembership(), ack = Completer<bool>();
    m.apply('s1', join: (_) => ack.future, leave: (_) {});
    expect(m.joinedSessionId, isNull);
    ack.complete(true);
    await t.pump();
    expect(m.joinedSessionId, 's1');
    m.dispose();
  });
  testWidgets(
    'Unauthorized then authentication-ready retry confirms membership',
    (t) async {
      final m = LiveSocketSessionMembership();
      var calls = 0;
      Future<bool> join(String _) async => ++calls > 1;
      m.apply('s1', join: join, leave: (_) {});
      await t.pump();
      expect(m.joinedSessionId, isNull);
      await t.pump(const Duration(seconds: 1));
      expect(calls, 2);
      expect(m.joinedSessionId, 's1');
      await t.pump(const Duration(minutes: 1));
      expect(calls, 2);
      m.dispose();
    },
  );
  testWidgets('failed joins have one bounded burst, resume permits retry', (
    t,
  ) async {
    final m = LiveSocketSessionMembership();
    var calls = 0;
    m.apply(
      's1',
      join: (_) async {
        calls++;
        return false;
      },
      leave: (_) {},
    );
    await t.pump();
    for (final seconds in [1, 2, 4, 8, 60]) {
      await t.pump(Duration(seconds: seconds));
    }
    expect(calls, 5);
    expect(m.joinedSessionId, isNull);
    m.setForeground(true);
    await t.pump();
    expect(calls, 6);
    m.dispose();
  });
  testWidgets(
    'repeated applies cannot duplicate an in-flight or confirmed join',
    (t) async {
      final m = LiveSocketSessionMembership(), ack = Completer<bool>();
      var calls = 0;
      void apply() => m.apply(
        's1',
        join: (_) {
          calls++;
          return ack.future;
        },
        leave: (_) {},
      );
      apply();
      apply();
      expect(calls, 1);
      ack.complete(true);
      await t.pump();
      apply();
      expect(calls, 1);
      m.dispose();
    },
  );
  testWidgets('old session ACK cannot confirm newer session', (t) async {
    final m = LiveSocketSessionMembership(),
        old = Completer<bool>(),
        next = Completer<bool>();
    final leaves = <String>[];
    m.apply('s1', join: (_) => old.future, leave: leaves.add, userId: 'u1');
    m.apply('s2', join: (_) => next.future, leave: leaves.add, userId: 'u1');
    old.complete(true);
    await t.pump();
    expect(m.joinedSessionId, isNull);
    next.complete(true);
    await t.pump();
    expect(m.joinedSessionId, 's2');
    expect(leaves, ['s1']);
    m.dispose();
  });
  testWidgets('old user ACK cannot confirm membership for another account', (
    t,
  ) async {
    final m = LiveSocketSessionMembership(),
        old = Completer<bool>(),
        next = Completer<bool>();
    m.apply('s1', userId: 'u1', join: (_) => old.future, leave: (_) {});
    m.apply('s1', userId: 'u2', join: (_) => next.future, leave: (_) {});
    old.complete(true);
    await t.pump();
    expect(m.joinedSessionId, isNull);
    next.complete(true);
    await t.pump();
    expect(m.joinedSessionId, 's1');
    m.dispose();
  });
  testWidgets('old transport ACK cannot suppress genuine reconnect join', (
    t,
  ) async {
    final m = LiveSocketSessionMembership(),
        old = Completer<bool>(),
        next = Completer<bool>();
    m.apply('s1', join: (_) => old.future, leave: (_) {});
    m.onDisconnected();
    m.onConnected();
    m.apply('s1', join: (_) => next.future, leave: (_) {});
    old.complete(true);
    await t.pump();
    expect(m.joinedSessionId, isNull);
    next.complete(true);
    await t.pump();
    expect(m.joinedSessionId, 's1');
    m.dispose();
  });
  for (final stop in ['logout', 'dispose', 'background', 'disconnect']) {
    testWidgets('$stop stops pending membership retries', (t) async {
      final m = LiveSocketSessionMembership();
      var calls = 0;
      m.apply(
        's1',
        join: (_) async {
          calls++;
          return false;
        },
        leave: (_) {},
      );
      await t.pump();
      switch (stop) {
        case 'logout':
          m.apply(null, join: (_) async => true, leave: (_) {});
        case 'dispose':
          m.dispose();
        case 'background':
          m.setForeground(false);
        case 'disconnect':
          m.onDisconnected();
      }
      await t.pump(const Duration(minutes: 1));
      expect(calls, 1);
      m.dispose();
    });
  }
  testWidgets('disconnected desired membership waits for reconnect', (t) async {
    final m = LiveSocketSessionMembership();
    var calls = 0;
    Future<bool> join(String _) async {
      calls++;
      return true;
    }

    m.apply('s1', join: join, leave: (_) {}, connected: false);
    await t.pump();
    expect(calls, 0);
    m.onConnected();
    m.apply('s1', join: join, leave: (_) {});
    await t.pump();
    expect(calls, 1);
    expect(m.joinedSessionId, 's1');
    m.dispose();
  });
}
