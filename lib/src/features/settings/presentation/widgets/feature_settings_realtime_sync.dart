import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../games/presentation/utils/socket_payload_normalizer.dart';
import '../../domain/feature_settings.dart';
import '../providers/feature_settings_provider.dart';

/// App-level sync for Auto Mark / Auto Bingo settings (not drawer-scoped).
class FeatureSettingsRealtimeSync extends ConsumerStatefulWidget {
  const FeatureSettingsRealtimeSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FeatureSettingsRealtimeSync> createState() =>
      _FeatureSettingsRealtimeSyncState();
}

class _FeatureSettingsRealtimeSyncState
    extends ConsumerState<FeatureSettingsRealtimeSync> {
  static const _eventName = 'user:feature_settings';

  late final SocketService _socketService;
  var _bound = false;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _syncListeners();
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _syncListeners() {
    final hasSession = ref.read(authControllerProvider).session != null;
    if (!hasSession) {
      _unbind();
      return;
    }
    if (_bound) {
      return;
    }

    _socketService.on(_eventName, _onFeatureSettings);
    _socketService.on('connect', _onSocketConnect);
    _bound = true;

    if (kDebugMode) {
      debugPrint(
        '[FeatureSettingsRealtime] listeners bound '
        'connected=${_socketService.isConnected}',
      );
    }
  }

  void _unbind() {
    if (!_bound) {
      return;
    }
    _socketService.off(_eventName, _onFeatureSettings);
    _socketService.off('connect', _onSocketConnect);
    _bound = false;
  }

  void _onSocketConnect(dynamic _) {
    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).session == null) {
      return;
    }
    ref.read(featureSettingsControllerProvider.notifier).refresh(quiet: true);
  }

  void _onFeatureSettings(dynamic rawPayload) {
    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).session == null) {
      return;
    }

    final payload = normalizeSocketPayload(rawPayload);
    if (payload == null) {
      if (kDebugMode) {
        debugPrint(
          '[FeatureSettingsRealtime] Invalid $_eventName: '
          '${rawPayload.runtimeType}',
        );
      }
      return;
    }

    ref
        .read(featureSettingsControllerProvider.notifier)
        .applySocketSettings(FeatureSettings.fromJson(payload));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final hadSession = previous?.session != null;
      final hasSession = next.session != null;
      final previousUserId = previous?.session?.user.id;
      final nextUserId = next.session?.user.id;

      if (!hasSession) {
        _unbind();
        return;
      }

      if (!hadSession || previousUserId != nextUserId) {
        _unbind();
        _syncListeners();
        ref
            .read(featureSettingsControllerProvider.notifier)
            .refresh(quiet: true);
      } else if (!_bound) {
        _syncListeners();
      }
    });

    return widget.child;
  }
}
