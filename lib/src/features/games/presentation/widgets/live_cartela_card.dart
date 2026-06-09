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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                  style: AppBranding.wordmarkGold(size: 18),
                ),
                Expanded(
                  child: Center(
                    child: !isBlocked
                        ? _BingoButton(
                            canClaim: canClaimBingo,
                            isClaiming: isClaiming,
                            onPressed: onClaimBingo,
                          )
                        : const SizedBox.shrink(),
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
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MarkedCartelaGrid(
                  columns: gameCartela.cartela.columns,
                  manualMarkedNumbers: manualMarkedNumbers,
                  onMarkedNumberToggled: onMarkedNumberToggled,
                ),
                if (pendingReview) ...[
                  const SizedBox(height: 4),
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
                if (isBlocked) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Blocked',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
                if (isWinner) ...[
                  const SizedBox(height: 4),
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
        ...List.generate(5, (rowIndex) {
          return Row(
            children: List.generate(bingoColumnHeaders.length, (columnIndex) {
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
                child: GestureDetector(
                  onTap:
                      isFree ? null : () => onMarkedNumberToggled(header, value),
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isFree
                          ? AppBranding.gold.withValues(alpha: isDark ? 0.25 : 0.35)
                          : AppBranding.cellBackground(
                              context,
                              marked: isMarked,
                            ),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isMarked || isFree
                            ? AppBranding.gold.withValues(alpha: 0.55)
                            : theme.colorScheme.outlineVariant
                                .withValues(alpha: isDark ? 0.35 : 0.5),
                      ),
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight:
                            isMarked || isFree ? FontWeight.w800 : FontWeight.w600,
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
              );
            }),
          );
        }),
      ],
    );
  }
}
