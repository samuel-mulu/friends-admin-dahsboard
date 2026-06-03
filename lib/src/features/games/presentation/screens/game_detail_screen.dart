import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/games_providers.dart';
import '../widgets/game_summary_card.dart';

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Game detail')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gameDetailProvider(gameId));
          await ref.read(gameDetailProvider(gameId).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            gameAsync.when(
              data: (game) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameSummaryCard(game: game),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registration',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            game.status.allowsRegistration
                                ? 'You can register one of your cartelas for this game now.'
                                : 'Registration is closed for this game at the moment.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: game.status.allowsRegistration
                                ? () => context.push('/games/$gameId/cartelas')
                                : null,
                            child: const Text('Register a cartela'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.push('/games/$gameId/live'),
                            child: const Text('Open live screen'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                context.push('/games/$gameId/my-cartelas'),
                            child: const Text('View my registered cartelas'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _DetailErrorState(
                message: error is ApiException
                    ? error.message
                    : 'Could not load game details.',
                onRetry: () => ref.invalidate(gameDetailProvider(gameId)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

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
