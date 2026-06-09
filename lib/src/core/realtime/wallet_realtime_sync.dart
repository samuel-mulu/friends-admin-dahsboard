import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
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
  @override
  void initState() {
    super.initState();
    _syncWalletListener();
  }

  void _syncWalletListener() {
    final socket = ref.read(socketServiceProvider);
    socket.off('wallet:updated', _onWalletUpdated);

    if (ref.read(authControllerProvider).session != null) {
      socket.on('wallet:updated', _onWalletUpdated);
    }
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).off('wallet:updated', _onWalletUpdated);
    super.dispose();
  }

  void _onWalletUpdated(dynamic _) {
    if (!mounted) {
      return;
    }

    ref.invalidate(myWalletProvider);
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
