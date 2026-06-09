import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    ref.read(socketServiceProvider).on('wallet:updated', _onWalletUpdated);
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).off('wallet:updated', _onWalletUpdated);
    super.dispose();
  }

  void _onWalletUpdated(dynamic _) {
    ref.invalidate(myWalletProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
