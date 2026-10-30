import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/features/games/cartelas/application/live_cartela_live_store.dart';

/// Rebuilds only this cartela tile when its live presentation revision changes.
class LiveCartelaTile extends StatelessWidget {
  const LiveCartelaTile({
    required this.gameCartelaId,
    required this.store,
    required this.liveListenable,
    required this.builder,
    super.key,
  });

  final String gameCartelaId;
  final LiveCartelaLiveStore store;
  /// Called-number / sort updates (strip revision).
  final Listenable liveListenable;
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        store.listenableFor(gameCartelaId),
        liveListenable,
      ]),
      builder: (context, _) => builder(context),
    );
  }
}
