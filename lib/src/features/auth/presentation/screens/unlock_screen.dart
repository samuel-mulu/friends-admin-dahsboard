import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../../security/app_lock_controller.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isUnlockingWithPin = false;
  bool _isUnlockingWithPassword = false;
  bool _obscurePassword = true;
  String? _pinError;
  String? _passwordError;

  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Unlock Friends Bingo to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (lockState.canUseBiometric) ...[
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _unlockWithBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use fingerprint'),
                    ),
                  ],
                  if (lockState.hasPin) ...[
                    const SizedBox(height: 28),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: '4-digit PIN',
                        errorText: _pinError,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isUnlockingWithPin ? null : _unlockWithPin,
                      child: _isUnlockingWithPin
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Unlock with PIN'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wrong PIN attempts: ${lockState.failedPinAttempts}/5',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Or confirm with your account password',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _passwordError,
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
                    onPressed: _isUnlockingWithPassword
                        ? null
                        : _unlockWithPassword,
                    child: _isUnlockingWithPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue with password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unlockWithBiometric() async {
    final unlocked = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithBiometric();
    if (!unlocked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric check failed. Try PIN or password.'),
        ),
      );
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _pinError = 'Enter your 4-digit PIN.';
      });
      return;
    }

    setState(() {
      _isUnlockingWithPin = true;
      _pinError = null;
    });

    final unlocked = await ref
        .read(appLockControllerProvider.notifier)
        .unlockWithPin(pin);

    if (mounted) {
      setState(() {
        _isUnlockingWithPin = false;
        _pinError = unlocked
            ? null
            : 'That PIN was not correct. After 5 wrong attempts, you will need to sign in again.';
      });
    }
  }

  Future<void> _unlockWithPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Enter your password.';
      });
      return;
    }

    setState(() {
      _isUnlockingWithPassword = true;
      _passwordError = null;
    });

    final reauthenticated = await ref
        .read(authControllerProvider.notifier)
        .reauthenticateWithPassword(password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUnlockingWithPassword = false;
    });

    if (!reauthenticated) {
      setState(() {
        _passwordError = 'Password was not accepted.';
      });
      return;
    }

    final lockController = ref.read(appLockControllerProvider.notifier);
    await lockController.resetFailedPinAttempts();
    lockController.unlock();
  }
}
