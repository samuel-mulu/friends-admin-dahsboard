import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/payment_provider.dart';
import '../../data/wallet_repository.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  static const _cbeTestReference = 'FTMOCK100';
  static const _telebirrTestReference = 'TBMOCK100';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionRefController = TextEditingController();

  PaymentProvider _provider = PaymentProvider.cbe;
  bool _isSubmitting = false;
  DepositModel? _latestDeposit;

  @override
  void dispose() {
    _amountController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProviderSelector(
                  value: _provider,
                  onChanged: (provider) {
                    setState(() {
                      _provider = provider;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_provider.depositInstruction),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: '100',
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transactionRefController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: _provider == PaymentProvider.cbe
                        ? 'FT number'
                        : 'Receipt ID',
                    hintText: _provider == PaymentProvider.cbe
                        ? 'FT26152ZN0XY'
                        : 'TB123456789',
                  ),
                  validator: _validateTransactionRef,
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Development / test helper',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _provider == PaymentProvider.cbe
                              ? 'Development test reference: $_cbeTestReference'
                              : 'Development test reference: $_telebirrTestReference',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () {
                              _transactionRefController.text =
                                  _provider == PaymentProvider.cbe
                                  ? _cbeTestReference
                                  : _telebirrTestReference;
                            },
                            child: const Text('Use test reference'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit deposit'),
                ),
                if (_latestDeposit != null) ...[
                  const SizedBox(height: 20),
                  _DepositStatusCard(deposit: _latestDeposit!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final deposit = await ref
          .read(walletRepositoryProvider)
          .createDeposit(
            provider: _provider,
            amount: _amountController.text.trim(),
            transactionRef: _transactionRefController.text.trim().toUpperCase(),
          );

      ref.invalidate(myWalletProvider);
      ref.invalidate(depositHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _latestDeposit = deposit;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deposit submitted. Status: ${deposit.status.label}.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Could not submit deposit.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateAmount(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Amount is required.';
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmed)) {
      return 'Enter a valid amount.';
    }
    if (double.tryParse(trimmed) == null || double.parse(trimmed) <= 0) {
      return 'Amount must be greater than zero.';
    }
    return null;
  }

  String? _validateTransactionRef(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < 6) {
      return 'Enter a valid transaction reference.';
    }
    return null;
  }
}

class _ProviderSelector extends StatelessWidget {
  const _ProviderSelector({required this.value, required this.onChanged});

  final PaymentProvider value;
  final ValueChanged<PaymentProvider> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PaymentProvider>(
      segments: const [
        ButtonSegment(value: PaymentProvider.cbe, label: Text('CBE')),
        ButtonSegment(value: PaymentProvider.telebirr, label: Text('Telebirr')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _DepositStatusCard extends StatelessWidget {
  const _DepositStatusCard({required this.deposit});

  final DepositModel deposit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest deposit',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _StatusChip(status: deposit.status.label),
            const SizedBox(height: 12),
            Text('Provider: ${deposit.provider.label}'),
            Text('Amount: ${formatMoney(deposit.amount)}'),
            Text('Reference: ${deposit.transactionRef}'),
            Text('Created: ${formatDateTime(deposit.createdAt)}'),
            if (deposit.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text('Reason: ${deposit.rejectionReason}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(status),
    );
  }
}
