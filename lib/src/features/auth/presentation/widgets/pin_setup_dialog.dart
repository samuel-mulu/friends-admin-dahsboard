import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/app_lock_controller.dart';

class PinSetupDialog extends ConsumerStatefulWidget {
  const PinSetupDialog({super.key});

  @override
  ConsumerState<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends ConsumerState<PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _enableBiometric = false;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    return AlertDialog(
      title: const Text('Set a faster unlock PIN?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create a 4-digit PIN for quick access on this device. Your PIN never leaves the phone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
            ),
            if (lockState.isBiometricAvailable) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _enableBiometric,
                onChanged: (value) {
                  setState(() {
                    _enableBiometric = value ?? false;
                  });
                },
                title: const Text('Use fingerprint'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () async {
                  await ref
                      .read(appLockControllerProvider.notifier)
                      .skipPinSetup();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save PIN'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'PIN must be exactly 4 digits.';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'PIN entries did not match.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    final controller = ref.read(appLockControllerProvider.notifier);
    await controller.setPin(pin);
    if (_enableBiometric) {
      await controller.setBiometricEnabled(true);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop();
  }
}
