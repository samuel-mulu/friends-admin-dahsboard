import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/current_big_game_provider.dart';
import '../providers/current_game_operations_provider.dart';

abstract final class BigGameNavigation {
  static void goToBigGame(BuildContext context, WidgetRef ref) {
    unawaited(ref.read(currentBigGameProvider.notifier).refresh());
    unawaited(ref.read(currentGameOperationsProvider.notifier).refresh());
    context.go('/games/big-game');
  }
}
