import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/src/core/time/server_clock_service.dart';
import 'package:friends_bingo_app/src/features/games/data/models/cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/data/models/registration_state_model.dart';
import 'package:friends_bingo_app/src/features/games/domain/registration_state_patch.dart';
import 'package:friends_bingo_app/src/features/games/domain/resolved_cartela_availability.dart';

void main() {
  group('RegistrationCartelaChange', () {
    test('resolves reserved owner for current user', () {
      final change = RegistrationCartelaChange.fromSocketJson({
        'cartelaId': 'cartela-1',
        'cartelaNumber': 12,
        'owner': 'RESERVED_OTHER',
        'actorUserId': 'user-me',
        'expiresAt': '2026-06-24T12:00:10.000Z',
      }, currentUserId: 'user-me');

      expect(change.owner, 'RESERVED_ME');
      expect(change.toSummary()?.status, 'RESERVED');
    });

    test('resolves registered owner for other user', () {
      final change = RegistrationCartelaChange.fromSocketJson({
        'cartelaId': 'cartela-2',
        'cartelaNumber': 8,
        'owner': 'OTHER',
        'actorUserId': 'user-other',
      }, currentUserId: 'user-me');

      expect(change.owner, 'OTHER');
      expect(change.toSummary()?.status, 'REGISTERED');
    });

    test('available change removes summary', () {
      final change = RegistrationCartelaChange.fromSocketJson({
        'cartelaId': 'cartela-3',
        'cartelaNumber': 3,
        'owner': 'AVAILABLE',
      }, currentUserId: 'user-me');

      expect(change.toSummary(), isNull);
    });

    test('parses multiple batched socket changes', () {
      final changes = parseRegistrationCartelaChanges([
        {
          'cartelaId': 'cartela-1',
          'cartelaNumber': 12,
          'owner': 'RESERVED_OTHER',
          'actorUserId': 'user-other',
        },
        {
          'cartelaId': 'cartela-2',
          'cartelaNumber': 34,
          'owner': 'OTHER',
          'actorUserId': 'user-other',
        },
      ], currentUserId: 'user-me');

      expect(changes, hasLength(2));
      expect(changes[0].owner, 'RESERVED_OTHER');
      expect(changes[1].owner, 'OTHER');
    });
  });

  group('mergeRegistrationSummariesWithPatches', () {
    test('registered base is not downgraded by reserved patch', () {
      final base = [
        const RegisteredCartelaSummary(
          cartelaId: 'a',
          cartelaNumber: 1,
          owner: 'OTHER',
          status: 'REGISTERED',
        ),
        const RegisteredCartelaSummary(
          cartelaId: 'b',
          cartelaNumber: 2,
          owner: 'ME',
          status: 'REGISTERED',
        ),
      ];

      final merged = mergeRegistrationSummariesWithPatches(
        base: base,
        patches: {
          'a': const RegisteredCartelaSummary(
            cartelaId: 'a',
            cartelaNumber: 1,
            owner: 'RESERVED_OTHER',
            status: 'RESERVED',
          ),
        },
        removedCartelaIds: {'b'},
      );

      expect(merged, hasLength(1));
      expect(merged.single.cartelaId, 'a');
      expect(merged.single.owner, 'OTHER');
    });
  });

  group('ME registration patch availability', () {
    test('ME patch marks cartela as mine in merged summary', () {
      final change = RegistrationCartelaChange(
        cartelaId: 'cartela-9',
        cartelaNumber: 9,
        owner: 'ME',
        actorUserId: 'user-me',
      );

      final summary = change.toSummary();
      expect(summary, isNotNull);
      expect(summary!.isMine, isTrue);
      expect(summary.isTaken, isFalse);

      final merged = mergeRegistrationSummariesWithPatches(
        base: const [],
        patches: {summary.cartelaId: summary},
        removedCartelaIds: const {},
      );

      expect(merged.single.cartelaNumber, 9);
      expect(merged.single.isMine, isTrue);
    });

    test('OTHER patch marks cartela as taken in merged summary', () {
      final change = RegistrationCartelaChange(
        cartelaId: 'cartela-12',
        cartelaNumber: 12,
        owner: 'OTHER',
        actorUserId: 'user-other',
      );

      final summary = change.toSummary();
      expect(summary, isNotNull);
      expect(summary!.isTaken, isTrue);
      expect(summary.isMine, isFalse);
    });
  });

  group('mergeRegistrationStateWithPatches', () {
    test('ignores snapshot from a different session', () {
      const snapshot = RegistrationStateResponse(
        sessionId: 'session-normal',
        registeredCartelasSummary: [
          RegisteredCartelaSummary(
            cartelaId: 'a',
            cartelaNumber: 1,
            owner: 'ME',
            status: 'REGISTERED',
          ),
        ],
        reservedCartelasSummary: [],
        myCartelaIds: ['a'],
      );

      final merged = mergeRegistrationStateWithPatches(
        snapshot: snapshot,
        patches: const {},
        removedCartelaIds: const {},
        sessionId: 'session-big-game',
      );

      expect(merged, isEmpty);
    });

    test('registered patch overrides reserved base summary', () {
      const snapshot = RegistrationStateResponse(
        sessionId: 'session-1',
        registeredCartelasSummary: [],
        reservedCartelasSummary: [
          RegisteredCartelaSummary(
            cartelaId: 'a',
            cartelaNumber: 1,
            owner: 'RESERVED_ME',
            status: 'RESERVED',
          ),
        ],
        myCartelaIds: [],
      );

      final merged = mergeRegistrationStateWithPatches(
        snapshot: snapshot,
        patches: {
          'a': const RegisteredCartelaSummary(
            cartelaId: 'a',
            cartelaNumber: 1,
            owner: 'ME',
            status: 'REGISTERED',
          ),
        },
        removedCartelaIds: const {},
        sessionId: 'session-1',
      );

      expect(merged.single.owner, 'ME');
    });

    test('available removal clears reserved cartela', () {
      const snapshot = RegistrationStateResponse(
        sessionId: 'session-1',
        registeredCartelasSummary: [],
        reservedCartelasSummary: [
          RegisteredCartelaSummary(
            cartelaId: 'a',
            cartelaNumber: 1,
            owner: 'RESERVED_ME',
            status: 'RESERVED',
          ),
        ],
        myCartelaIds: [],
      );

      final merged = mergeRegistrationStateWithPatches(
        snapshot: snapshot,
        patches: const {},
        removedCartelaIds: {'a'},
        sessionId: 'session-1',
      );

      expect(merged, isEmpty);
    });
  });

  group('parseAndValidateRegistrationCartelaChanges', () {
    test('flags malformed payloads', () {
      final parsed = parseAndValidateRegistrationCartelaChanges([
        {'cartelaNumber': 1, 'owner': 'OTHER'},
        {'cartelaId': 'cartela-1', 'cartelaNumber': 2, 'owner': 'OTHER'},
      ]);

      expect(parsed.hasMalformed, isTrue);
      expect(parsed.valid, hasLength(1));
      expect(parsed.valid.single.cartelaNumber, 2);
    });
  });

  group('resolveCartelaAvailability', () {
    test('pending selection stays available with pending flag', () {
      final resolved = resolveCartelaAvailability(
        cartela: CartelaModel(
          id: 'cartela-1',
          number: 7,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
        summary: null,
        isTrackedMine: false,
        isSelecting: true,
        isReservePending: true,
        isRegistering: false,
        localHoldExpiresAt: null,
        cartelaHoldSeconds: 30,
        clock: ServerClockService(),
      );

      expect(resolved.isAvailable, isTrue);
      expect(resolved.isPending, isTrue);
    });
  });
}
