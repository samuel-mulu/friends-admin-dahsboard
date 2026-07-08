import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friends_bingo_app/l10n/app_localizations.dart';
import 'package:friends_bingo_app/src/features/auth/domain/auth_session.dart';
import 'package:friends_bingo_app/src/features/auth/domain/user_profile.dart';
import 'package:friends_bingo_app/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:friends_bingo_app/src/features/messages/data/models/admin_broadcast_model.dart';
import 'package:friends_bingo_app/src/features/messages/presentation/providers/broadcast_banner_provider.dart';
import 'package:friends_bingo_app/src/features/messages/presentation/providers/broadcasts_provider.dart';
import 'package:friends_bingo_app/src/features/messages/presentation/widgets/broadcast_top_banner.dart';

AdminBroadcastModel _broadcast({
  required String id,
  AdminBroadcastCategory category = AdminBroadcastCategory.dismissible,
}) {
  return AdminBroadcastModel(
    id: id,
    title: 'Title $id',
    body: 'Body $id',
    createdAt: DateTime.utc(2026, 6, 30),
    category: category,
  );
}

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() => AuthState(
        session: AuthSession(
          accessToken: 'token',
          refreshToken: 'refresh',
          user: UserProfile(
            id: 'user-1',
            fullName: 'Test Player',
            phoneNumber: '0912345678',
            role: UserRole.player,
            status: UserStatus.active,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ),
      );
}

class _StubBroadcastsNotifier extends BroadcastsNotifier {
  _StubBroadcastsNotifier(this._initial);

  final PlayerBroadcastsState _initial;

  @override
  Future<PlayerBroadcastsState> build() async => _initial;

  void emit(PlayerBroadcastsState next) {
    state = AsyncData(next);
  }
}

void main() {
  group('BroadcastBannerNotifier', () {
    test('showFromSocket reveals a new admin message immediately', () async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_LoggedInAuthController.new),
          broadcastsProvider.overrideWith(
            () => _StubBroadcastsNotifier(const PlayerBroadcastsState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(broadcastsProvider.future);
      container.read(broadcastBannerProvider.notifier).showFromSocket(
            _broadcast(id: 'socket-1'),
          );

      expect(
        container.read(broadcastBannerProvider).visibleMessage?.id,
        'socket-1',
      );
    });

    test('hideBanner prevents the same inbox message from reappearing', () async {
      final stub = _StubBroadcastsNotifier(
        PlayerBroadcastsState(
          inboxBroadcasts: [_broadcast(id: 'msg-1')],
          unreadCount: 1,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_LoggedInAuthController.new),
          broadcastsProvider.overrideWith(() => stub),
        ],
      );
      addTearDown(container.dispose);

      await container.read(broadcastsProvider.future);
      final banner = container.read(broadcastBannerProvider.notifier);
      banner.showFromSocket(_broadcast(id: 'msg-1'));
      banner.hideBanner();

      stub.emit(
        PlayerBroadcastsState(
          inboxBroadcasts: [_broadcast(id: 'msg-1')],
          unreadCount: 1,
        ),
      );

      expect(container.read(broadcastBannerProvider).visibleMessage, isNull);
    });
  });

  testWidgets('BroadcastTopBanner renders visible admin message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedInAuthController.new),
          broadcastsProvider.overrideWith(
            () => _StubBroadcastsNotifier(const PlayerBroadcastsState()),
          ),
          broadcastBannerProvider.overrideWith(() => _VisibleBannerController()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BroadcastTopBanner(),
          ),
        ),
      ),
    );

    expect(find.text('Title banner-1'), findsOneWidget);
    expect(find.text('Body banner-1'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}

class _VisibleBannerController extends BroadcastBannerNotifier {
  @override
  BroadcastBannerState build() {
    ref.listen(
      broadcastsProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    return BroadcastBannerState(
      visibleMessage: _broadcast(id: 'banner-1'),
    );
  }
}
