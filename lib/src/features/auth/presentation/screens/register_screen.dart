import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_screen_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpRequested = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final nextMessage = next.errorMessage;
      if (nextMessage != null && nextMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(nextMessage)));
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authControllerProvider);

    return AuthScreenScaffold(
      title: 'Create account',
      subtitle:
          'Register with your phone number first, then verify with an OTP before entering Friends Bingo.',
      footer: TextButton(
        onPressed: authState.isSubmitting ? null : () => context.go('/login'),
        child: const Text('Already have an account? Login'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Samuel Mulu',
              ),
              validator: (value) {
                if ((value?.trim().length ?? 0) < 3) {
                  return 'Full name must be at least 3 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0912345678',
              ),
              validator: _validatePhoneNumber,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Minimum 8 characters',
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: _otpRequested
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return _validatePassword(value);
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: authState.isSubmitting ? null : _sendOtp,
              child: authState.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_otpRequested ? 'Resend OTP' : 'Send OTP'),
            ),
            const SizedBox(height: 12),
            Text(
              'Use OTP 1234 in development.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_otpRequested) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  hintText: '1234',
                ),
                validator: (value) {
                  if (!_otpRequested) {
                    return null;
                  }
                  if ((value?.trim().isEmpty ?? true)) {
                    return 'OTP is required.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: authState.isSubmitting ? null : _submit,
                child: authState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create account'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_validateBeforeOtp()) {
      return;
    }

    final message = await ref
        .read(authControllerProvider.notifier)
        .requestRegisterOtp(phoneNumber: _phoneController.text.trim());

    if (!mounted || message == null) {
      return;
    }

    setState(() {
      _otpRequested = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_otpRequested) {
      await _sendOtp();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          otp: _otpController.text.trim(),
        );
  }

  bool _validateBeforeOtp() {
    final isValidFullName = (_fullNameController.text.trim().length) >= 3;
    final isValidPhone = _validatePhoneNumber(_phoneController.text) == null;
    final isValidPassword = _validatePassword(_passwordController.text) == null;
    final passwordsMatch =
        _confirmPasswordController.text == _passwordController.text &&
        _confirmPasswordController.text.isNotEmpty;

    if (isValidFullName && isValidPhone && isValidPassword && passwordsMatch) {
      return true;
    }

    _formKey.currentState!.validate();
    return false;
  }

  String? _validatePhoneNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Phone number is required.';
    }
    if (!RegExp(r'^\d{10,15}$').hasMatch(trimmed)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }
}
