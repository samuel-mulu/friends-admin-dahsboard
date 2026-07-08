import 'package:flutter/material.dart';

/// Prevents nested scroll notifications from bubbling to a parent [ListView].
///
/// Use when the registration panel sits inside a fixed-height slot within a
/// parent scroll view so the grid keeps the only scroll owner in that slot.
class RegistrationGridScrollIsolation extends StatelessWidget {
  const RegistrationGridScrollIsolation({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: child,
    );
  }
}
