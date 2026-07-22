import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/realtime/wallet_realtime_sync.dart';
import '../../../games/presentation/widgets/game_announcement_banner.dart';
import '../../../messages/presentation/widgets/broadcast_realtime_sync.dart';
import '../../../messages/presentation/widgets/broadcast_top_banner.dart';
import '../../../messages/presentation/widgets/forced_broadcast_overlay.dart';
import '../../../settings/presentation/widgets/app_settings_drawer.dart';
import '../../../support/presentation/widgets/support_realtime_sync.dart';
import '../widgets/app_shell_app_bar.dart';

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ForcedBroadcastOverlay(
      child: BroadcastRealtimeSync(
        child: SupportRealtimeSync(
          child: Scaffold(
            appBar: AppShellAppBar(navigationShell: navigationShell),
            drawer: AppSettingsDrawer(navigationShell: navigationShell),
            body: Column(
              children: [
                const BroadcastTopBanner(),
                const GameAnnouncementBanner(),
                Expanded(child: WalletRealtimeSync(child: navigationShell)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
