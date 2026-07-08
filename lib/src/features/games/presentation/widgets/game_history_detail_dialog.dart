import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../../data/games_repository.dart';
import '../../data/models/game_cartela_model.dart';
import '../../data/models/session_winner_result_model.dart';
import '../../domain/attended_game_history_entry.dart';
import '../../domain/game_rule_localized_name.dart';
import 'history_cartela_detail_dialog.dart';
import 'winner_cartela_dialog.dart';

Future<void> showGameHistoryDetailDialog({
  required BuildContext context,
  required AttendedGameHistoryEntry entry,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _GameHistoryDetailDialog(entry: entry);
    },
  );
}

class _GameHistoryDetailDialog extends ConsumerStatefulWidget {
  const _GameHistoryDetailDialog({required this.entry});

  final AttendedGameHistoryEntry entry;

  @override
  ConsumerState<_GameHistoryDetailDialog> createState() =>
      _GameHistoryDetailDialogState();
}

class _GameHistoryDetailDialogState
    extends ConsumerState<_GameHistoryDetailDialog> {
  Future<List<SessionWinnerResultModel>>? _winnerResultsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _winnerResultsFuture ??= _loadWinnerResults();
  }

  Future<List<SessionWinnerResultModel>> _loadWinnerResults() {
    final sessionId = widget.entry.game.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return Future<List<SessionWinnerResultModel>>.value(const []);
    }

    return ref
        .read(gamesRepositoryProvider)
        .getSessionWinnerResults(sessionId: sessionId);
  }

  SessionWinnerResultModel? _winnerResultFor(
    GameCartelaModel cartela,
    List<SessionWinnerResultModel> results,
  ) {
    for (final result in results) {
      if (result.gameCartelaId == cartela.id ||
          result.cartelaId == cartela.cartelaId ||
          result.cartelaNumber == cartela.cartela.number) {
        return result;
      }
    }
    return null;
  }

  String _statusLabel(GameCartelaModel cartela) {
    if (cartela.isWinner) {
      return 'Winner';
    }
    if (cartela.status == GameCartelaStatus.blocked) {
      return 'Blocked';
    }
    return cartela.status.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final game = widget.entry.game;
    final cartelas = widget.entry.sortedCartelas;
    final localizedRuleName = game.localizedRuleName(ref);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.gameHistoryDetailTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizedRuleName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppBranding.gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$localizedRuleName · ${formatDateTime(game.finishedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PrizeSummary(
                        prizePool: game.prizeAmount,
                        winningsFuture: _winnerResultsFuture,
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<SessionWinnerResultModel>>(
                        future: _winnerResultsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _SessionWinnersBanner(
                              results: const [],
                              isLoading: true,
                            );
                          }

                          return _SessionWinnersBanner(
                            results: snapshot.data ?? const [],
                            isLoading: false,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.gameHistoryYourCartelas,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.winningCartelasTapHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<SessionWinnerResultModel>>(
                        future: _winnerResultsFuture,
                        builder: (context, snapshot) {
                          final results = snapshot.data ?? const [];

                          return Column(
                            children: [
                              for (final cartela in cartelas)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color:
                                        theme.colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      onTap: () {
                                        unawaited(
                                          showHistoryCartelaDetailDialog(
                                            context: context,
                                            cartela: cartela,
                                            winnerResult: _winnerResultFor(
                                              cartela,
                                              results,
                                            ),
                                          ),
                                        );
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        child: Text(
                                          '#${cartela.cartela.number}',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'Cartela ${cartela.cartela.number}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(_statusLabel(cartela)),
                                      trailing: const Icon(
                                        Icons.open_in_full_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrizeSummary extends StatelessWidget {
  const _PrizeSummary({
    required this.prizePool,
    required this.winningsFuture,
  });

  final String prizePool;
  final Future<List<SessionWinnerResultModel>>? winningsFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppBranding.panelBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppBranding.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.gameHistoryPrizePool,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(prizePool),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppBranding.balanceAccent(context),
            ),
          ),
          if (winningsFuture != null) ...[
            const SizedBox(height: 10),
            FutureBuilder<List<SessionWinnerResultModel>>(
              future: winningsFuture,
              builder: (context, snapshot) {
                final results = snapshot.data;
                if (results == null) {
                  return const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                var total = 0.0;
                var hasWin = false;
                for (final result in results) {
                  if (!result.isMine) {
                    continue;
                  }
                  hasWin = true;
                  total += double.tryParse(result.amount) ?? 0;
                }

                if (!hasWin) {
                  return const SizedBox.shrink();
                }

                return Text(
                  l10n.gameHistoryYourWinnings(formatMoney(total.toStringAsFixed(2))),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionWinnersBanner extends StatelessWidget {
  const _SessionWinnersBanner({
    required this.results,
    required this.isLoading,
  });

  final List<SessionWinnerResultModel> results;
  final bool isLoading;

  void _openWinnerDialog(BuildContext context) {
    if (results.isEmpty) {
      return;
    }
    unawaited(showWinnerCartelaDialog(context: context, results: results));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canOpen = results.isNotEmpty;

    if (!isLoading && !canOpen) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppBranding.panelBackground(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: canOpen ? () => _openWinnerDialog(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppBranding.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppBranding.gold,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gameHistorySessionWinners,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? l10n.gameResultsLoading
                          : canOpen
                          ? _winnerLabel(l10n)
                          : l10n.gameResultsLoading,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (canOpen) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.postGameSummaryTapToViewWinner,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canOpen)
                Icon(
                  Icons.open_in_full_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _winnerLabel(dynamic l10n) {
    final primary = results.first.cartelaNumber;
    if (results.length == 1) {
      return l10n.reviewModeWinnerCartela(primary);
    }
    return '${l10n.reviewModeWinnerCartela(primary)} · '
        '${l10n.reviewModeAdditionalWinners(results.length - 1)}';
  }
}
