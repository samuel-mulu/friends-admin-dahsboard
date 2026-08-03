import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../providers/first_launch_preferences_provider.dart';
import '../screens/first_launch_preferences_screen.dart';

/// Shows the first-launch theme/language prompt once preferences are loaded.
///
/// Mounted inside security/force-update wrappers so those gates stay on top.
class FirstLaunchPreferencesGate extends ConsumerWidget {
  const FirstLaunchPreferencesGate({required this.child, super.key});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(firstLaunchPreferencesCompletedProvider);
    final routedChild = child ?? const SizedBox.shrink();

    return completedAsync.when(
      loading: () => Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppBranding.liveSurfaceDark
            : AppBranding.lightScaffold,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AbsorbPointer(child: routedChild),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (_, _) => routedChild,
      data: (completed) {
        if (completed) {
          return routedChild;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            AbsorbPointer(child: routedChild),
            const FirstLaunchPreferencesScreen(),
          ],
        );
      },
    );
  }
}
