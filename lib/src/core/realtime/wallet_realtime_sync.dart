import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/games/presentation/utils/socket_payload_normalizer.dart';
import '../../features/wallet/presentation/providers/wallet_history_providers.dart';
import '../../features/wallet/presentation/providers/wallet_provider.dart';
import 'socket_service.dart';
import 'wallet_entity_realtime.dart';

/// Keeps wallet + deposit/withdrawal review status fresh from socket events.
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
    _unbind();

    if (ref.read(authControllerProvider).session == null) {
      return;
    }

    _socketService.on('wallet:updated', _onWalletUpdated);
    _socketService.on('withdrawal:updated', _onWithdrawalUpdated);
    _socketService.on('deposit:updated', _onDepositUpdated);
    _socketService.on('connect', _onSocketConnect);

    if (kDebugMode) {
      debugPrint(
        '[WalletRealtime] listeners bound connected=${_socketService.isConnected}',
      );
    }
  }

  void _unbind() {
    _socketService.off('wallet:updated', _onWalletUpdated);
    _socketService.off('withdrawal:updated', _onWithdrawalUpdated);
    _socketService.off('deposit:updated', _onDepositUpdated);
    _socketService.off('connect', _onSocketConnect);
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _onSocketConnect(dynamic _) {
    if (kDebugMode) {
      debugPrint('[WalletRealtime] socket connected');
    }
  }

  void _onWalletUpdated(dynamic _) {
    if (!mounted) {
      return;
    }
    ref.invalidate(myWalletProvider);
  }

  void _onWithdrawalUpdated(dynamic rawPayload) {
    if (!mounted) {
      return;
    }

    final payload = normalizeSocketPayload(rawPayload);
    if (payload == null) {
      if (kDebugMode) {
        debugPrint(
          '[WalletRealtime] Invalid withdrawal:updated: '
          '${rawPayload.runtimeType}',
        );
      }
      return;
    }

    ref.read(walletEntityRealtimeProvider.notifier).applyWithdrawal(payload);
    ref.invalidate(withdrawalHistoryProvider);
    ref.invalidate(myWalletProvider);
  }

  void _onDepositUpdated(dynamic rawPayload) {
    if (!mounted) {
      return;
    }

    final payload = normalizeSocketPayload(rawPayload);
    if (payload == null) {
      if (kDebugMode) {
        debugPrint(
          '[WalletRealtime] Invalid deposit:updated: '
          '${rawPayload.runtimeType}',
        );
      }
      return;
    }

    ref.read(walletEntityRealtimeProvider.notifier).applyDeposit(payload);
    ref.invalidate(depositHistoryProvider);
    ref.invalidate(myWalletProvider);
    ref.invalidate(walletTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      if (hadSession == hasSession) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncWalletListener();
        }
      });
    });

    return widget.child;
  }
}
