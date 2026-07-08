import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_branding.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/l10n.dart';
import '../providers/game_history_provider.dart';
import '../../domain/game_rule_localized_name.dart';
import '../widgets/game_history_detail_dialog.dart';

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(attendedGameHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameHistoryTitle)),
      body: historyAsync.when(
        data: (state) {
          final entries = state.entries;
          if (entries.isEmpty) {
            return Center(child: Text(l10n.gameHistoryEmptyAttended));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(attendedGameHistoryProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: entries.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  return _LoadMoreFooter(
                    isLoading: state.isLoadingMore,
                    onPressed: () => ref
                        .read(attendedGameHistoryProvider.notifier)
                        .loadMore(),
                  );
                }

                final entry = entries[index];
                final game = entry.game;
                final localizedRuleName = game.localizedRuleName(ref);

                return Card(
                  child: ListTile(
                    onTap: () => showGameHistoryDetailDialog(
                      context: context,
                      entry: entry,
                    ),
                    title: Text(
                      localizedRuleName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '$localizedRuleName · ${formatDateTime(game.finishedAt)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${game.prizeAmount} ETB',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppBranding.balanceAccent(context),
                          ),
                        ),
                        if (entry.hasWinningCartela)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: 16,
                              color: AppBranding.gold,
                            ),
                          ),
                        Text(
                          l10n.gameHistoryMyCartelaCount(
                            entry.myCartelas.length,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.gameHistoryLoadingAttended),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref
                      .read(attendedGameHistoryProvider.notifier)
                      .refresh(),
                  child: Text(l10n.gameHistoryRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(l10n.gameHistoryLoadMore),
              ),
      ),
    );
  }
}
