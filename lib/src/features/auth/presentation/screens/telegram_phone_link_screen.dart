import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/l10n.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_validators.dart';
import '../widgets/otp_code_input.dart';

class TelegramPhoneLinkScreen extends ConsumerStatefulWidget {
  const TelegramPhoneLinkScreen({required this.ticket, super.key});

  final String ticket;

  @override
  ConsumerState<TelegramPhoneLinkScreen> createState() =>
      _TelegramPhoneLinkScreenState();
}

class _TelegramPhoneLinkScreenState
    extends ConsumerState<TelegramPhoneLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _otp = '';
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);

    return AuthErrorListener(
      child: AuthScreenScaffold(
        title: l10n.telegramLinkPhoneTitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.telegramLinkPhoneSubtitle),
              const SizedBox(height: 18),
              AuthFormField(
                controller: _phoneController,
                label: l10n.loginPhone,
                hint: l10n.loginPhoneHint,
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => validatePhoneNumber(v, l10n),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 18),
                OtpCodeInput(onChanged: (value) => _otp = value),
              ],
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: _otpSent
                    ? l10n.telegramCompleteSignIn
                    : l10n.forgotPasswordSendCode,
                isLoading: auth.isSubmitting || auth.isSendingOtp,
                onPressed: _otpSent ? _complete : _sendOtp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final message = await ref
        .read(authControllerProvider.notifier)
        .telegramRequestOtp(
          ticket: widget.ticket,
          phoneNumber: _phoneController.text.trim(),
        );
    if (!mounted || message == null) {
      return;
    }
    setState(() => _otpSent = true);
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate() || _otp.length < kOtpCodeLength) {
      return;
    }
    await ref.read(authControllerProvider.notifier).telegramComplete(
          ticket: widget.ticket,
          phoneNumber: _phoneController.text.trim(),
          otp: _otp,
        );
    if (!mounted) {
      return;
    }
    if (ref.read(authControllerProvider).session != null) {
      navigateAfterAuthentication(GoRouter.of(context));
    }
  }
}

Future<void> launchTelegramLogin(BuildContext context, WidgetRef ref) async {
  final baseUrl = ref.read(appConfigProvider).apiBaseUrl;
  final uri = Uri.parse(
    baseUrl.endsWith('/')
        ? '${baseUrl}auth/telegram/widget'
        : '$baseUrl/auth/telegram/widget',
  );
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.telegramOpenFailed)),
    );
  }
}

Map<String, dynamic>? parseTelegramAuthUri(Uri uri) {
  if (uri.scheme != 'friendsbingo' || uri.host != 'telegram-auth') {
    return null;
  }

  final params = uri.queryParameters;
  final id = int.tryParse(params['id'] ?? '');
  final authDate = int.tryParse(params['auth_date'] ?? '');
  final hash = params['hash'];
  if (id == null || authDate == null || hash == null || hash.isEmpty) {
    return null;
  }

  return {
    'id': id,
    'auth_date': authDate,
    'hash': hash,
    if (params['first_name'] != null) 'first_name': params['first_name'],
    if (params['last_name'] != null) 'last_name': params['last_name'],
    if (params['username'] != null) 'username': params['username'],
    if (params['photo_url'] != null) 'photo_url': params['photo_url'],
  };
}
