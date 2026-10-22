import 'package:flutter/material.dart';

import 'package:friends_bingo_app/src/core/utils/l10n.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/registration/domain/blocked_cartela_reason.dart';

Future<void> showBlockedCartelaReasonDialog({
  required BuildContext context,
  required GameCartelaModel gameCartela,
  String? reasonCode,
  String? serverReason,
}) {
  final message = blockedCartelaReasonMessage(
    context,
    reasonCode: reasonCode,
    serverReason: serverReason,
  );

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final l10n = dialogContext.l10n;

      return AlertDialog(
        icon: Icon(
          Icons.block_rounded,
          color: theme.colorScheme.error,
          size: 28,
        ),
        title: Text(
          l10n.cartelaBlockedDialogTitle(gameCartela.cartela.number),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cartelaBlockedDialogOk),
          ),
        ],
      );
    },
  );
}
