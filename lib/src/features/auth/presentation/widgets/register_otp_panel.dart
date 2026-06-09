import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/registration_draft.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import 'auth_primary_button.dart';
import 'auth_validators.dart';
import 'otp_code_input.dart';
import 'sms_otp_hint_banner.dart';

class RegisterOtpPanel extends ConsumerStatefulWidget {
  const RegisterOtpPanel({required this.draft, super.key});

  final RegistrationDraft draft;

  @override
  ConsumerState<RegisterOtpPanel> createState() => _RegisterOtpPanelState();
}

class _RegisterOtpPanelState extends ConsumerState<RegisterOtpPanel> {
  String _otp = '';
  String? _otpError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sendCode());
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final maskedPhone = maskPhoneNumber(widget.draft.phoneNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify your phone',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 4-digit code sent to $maskedPhone.',
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
          onCompleted: (_) => _submit(),
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
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Create account',
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
                  ref.read(registerStepProvider.notifier).showDetails();
                },
          child: const Text('Back to details'),
        ),
      ],
    );
  }

  Future<void> _sendCode() async {
    final message = await ref
        .read(authControllerProvider.notifier)
        .requestRegisterOtp(phoneNumber: widget.draft.phoneNumber);

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

    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.register(
      fullName: widget.draft.fullName,
      phoneNumber: widget.draft.phoneNumber,
      password: widget.draft.password,
      otp: _otp,
    );
  }
}
