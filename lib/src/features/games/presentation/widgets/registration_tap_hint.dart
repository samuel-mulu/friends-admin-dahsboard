import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';

class RegistrationTapHint extends StatelessWidget {
  const RegistrationTapHint({
    required this.isGuest,
    required this.selectModeEnabled,
    super.key,
  });

  final bool isGuest;
  final bool selectModeEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n = context.l10n;
    final message = isGuest
        ? l10n.gameHintGuest
        : selectModeEnabled
            ? l10n.gameHintSelectMode
            : l10n.gameHintSingleMode;

    return Text(
      message,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
