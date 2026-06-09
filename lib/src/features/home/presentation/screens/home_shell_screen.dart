import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/realtime/wallet_realtime_sync.dart';
import '../../../../core/widgets/friends_bingo_wordmark.dart';
import '../../../settings/presentation/widgets/app_settings_drawer.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const FriendsBingoWordmark(compact: true),
        centerTitle: false,
      ),
      drawer: AppSettingsDrawer(navigationShell: navigationShell),
      body: WalletRealtimeSync(child: navigationShell),
    );
  }
}
