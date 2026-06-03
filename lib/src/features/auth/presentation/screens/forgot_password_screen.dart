import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_screen_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _otpRequested = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
      title: 'Reset password',
      subtitle:
          'Request an OTP for your phone number, then confirm a new password to get back into Friends Bingo.',
      footer: TextButton(
        onPressed: authState.isSubmitting ? null : () => context.go('/login'),
        child: const Text('Back to login'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: _otpRequested
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0912345678',
              ),
              validator: _validatePhoneNumber,
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
                textInputAction: TextInputAction.next,
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  hintText: 'Minimum 8 characters',
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return _validatePassword(value);
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
                    : const Text('Reset password'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (_validatePhoneNumber(_phoneController.text) != null) {
      _formKey.currentState!.validate();
      return;
    }

    final message = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordResetOtp(phoneNumber: _phoneController.text.trim());

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

    final message = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          phoneNumber: _phoneController.text.trim(),
          otp: _otpController.text.trim(),
          newPassword: _newPasswordController.text,
        );

    if (!mounted || message == null) {
      return;
    }

    context.go('/login?message=${Uri.encodeComponent(message)}');
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
