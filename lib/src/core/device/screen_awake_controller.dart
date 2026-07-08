import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screen_awake_service.dart';

class ScreenAwakeController extends Notifier<bool> {
  late final ScreenAwakeService _service;

  @override
  bool build() {
    _service = ref.read(screenAwakeServiceProvider);
    return false;
  }

  Future<void> setForegroundActive(bool active) async {
    if (state == active) {
      return;
    }

    state = active;
    await _service.setEnabled(active);
  }

  Future<void> syncLifecycle(AppLifecycleState lifecycleState) {
    return switch (lifecycleState) {
      AppLifecycleState.resumed => setForegroundActive(true),
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => setForegroundActive(false),
    };
  }
}

final screenAwakeControllerProvider =
    NotifierProvider<ScreenAwakeController, bool>(ScreenAwakeController.new);
