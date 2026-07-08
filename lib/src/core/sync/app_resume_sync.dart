import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/games/data/games_repository.dart';
import '../../features/games/presentation/debug/live_realtime_debug.dart';
import '../../features/games/presentation/providers/current_big_game_provider.dart';
import '../../features/games/presentation/providers/current_game_operations_provider.dart';
import '../../features/games/presentation/utils/live_game_resume_owner_registry.dart';
import '../../features/messages/presentation/providers/broadcasts_provider.dart';
import '../../features/wallet/presentation/providers/wallet_provider.dart';
import '../../core/realtime/socket_service.dart';
import '../time/server_clock_provider.dart';
import 'resume_sync_guard.dart';

/// Canonical app-resume sync — restores live operations, wallet, and hub state.
Future<void> syncAppAfterResume(WidgetRef ref) async {
  if (ResumeSyncGuard.inFlight) {
    LiveRealtimeDebug.resumeSyncIgnored(reason: 'app_resume_guard');
    return;
  }

  final liveGameOwnsResume = LiveGameResumeOwnerRegistry.isActive;
  if (liveGameOwnsResume) {
    LiveRealtimeDebug.resumeSyncIgnored(reason: 'live_game_resume_owner');
    return;
  }

  final resumeDecision = AppBackgroundResumeGate.evaluateFullResumeSync(
    socketConnectedNow: ref.read(socketServiceProvider).isConnected,
  );
  if (!resumeDecision.shouldRunFullResumeSync) {
    LiveRealtimeDebug.resumeSyncIgnored(reason: resumeDecision.reason);
    return;
  }

  try {
    final timing = await ref.read(gamesRepositoryProvider).getTimeConfig();
    final serverNow = timing.serverNow;
    if (serverNow != null) {
      ref.read(serverClockProvider).sync(serverNow, snap: true);
    }
  } catch (_) {}

  await ref
      .read(currentGameOperationsProvider.notifier)
      .refreshFromResumeCacheOrNetwork();

  if (ref.read(authControllerProvider).session != null) {
    await ref.read(currentBigGameProvider.notifier).refresh();
    if (ResumeAuxiliaryRefreshGate.shouldRunWalletRegistration(
      syncReason: 'app_resume',
      force: false,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(myWalletProvider);
        LiveRealtimeDebug.providerInvalidated(
          provider: 'myWallet',
          reason: 'app_resume',
        );
      });
    } else {
      LiveRealtimeDebug.providerInvalidateSkipped(
        provider: 'myWallet',
        reason: 'app_resume_debounced',
      );
    }
    unawaited(ref.read(broadcastsProvider.notifier).refresh());
  }
}
