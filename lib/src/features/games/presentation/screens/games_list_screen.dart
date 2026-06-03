import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/games_providers.dart';
import '../widgets/game_summary_card.dart';

class GamesListScreen extends ConsumerWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gamesListProvider);
        await ref.read(gamesListProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Available games',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse upcoming and open games, then register your cartela when you are ready.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          gamesAsync.when(
            data: (games) {
              if (games.isEmpty) {
                return const _EmptyState(
                  title: 'No games available',
                  message:
                      'New bingo rounds will appear here when they are opened.',
                );
              }

              return Column(
                children: games
                    .map(
                      (game) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GameSummaryCard(
                          game: game,
                          onTap: () => context.push('/games/${game.id}'),
                          action: FilledButton.tonal(
                            onPressed: () => context.push('/games/${game.id}'),
                            child: const Text('View'),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const _LoadingState(),
            error: (error, _) => _ErrorState(
              message: error is ApiException
                  ? error.message
                  : 'Could not load games right now.',
              onRetry: () => ref.invalidate(gamesListProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
