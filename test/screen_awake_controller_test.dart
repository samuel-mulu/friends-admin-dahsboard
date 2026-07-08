import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friends_bingo_app/src/core/device/screen_awake_controller.dart';
import 'package:friends_bingo_app/src/core/device/screen_awake_service.dart';

void main() {
  test('resumed enables keep-awake', () async {
    final service = _FakeScreenAwakeService();
    final container = ProviderContainer(
      overrides: [screenAwakeServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await container
        .read(screenAwakeControllerProvider.notifier)
        .syncLifecycle(AppLifecycleState.resumed);

    expect(container.read(screenAwakeControllerProvider), isTrue);
    expect(service.enabledStates, [true]);
  });

  test('inactive disables keep-awake', () async {
    final service = _FakeScreenAwakeService();
    final container = ProviderContainer(
      overrides: [screenAwakeServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final controller = container.read(screenAwakeControllerProvider.notifier);
    await controller.setForegroundActive(true);
    await controller.syncLifecycle(AppLifecycleState.inactive);

    expect(container.read(screenAwakeControllerProvider), isFalse);
    expect(service.enabledStates, [true, false]);
  });

  test('paused disables keep-awake', () async {
    final service = _FakeScreenAwakeService();
    final container = ProviderContainer(
      overrides: [screenAwakeServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final controller = container.read(screenAwakeControllerProvider.notifier);
    await controller.setForegroundActive(true);
    await controller.syncLifecycle(AppLifecycleState.paused);

    expect(container.read(screenAwakeControllerProvider), isFalse);
    expect(service.enabledStates, [true, false]);
  });

  test('hidden disables keep-awake', () async {
    final service = _FakeScreenAwakeService();
    final container = ProviderContainer(
      overrides: [screenAwakeServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final controller = container.read(screenAwakeControllerProvider.notifier);
    await controller.setForegroundActive(true);
    await controller.syncLifecycle(AppLifecycleState.hidden);

    expect(container.read(screenAwakeControllerProvider), isFalse);
    expect(service.enabledStates, [true, false]);
  });

  test('detached disables keep-awake', () async {
    final service = _FakeScreenAwakeService();
    final container = ProviderContainer(
      overrides: [screenAwakeServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final controller = container.read(screenAwakeControllerProvider.notifier);
    await controller.setForegroundActive(true);
    await controller.syncLifecycle(AppLifecycleState.detached);

    expect(container.read(screenAwakeControllerProvider), isFalse);
    expect(service.enabledStates, [true, false]);
  });
}

class _FakeScreenAwakeService implements ScreenAwakeService {
  final List<bool> enabledStates = <bool>[];

  @override
  Future<void> setEnabled(bool enabled) async {
    enabledStates.add(enabled);
  }
}
