import 'package:flutter/material.dart';

import 'cartela_number_badge.dart';

Future<void> showCartelaNumberDialog({
  required BuildContext context,
  required int number,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return GestureDetector(
        onTap: () => Navigator.of(dialogContext).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: CartelaNumberCircleBadge(
            number: number,
            size: 120,
            baseFontSize: 56,
            borderWidth: 2,
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.15, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Wraps an existing cartela-number widget so only that area opens the dialog.
class CartelaNumberTapTarget extends StatelessWidget {
  const CartelaNumberTapTarget({
    required this.number,
    required this.child,
    super.key,
  });

  final int number;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCartelaNumberDialog(context: context, number: number),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
