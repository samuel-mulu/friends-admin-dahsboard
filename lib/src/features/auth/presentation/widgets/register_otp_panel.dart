import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../domain/registration_draft.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import '../../../profile/presentation/providers/profile_avatar_provider.dart';
import 'auth_primary_button.dart';
import 'auth_validators.dart';
import 'otp_code_input.dart';
import 'otp_resend_button.dart';
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final maskedPhone = maskPhoneNumber(widget.draft.phoneNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.otpVerifyPhone,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.otpSentTo(maskedPhone),
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
          label: l10n.otpCreateAccount,
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
                  ref.read(registerStepProvider.notifier).showDetails();
                },
          child: Text(l10n.otpBackToDetails),
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

    if (message == null) {
      final errorMessage = ref.read(authControllerProvider).errorMessage;
      if (_isPhoneAlreadyRegisteredError(errorMessage)) {
        ref.read(registerStepProvider.notifier).showDetails();
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isPhoneAlreadyRegisteredError(String? message) {
    return message?.toLowerCase().contains('already registered') ?? false;
  }

  Future<void> _submit() async {
    if (_otp.length != kOtpCodeLength) {
      setState(() => _otpError = context.l10n.otpEnterCode);
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.register(
      fullName: widget.draft.fullName,
      phoneNumber: widget.draft.phoneNumber,
      password: widget.draft.password,
      otp: _otp,
    );

    final session = ref.read(authControllerProvider).session;
    final avatarId = widget.draft.avatarId;
    if (session != null && mounted) {
      await ref
          .read(profileAvatarControllerProvider(session.user.id))
          .setAvatar(avatarId);
    }
  }
}
