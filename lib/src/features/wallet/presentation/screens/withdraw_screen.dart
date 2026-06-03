import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/payment_provider.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/wallet_repository.dart';
import '../providers/wallet_history_providers.dart';
import '../providers/wallet_provider.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _receiverController = TextEditingController();

  PaymentProvider _provider = PaymentProvider.telebirr;
  bool _isSubmitting = false;
  WithdrawalModel? _latestWithdrawal;

  @override
  void dispose() {
    _amountController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WithdrawProviderSelector(
                  value: _provider,
                  onChanged: (provider) {
                    setState(() {
                      _provider = provider;
                    });
                  },
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
                  controller: _receiverController,
                  keyboardType: _provider == PaymentProvider.telebirr
                      ? TextInputType.phone
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: _provider.receiverFieldLabel,
                    hintText: _provider.receiverFieldHint,
                  ),
                  validator: _validateReceiver,
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
                      : const Text('Submit withdrawal'),
                ),
                if (_latestWithdrawal != null) ...[
                  const SizedBox(height: 20),
                  _WithdrawalStatusCard(withdrawal: _latestWithdrawal!),
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
      final receiverValue = _receiverController.text.trim();
      final withdrawal = await ref
          .read(walletRepositoryProvider)
          .createWithdrawal(
            provider: _provider,
            amount: _amountController.text.trim(),
            receiverPhone: _provider == PaymentProvider.telebirr
                ? receiverValue
                : null,
            receiverAccount: _provider == PaymentProvider.cbe
                ? receiverValue
                : null,
          );

      ref.invalidate(myWalletProvider);
      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(walletTransactionsProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _latestWithdrawal = withdrawal;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal submitted. Status: ${withdrawal.status.label}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Could not submit withdrawal.',
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

  String? _validateReceiver(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '${_provider.receiverFieldLabel} is required.';
    }
    if (_provider == PaymentProvider.telebirr &&
        !RegExp(r'^\d{10,15}$').hasMatch(trimmed)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }
}

class _WithdrawProviderSelector extends StatelessWidget {
  const _WithdrawProviderSelector({
    required this.value,
    required this.onChanged,
  });

  final PaymentProvider value;
  final ValueChanged<PaymentProvider> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PaymentProvider>(
      segments: const [
        ButtonSegment(value: PaymentProvider.telebirr, label: Text('Telebirr')),
        ButtonSegment(value: PaymentProvider.cbe, label: Text('CBE')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _WithdrawalStatusCard extends StatelessWidget {
  const _WithdrawalStatusCard({required this.withdrawal});

  final WithdrawalModel withdrawal;

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
              'Latest withdrawal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text('Status: ${withdrawal.status.label}'),
            Text('Provider: ${withdrawal.provider.label}'),
            Text('Amount: ${formatMoney(withdrawal.amount)}'),
            Text('Created: ${formatDateTime(withdrawal.createdAt)}'),
          ],
        ),
      ),
    );
  }
}
