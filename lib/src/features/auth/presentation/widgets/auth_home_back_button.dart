import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthHomeBackButton extends StatelessWidget {
  const AuthHomeBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back to home',
      onPressed: () => context.go('/games'),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
