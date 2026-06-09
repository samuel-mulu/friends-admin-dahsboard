import 'package:flutter/material.dart';

import '../../../../core/theme/app_branding.dart';
import '../../data/models/game_cartela_model.dart';
import '../utils/cartela_mark_helpers.dart';

class LiveCartelaCard extends StatelessWidget {
  const LiveCartelaCard({
    required this.gameCartela,
    required this.canClaimBingo,
    required this.isClaiming,
    required this.pendingReview,
    required this.manualMarkedNumbers,
    required this.onMarkedNumberToggled,
    required this.onClaimBingo,
    this.winnerWindowSeconds,
    super.key,
  });

  final GameCartelaModel gameCartela;
  final bool canClaimBingo;
  final bool isClaiming;
  final bool pendingReview;
  final Set<String> manualMarkedNumbers;
  final void Function(String header, String value) onMarkedNumberToggled;
  final VoidCallback onClaimBingo;
  final int? winnerWindowSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBlocked = gameCartela.status == GameCartelaStatus.blocked;
    final isWinner = gameCartela.isWinner;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              gradient: isBlocked
                  ? LinearGradient(
                      colors: [
                        theme.colorScheme.error.withValues(alpha: 0.92),
                        theme.colorScheme.error,
                      ],
                    )
                  : const LinearGradient(
                      colors: [
                        AppBranding.casinoPurpleDeep,
                        AppBranding.casinoPurple,
                      ],
                    ),
            ),
            child: Row(
              children: [
                Text(
                  '${gameCartela.cartela.number}',
                  style: isBlocked
                      ? theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w900,
                        )
                      : AppBranding.wordmarkGold(size: 18),
                ),
                Expanded(
                  child: Center(
                    child: isBlocked
                        ? Text(
                            'BLOCKED',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          )
                        : _BingoButton(
                            canClaim: canClaimBingo,
                            isClaiming: isClaiming,
                            onPressed: onClaimBingo,
                          ),
                  ),
                ),
                if (winnerWindowSeconds != null && !isBlocked)
                  Text(
                    '${winnerWindowSeconds}s',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppBranding.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  )
                else
                  const SizedBox(width: 20),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MarkedCartelaGrid(
                      columns: gameCartela.cartela.columns,
                      manualMarkedNumbers: manualMarkedNumbers,
                      onMarkedNumberToggled: onMarkedNumberToggled,
                    ),
                  ),
                  if (pendingReview) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Under review',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (isWinner) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Winner',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppBranding.balanceAccent(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BingoButton extends StatelessWidget {
  const _BingoButton({
    required this.canClaim,
    required this.isClaiming,
    required this.onPressed,
  });

  final bool canClaim;
  final bool isClaiming;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppBranding.gold,
          foregroundColor: AppBranding.casinoPurpleDeep,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: canClaim && !isClaiming ? onPressed : null,
        child: isClaiming
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'BINGO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _MarkedCartelaGrid extends StatelessWidget {
  const _MarkedCartelaGrid({
    required this.columns,
    required this.manualMarkedNumbers,
    required this.onMarkedNumberToggled,
  });

  final List<List<String>> columns;
  final Set<String> manualMarkedNumbers;
  final void Function(String header, String value) onMarkedNumberToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: List.generate(bingoColumnHeaders.length, (index) {
            return Expanded(
              child: Text(
                bingoColumnHeaders[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppBranding.gold : AppBranding.casinoPurple,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Column(
            children: List.generate(5, (rowIndex) {
              return Expanded(
                child: Row(
                  children:
                      List.generate(bingoColumnHeaders.length, (columnIndex) {
                    final value = columns[columnIndex].length > rowIndex
                        ? columns[columnIndex][rowIndex]
                        : '';
                    final header = bingoColumnHeaders[columnIndex];
                    final isMarked = isManuallyMarkedCell(
                      manualMarkedNumbers: manualMarkedNumbers,
                      header: header,
                      value: value,
                    );
                    final isFree = value == 'FREE';

                    return Expanded(
                      child: _CartelaGridCell(
                        value: value,
                        isMarked: isMarked,
                        isFree: isFree,
                        onTap: isFree
                            ? null
                            : () => onMarkedNumberToggled(header, value),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CartelaGridCell extends StatelessWidget {
  const _CartelaGridCell({
    required this.value,
    required this.isMarked,
    required this.isFree,
    required this.onTap,
  });

  final String value;
  final bool isMarked;
  final bool isFree;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(0.5),
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isFree
                ? AppBranding.gold.withValues(alpha: isDark ? 0.38 : 0.45)
                : AppBranding.cellBackground(context, marked: isMarked),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isFree
                  ? AppBranding.gold
                  : AppBranding.cellBorder(context, marked: isMarked),
              width: isFree
                  ? 1.5
                  : AppBranding.cellBorderWidth(marked: isMarked),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isMarked || isFree ? FontWeight.w900 : FontWeight.w600,
                    color: isFree
                        ? AppBranding.casinoPurpleDeep
                        : AppBranding.cellForeground(
                            context,
                            marked: isMarked,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
