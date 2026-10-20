import 'package:flutter/material.dart';
import '../../data/models/cartela_model.dart';

enum CartelaBoardSize { compact, standard, large }

class CartelaBoardWidget extends StatelessWidget {
  const CartelaBoardWidget({
    super.key,
    required this.cartela,
    required this.markedCells,
    this.winningPatternCells,
    this.winningBallNumber,
    this.isBlocked = false,
    this.isWinner = false,
    this.interactive = true,
    this.onCellTapped,
    this.boardSize = CartelaBoardSize.standard,
    this.cardHeaderTrailing,
  });

  final CartelaModel cartela;
  final Set<int> markedCells;
  final Set<int>? winningPatternCells;
  final int? winningBallNumber;
  final bool isBlocked;
  final bool isWinner;
  final bool interactive;
  final void Function(int number)? onCellTapped;
  final CartelaBoardSize boardSize;
  final Widget? cardHeaderTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = [
      cartela.b,
      cartela.i,
      cartela.n,
      cartela.g,
      cartela.o,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: isWinner ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isWinner
              ? Colors.amber
              : isBlocked
                  ? Colors.red
                  : theme.dividerColor.withValues(alpha: 0.2),
          width: isWinner ? 2.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Cartela # and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.style_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '#${cartela.number}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ?cardHeaderTrailing,
              ],
            ),
          ),
          // B-I-N-G-O Title Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Row(
              children: ['B', 'I', 'N', 'G', 'O'].map((letter) {
                return Expanded(
                  child: Center(
                    child: Text(
                      letter,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 5x5 Matrix
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: List.generate(5, (colIdx) {
                final colData = columns[colIdx];
                return Expanded(
                  child: Column(
                    children: List.generate(5, (rowIdx) {
                      final isFreeSpace = colIdx == 2 && rowIdx == 2;
                      final rawVal = (colData.length > rowIdx) ? colData[rowIdx] : '0';
                      final number = isFreeSpace ? 0 : (int.tryParse(rawVal) ?? 0);
                      final isMarked = isFreeSpace || (number > 0 && markedCells.contains(number));
                      final isWinningCell = number > 0 && (winningPatternCells?.contains(number) ?? false);
                      final isWinningBall = number > 0 && winningBallNumber != null && winningBallNumber == number;

                      return _buildCell(
                        context: context,
                        number: number,
                        isFreeSpace: isFreeSpace,
                        isMarked: isMarked,
                        isWinningCell: isWinningCell,
                        isWinningBall: isWinningBall,
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required int number,
    required bool isFreeSpace,
    required bool isMarked,
    required bool isWinningCell,
    required bool isWinningBall,
  }) {
    final theme = Theme.of(context);

    Color bgColor = Colors.transparent;
    Color textColor = theme.colorScheme.onSurface;

    if (isWinningBall) {
      bgColor = Colors.amber;
      textColor = Colors.black;
    } else if (isWinningCell) {
      bgColor = Colors.amber.withValues(alpha: 0.4);
      textColor = theme.colorScheme.primary;
    } else if (isMarked) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.85);
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: InkWell(
          onTap: (interactive && !isFreeSpace && onCellTapped != null && number > 0)
              ? () => onCellTapped!(number)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWinningBall
                    ? Colors.orange
                    : isMarked
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.3),
                width: isWinningBall ? 2 : 1,
              ),
            ),
            child: Center(
              child: isFreeSpace
                  ? Text(
                      'FREE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Text(
                      number.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isMarked ? FontWeight.w900 : FontWeight.w600,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
