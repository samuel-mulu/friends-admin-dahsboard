import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/games_repository.dart';
import '../providers/games_providers.dart';
import '../widgets/cartela_preview_card.dart';

class CartelaPickerScreen extends ConsumerStatefulWidget {
  const CartelaPickerScreen({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<CartelaPickerScreen> createState() =>
      _CartelaPickerScreenState();
}

class _CartelaPickerScreenState extends ConsumerState<CartelaPickerScreen> {
  String? _selectedCartelaId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cartelasAsync = ref.watch(cartelasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose cartela')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cartelasProvider);
          await ref.read(cartelasProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pick one cartela to register',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your wallet will be charged the game entry fee after a successful registration.',
            ),
            const SizedBox(height: 20),
            cartelasAsync.when(
              data: (cartelas) {
                if (cartelas.isEmpty) {
                  return const _PickerInfoCard(
                    message: 'No cartelas are available right now.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...cartelas.map(
                      (cartela) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CartelaPreviewCard(
                          cartela: cartela,
                          isSelected: _selectedCartelaId == cartela.id,
                          onTap: () {
                            setState(() {
                              _selectedCartelaId = cartela.id;
                            });
                          },
                          trailing: Icon(
                            _selectedCartelaId == cartela.id
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _selectedCartelaId == cartela.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register selected cartela'),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _PickerInfoCard(
                message: error is ApiException
                    ? error.message
                    : 'Could not load cartelas.',
                action: FilledButton.tonal(
                  onPressed: () => ref.invalidate(cartelasProvider),
                  child: const Text('Try again'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final selectedCartelaId = _selectedCartelaId;
    if (selectedCartelaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a cartela first.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(gamesRepositoryProvider)
          .registerCartela(gameId: widget.gameId, cartelaId: selectedCartelaId);

      ref.invalidate(myWalletProvider);
      ref.invalidate(gamesListProvider);
      ref.invalidate(gameDetailProvider(widget.gameId));
      ref.invalidate(myGameCartelasProvider(widget.gameId));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cartela registered successfully.')),
      );
      context.go('/games/${widget.gameId}/my-cartelas');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is ApiException
          ? error.message
          : 'Could not register this cartela.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _PickerInfoCard extends StatelessWidget {
  const _PickerInfoCard({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
