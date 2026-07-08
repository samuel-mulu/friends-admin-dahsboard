import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/wallet/presentation/providers/wallet_history_providers.dart';
import '../../features/wallet/presentation/providers/wallet_provider.dart';
import 'socket_service.dart';

/// Keeps wallet balance fresh across all tabs when the backend emits updates.
class WalletRealtimeSync extends ConsumerStatefulWidget {
  const WalletRealtimeSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<WalletRealtimeSync> createState() => _WalletRealtimeSyncState();
}

class _WalletRealtimeSyncState extends ConsumerState<WalletRealtimeSync> {
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _syncWalletListener();
  }

  void _syncWalletListener() {
    _socketService.off('wallet:updated', _onWalletUpdated);
    _socketService.off('withdrawal:updated', _onWithdrawalUpdated);

    if (ref.read(authControllerProvider).session != null) {
      _socketService.on('wallet:updated', _onWalletUpdated);
      _socketService.on('withdrawal:updated', _onWithdrawalUpdated);
    }
  }

  @override
  void dispose() {
    _socketService.off('wallet:updated', _onWalletUpdated);
    _socketService.off('withdrawal:updated', _onWithdrawalUpdated);
    super.dispose();
  }

  void _onWalletUpdated(dynamic _) {
    if (!mounted) {
      return;
    }

    ref.invalidate(myWalletProvider);
  }

  void _onWithdrawalUpdated(dynamic _) {
    if (!mounted) {
      return;
    }

    ref.invalidate(withdrawalHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession != hasSession) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncWalletListener();
          }
        });
      }
    });

    return widget.child;
  }
}
