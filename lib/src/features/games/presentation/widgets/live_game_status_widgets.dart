import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/friends_bingo_loader.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/data/models/game_cartela_model.dart';
import 'package:friends_bingo_app/src/features/games/cartelas/presentation/widgets/live_registered_cartela_list.dart';

class LiveErrorState extends StatelessWidget {
  const LiveErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            VGap.xl,
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class PreparingGamePanel extends StatelessWidget {
  const PreparingGamePanel({
    required this.registeredCartelas,
    required this.isRefetching,
    this.messageOverride,
    this.titleOverride,
    super.key,
  });

  final List<GameCartelaModel> registeredCartelas;
  final bool isRefetching;
  final String? titleOverride;
  final String? messageOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final registeredCount = registeredCartelas.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: AppSpacing.cardPaddingDense,
            child: Column(
              children: [
                if (isRefetching) ...[
                  const FriendsBingoLoader.inline(compact: true),
                  VGap.xl,
                ],
                Text(
                  titleOverride ?? l10n.registrationClosedPreparing,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                VGap.md,
                Text(
                  messageOverride ??
                      (registeredCount == 0
                          ? l10n.preparingGameNoCartelas
                          : l10n.preparingGameCartelasRegistered(
                              registeredCount,
                            )),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (registeredCount > 0) ...[
          VGap.xl,
          Expanded(child: RegisteredCartelaList(cartelas: registeredCartelas)),
        ],
      ],
    );
  }
}

/// Compact waiting state for embedded Big Game (no registered-cartela list).
class BigGameEmbeddedWaitingPanel extends StatelessWidget {
  const BigGameEmbeddedWaitingPanel({required this.isRefetching, super.key});

  final bool isRefetching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRefetching) ...[
              const FriendsBingoLoader.inline(compact: true),
              VGap.lg,
            ],
            Text(
              l10n.registrationClosedPreparing,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            VGap.sm,
            Text(
              l10n.preparingGameNoCartelas,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissedNoNextCard extends StatelessWidget {
  const MissedNoNextCard({
    required this.title,
    required this.message,
    required this.tipWatch,
    required this.tipRefresh,
    super.key,
  });

  final String title;
  final String message;
  final String tipWatch;
  final String tipRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            VGap.md,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            VGap.lg,
            MissedNoNextTipRow(text: tipWatch),
            VGap.sm,
            MissedNoNextTipRow(text: tipRefresh),
          ],
        ),
      ),
    );
  }
}

class MissedNoNextTipRow extends StatelessWidget {
  const MissedNoNextTipRow({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class LiveInfoCard extends StatelessWidget {
  const LiveInfoCard({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingDense,
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            VGap.md,
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class LiveStatusBanner extends StatelessWidget {
  const LiveStatusBanner({
    required this.color,
    required this.foregroundColor,
    required this.title,
    required this.message,
    super.key,
  });

  final Color color;
  final Color foregroundColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class LiveSyncOverlay extends StatelessWidget {
  const LiveSyncOverlay({
    required this.visible,
    required this.title,
    required this.message,
    required this.showRetry,
    required this.onRetry,
    this.dimContent = false,
    super.key,
  });

  final bool visible;
  final String title;
  final String message;
  final bool showRetry;
  final VoidCallback onRetry;
  final bool dimContent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: Container(
          color: Colors.black.withValues(alpha: dimContent ? 0.28 : 0.12),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.fromLTRB(20, 88, 20, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              elevation: 10,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppBranding.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (showRetry) ...[
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
