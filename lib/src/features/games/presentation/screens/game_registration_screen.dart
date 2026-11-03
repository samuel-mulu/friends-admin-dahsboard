import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:friends_bingo_app/src/core/theme/app_branding.dart';
import 'package:friends_bingo_app/src/core/utils/formatters.dart';
import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/application/controllers/live_game_host.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/repositories/cartelas_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/games_repository.dart';
import 'package:friends_bingo_app/src/features/games/data/models/game_model.dart';
import 'package:friends_bingo_app/src/features/games/patterns/domain/game_rule_localized_name.dart';
import 'package:friends_bingo_app/src/features/games/presentation/screens/live_game_screen.dart';
import 'package:friends_bingo_app/src/features/games/presentation/widgets/game_category_badge.dart';
import 'package:friends_bingo_app/src/features/games/registration/application/controllers/live_registration_controller.dart';
import 'package:friends_bingo_app/src/features/games/registration/presentation/widgets/registration_grid_scroll_isolation.dart';
import 'package:friends_bingo_app/src/features/wallet/overview/application/providers/wallet_provider.dart';

/// Standalone full-screen page for game cartela registration.
///
/// Can be pushed as an independent route or navigated to from game lobbies,
/// scheduled cards, or deep links.
class GameRegistrationScreen extends ConsumerStatefulWidget {
  const GameRegistrationScreen({
    required this.game,
    this.registration,
    this.slotId,
    this.isGuest = false,
    this.cartelaHoldSeconds = 10,
    this.bulkSelectionSeconds = 30,
    this.onRegistered,
    super.key,
  });

  final GameModel game;
  final LiveRegistrationController? registration;
  final String? slotId;
  final bool isGuest;
  final int cartelaHoldSeconds;
  final int bulkSelectionSeconds;
  final ValueChanged<List<GameCartelaModel>>? onRegistered;

  static Route<List<GameCartelaModel>?> route({
    required GameModel game,
    LiveRegistrationController? registration,
    String? slotId,
    bool isGuest = false,
  }) {
    return MaterialPageRoute<List<GameCartelaModel>?>(
      builder: (_) => GameRegistrationScreen(
        game: game,
        registration: registration,
        slotId: slotId,
        isGuest: isGuest,
      ),
    );
  }

  @override
  ConsumerState<GameRegistrationScreen> createState() =>
      _GameRegistrationScreenState();
}

class _GameRegistrationScreenState
    extends ConsumerState<GameRegistrationScreen>
    implements LiveGameHost {
  late final LiveRegistrationController _registration;
  final List<GameCartelaModel> _registeredCartelas = [];

  @override
  void initState() {
    super.initState();
    _registration = widget.registration ?? LiveRegistrationController(this);
  }

  @override
  void dispose() {
    if (widget.registration == null) {
      _registration.dispose();
    }
    super.dispose();
  }

  @override
  bool get isLiveHostActive => mounted;

  @override
  bool get embedded => false;

  @override
  bool get isAppInForeground => true;

  @override
  String? get gameId => widget.game.id;

  @override
  GameModel? get initialGame => widget.game;

  @override
  GameModel? get game => widget.game;

  @override
  set game(GameModel? value) {}

  @override
  bool get isGuest => widget.isGuest;

  @override
  GamesRepository get gamesRepository => ref.read(gamesRepositoryProvider);

  @override
  CartelasRepository get cartelasRepository =>
      ref.read(cartelasRepositoryProvider);

  @override
  void markNeedsBuild([VoidCallback? fn]) {
    if (mounted) {
      setState(() {
        fn?.call();
      });
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void _handleCartelasRegistered(List<GameCartelaModel> cartelas) {
    setState(() {
      _registeredCartelas.addAll(cartelas);
    });
    widget.onRegistered?.call(cartelas);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final game = widget.game;
    final wallet = widget.isGuest
        ? null
        : switch (ref.watch(myWalletProvider)) {
            AsyncData(:final value) => value,
            _ => null,
          };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    game.localizedRuleName(ref),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GameCategoryBadge(category: game.category, compact: true),
              ],
            ),
            Text(
              '${l10n.bigGameEntryFee}: ${formatMoney(game.entryFee)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (wallet != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: AppBranding.balanceAccent(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatMoney(wallet.balance),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppBranding.balanceAccent(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: RegistrationGridScrollIsolation(
            child: CartelaRegistrationPanel(
              registration: _registration,
              slotId: widget.slotId ?? game.id,
              sessionId: game.sessionId,
              gameStatus: game.status,
              entryFee: game.entryFee,
              prizePerCartela: game.prizePerCartela,
              category: game.category,
              fixedPrizeAmount: game.fixedPrizeAmount,
              maxCartelasPerPlayer: game.maxCartelasPerPlayer,
              roundPrizes: game.roundPrizes,
              registeredCartelas: _registeredCartelas,
              cartelaHoldSeconds: widget.cartelaHoldSeconds,
              bulkSelectionSeconds: widget.bulkSelectionSeconds,
              isGuest: widget.isGuest,
              onRegistered: _handleCartelasRegistered,
            ),
          ),
        ),
      ),
    );
  }
}
