import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/app_lock_controller.dart';
import '../controllers/auth_controller.dart';

Future<bool> showLocalReauthDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _LocalReauthDialog(),
  );

  return result ?? false;
}

class _LocalReauthDialog extends ConsumerStatefulWidget {
  const _LocalReauthDialog();

  @override
  ConsumerState<_LocalReauthDialog> createState() => _LocalReauthDialogState();
}

class _LocalReauthDialogState extends ConsumerState<_LocalReauthDialog> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isWorking = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    return AlertDialog(
      title: const Text('Confirm withdrawal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Use your device security before sending money.'),
            if (lockState.canUseBiometric) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isWorking ? null : _useBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use fingerprint'),
              ),
            ],
            if (lockState.hasPin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: '4-digit PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isWorking ? null : _usePin,
                child: const Text('Confirm with PIN'),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isWorking ? null : _usePassword,
              child: const Text('Confirm with password'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
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
          onPressed: _isWorking
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _useBiometric() async {
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithBiometric();

    if (!mounted) {
      return;
    }

    setState(() {
      _isWorking = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorMessage = 'Biometric check failed.';
    });
  }

  Future<void> _usePin() async {
    final pin = _pinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'Enter your 4-digit PIN.';
      });
      return;
    }

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithPin(pin);

    if (!mounted) {
      return;
    }

    setState(() {
      _isWorking = false;
    });

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorMessage = 'PIN was not correct.';
    });
  }

  Future<void> _usePassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your password.';
      });
      return;
    }

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .reauthenticateWithPassword(password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isWorking = false;
    });

    if (success) {
      final lockController = ref.read(appLockControllerProvider.notifier);
      await lockController.resetFailedPinAttempts();
      if (!mounted) {
        return;
      }
      lockController.unlock();
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorMessage = 'Password was not accepted.';
    });
  }
}
