import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import 'auth_form_field.dart';
import 'auth_primary_button.dart';
import 'auth_validators.dart';
import 'otp_code_input.dart';
import 'sms_otp_hint_banner.dart';

class ForgotPasswordResetPanel extends ConsumerStatefulWidget {
  const ForgotPasswordResetPanel({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  ConsumerState<ForgotPasswordResetPanel> createState() =>
      _ForgotPasswordResetPanelState();
}

class _ForgotPasswordResetPanelState
    extends ConsumerState<ForgotPasswordResetPanel> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _otp = '';
  String? _otpError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sendCode());
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final maskedPhone = maskPhoneNumber(widget.phoneNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set a new password',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the SMS code sent to $maskedPhone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const SmsOtpHintBanner(),
        const SizedBox(height: 24),
        OtpCodeInput(
          onChanged: (code) {
            setState(() {
              _otp = code;
              _otpError = null;
            });
          },
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 10),
          Text(
            _otpError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 22),
        AuthFormField(
          controller: _newPasswordController,
          label: 'New password',
          hint: 'Minimum 8 characters',
          prefixIcon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          validator: validatePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 18),
        AuthFormField(
          controller: _confirmPasswordController,
          label: 'Confirm new password',
          hint: 'Re-enter your new password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value != _newPasswordController.text) {
              return 'Passwords do not match.';
            }
            return validatePassword(value);
          },
          onFieldSubmitted: (_) => _submit(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Update password',
          isLoading: authState.isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: authState.isSendingOtp ? null : _sendCode,
          child: authState.isSendingOtp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Resend code'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: authState.isSubmitting || authState.isSendingOtp
              ? null
              : () {
                  ref.read(forgotPasswordStepProvider.notifier).showPhone();
                },
          child: const Text('Back to phone number'),
        ),
      ],
    );
  }

  Future<void> _sendCode() async {
    final message = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordResetOtp(phoneNumber: widget.phoneNumber);

    if (!mounted) {
      return;
    }

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _submit() async {
    if (_otp.length != 4) {
      setState(() => _otpError = 'Enter the 4-digit verification code.');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (validatePassword(_newPasswordController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters.'),
        ),
      );
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    final passwordResetPhoneNotifier =
        ref.read(passwordResetPhoneProvider.notifier);
    final forgotPasswordStepNotifier =
        ref.read(forgotPasswordStepProvider.notifier);
    final router = GoRouter.of(context);

    final message = await authNotifier.resetPassword(
      phoneNumber: widget.phoneNumber,
      otp: _otp,
      newPassword: _newPasswordController.text,
    );

    if (!mounted || message == null) {
      return;
    }

    passwordResetPhoneNotifier.clear();
    forgotPasswordStepNotifier.showPhone();
    router.go('/login?message=${Uri.encodeComponent(message)}');
  }
}
