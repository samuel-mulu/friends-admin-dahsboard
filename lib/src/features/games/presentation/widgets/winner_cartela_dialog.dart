import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/theme/app_branding.dart';
import '../../data/models/session_winner_result_model.dart';
import '../utils/cartela_pattern_progress_overlay.dart';
import '../utils/cartela_board_layout.dart';
import 'winning_pattern_cartela_grid.dart';
import 'winner_cartela_number_strip.dart';

Future<void> showWinnerCartelaDialog({
  required BuildContext context,
  required List<SessionWinnerResultModel> results,
}) {
  if (results.isEmpty) {
    return Future<void>.value();
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return _WinnerCartelaDialog(results: results);
    },
  );
}

class _WinnerCartelaDialog extends StatefulWidget {
  const _WinnerCartelaDialog({required this.results});

  final List<SessionWinnerResultModel> results;

  @override
  State<_WinnerCartelaDialog> createState() => _WinnerCartelaDialogState();
}

class _WinnerCartelaDialogState extends State<_WinnerCartelaDialog> {
  late final PageController _pageController = PageController();
  int _pageIndex = 0;

  List<int> get _winnerNumbers => widget.results
      .map((result) => result.cartelaNumber)
      .toList(growable: false);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.results.length) {
      return;
    }

    setState(() => _pageIndex = index);
    unawaited(
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildGrid(SessionWinnerResultModel result) {
    return WinningPatternCartelaGrid(
      columns: result.columns,
      highlightCellIndexes: result.highlightCellIndexes,
      patternOverlay: CartelaPatternProgressOverlay.fromCompletedPatterns(
        result.completedPatterns,
      ),
      winningBallCellIndex: result.resolvedWinningBallCellIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final results = widget.results;
    final result = results[_pageIndex.clamp(0, results.length - 1)];
    final hasMultiple = results.length > 1;
    final winningBall = result.displayWinningBallLabel;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.winningCartelasTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                l10n.winningCartelasDetailTitle(result.cartelaNumber),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (result.phoneNumber != null &&
                  result.phoneNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  result.phoneNumber!.trim(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                l10n.winningCartelasPrize(result.amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (winningBall != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.winningCartelasWinningBall(winningBall),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppBranding.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (hasMultiple) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.winningCartelasAllWinners,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                WinnerCartelaNumberStrip(
                  numbers: _winnerNumbers,
                  selectedIndex: _pageIndex,
                  onSelected: _goToPage,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.winningCartelasSwipeHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  l10n.winningCartelasTapHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: CartelaBoardLayout.reviewBoardAspectRatio,
                child: hasMultiple
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: results.length,
                            onPageChanged: (index) {
                              setState(() => _pageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: _buildGrid(results[index]),
                              );
                            },
                          ),
                          Positioned(
                            left: 0,
                            child: IconButton(
                              tooltip: l10n.winningCartelasPreviousWinner,
                              onPressed: _pageIndex > 0
                                  ? () => _goToPage(_pageIndex - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              tooltip: l10n.winningCartelasNextWinner,
                              onPressed: _pageIndex < results.length - 1
                                  ? () => _goToPage(_pageIndex + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        ],
                      )
                    : _buildGrid(result),
              ),
              if (hasMultiple) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(results.length, (index) {
                    final active = index == _pageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 10 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? AppBranding.gold
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
