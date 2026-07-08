import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import 'auth_form_field.dart';
import 'auth_primary_button.dart';
import 'auth_validators.dart';
import 'otp_code_input.dart';
import 'otp_resend_button.dart';
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
    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final maskedPhone = maskPhoneNumber(widget.phoneNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.resetPasswordTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.resetPasswordSmsSentTo(maskedPhone),
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
          label: l10n.resetPasswordNewPassword,
          hint: l10n.registerPasswordHint,
          prefixIcon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          validator: (v) => validatePassword(v, l10n),
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
          label: l10n.resetPasswordConfirmNew,
          hint: l10n.resetPasswordConfirmNewHint,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value != _newPasswordController.text) {
              return l10n.validatorPasswordMismatch;
            }
            return validatePassword(value, l10n);
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
          label: l10n.resetPasswordUpdate,
          isLoading: authState.isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        OtpResendButton(
          isSending: authState.isSendingOtp,
          onPressed: _sendCode,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: authState.isSubmitting || authState.isSendingOtp
              ? null
              : () {
                  ref.read(forgotPasswordStepProvider.notifier).showPhone();
                },
          child: Text(l10n.resetPasswordBackToPhone),
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
    final l10n = context.l10n;
    if (_otp.length != kOtpCodeLength) {
      setState(() => _otpError = l10n.otpEnterCode);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validatorPasswordMismatch)),
      );
      return;
    }

    if (validatePassword(_newPasswordController.text, l10n) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validatorPasswordLength),
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
