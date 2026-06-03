import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/games_providers.dart';
import '../widgets/cartela_preview_card.dart';

class MyGameCartelasScreen extends ConsumerWidget {
  const MyGameCartelasScreen({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartelasAsync = ref.watch(myGameCartelasProvider(gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('My game cartelas')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myGameCartelasProvider(gameId));
          await ref.read(myGameCartelasProvider(gameId).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            cartelasAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const _MyCartelasEmptyState();
                }

                return Column(
                  children: entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        entry.status.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const Spacer(),
                                      if (entry.isWinner)
                                        const Icon(Icons.emoji_events_outlined),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  CartelaPreviewCard(cartela: entry.cartela),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _MyCartelasErrorState(
                message: error is ApiException
                    ? error.message
                    : 'Could not load your cartelas for this game.',
                onRetry: () => ref.invalidate(myGameCartelasProvider(gameId)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCartelasEmptyState extends StatelessWidget {
  const _MyCartelasEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'No registered cartelas yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Once you register a cartela for this game, it will show here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCartelasErrorState extends StatelessWidget {
  const _MyCartelasErrorState({required this.message, required this.onRetry});

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
