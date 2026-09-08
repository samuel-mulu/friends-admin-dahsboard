import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../controllers/auth_controller.dart';
import 'auth_form_field.dart';
import 'auth_primary_button.dart';
import 'auth_validators.dart';
import 'otp_code_input.dart';

Future<void> showSecurityPasswordSheet(BuildContext context, WidgetRef ref) {
  final hasPassword =
      ref.read(authControllerProvider).session?.user.hasPassword ?? true;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: hasPassword
          ? const _ChangePasswordSheet()
          : const _SetPasswordSheet(),
    ),
  );
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final errorMessage = auth.errorMessage;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.securityChangePassword,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AuthFormField(
                controller: _currentController,
                label: l10n.securityCurrentPassword,
                obscureText: true,
                validator: (v) => validatePassword(v, l10n),
              ),
              const SizedBox(height: 12),
              AuthFormField(
                controller: _newController,
                label: l10n.securityNewPassword,
                obscureText: true,
                validator: (v) => validatePassword(v, l10n),
              ),
              const SizedBox(height: 12),
              AuthFormField(
                controller: _confirmController,
                label: l10n.securityConfirmPassword,
                obscureText: true,
                validator: (value) {
                  if (value != _newController.text) {
                    return l10n.securityPasswordMismatch;
                  }
                  return validatePassword(value, l10n);
                },
              ),
              if (errorMessage != null && errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: l10n.securitySavePassword,
                isLoading: auth.isSubmitting,
                onPressed: () async {
                  final formState = _formKey.currentState;
                  if (formState == null || !formState.validate()) {
                    return;
                  }
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final ok = await ref
                      .read(authControllerProvider.notifier)
                      .changePassword(
                        currentPassword: _currentController.text,
                        newPassword: _newController.text,
                      );
                  if (!context.mounted) {
                    return;
                  }
                  if (!ok) {
                    return;
                  }
                  Navigator.of(context).pop();
                  messenger?.showSnackBar(
                    SnackBar(content: Text(l10n.securityPasswordChanged)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetPasswordSheet extends ConsumerStatefulWidget {
  const _SetPasswordSheet();

  @override
  ConsumerState<_SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends ConsumerState<_SetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String _otp = '';
  bool _otpSent = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final errorMessage = auth.errorMessage;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.securitySetPassword,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.securitySetPasswordHint),
              const SizedBox(height: 16),
              if (_otpSent) ...[
                OtpCodeInput(
                  onChanged: (value) => _otp = value,
                ),
                const SizedBox(height: 12),
                AuthFormField(
                  controller: _newController,
                  label: l10n.securityNewPassword,
                  obscureText: true,
                  validator: (v) => validatePassword(v, l10n),
                ),
                const SizedBox(height: 12),
                AuthFormField(
                  controller: _confirmController,
                  label: l10n.securityConfirmPassword,
                  obscureText: true,
                  validator: (value) {
                    if (value != _newController.text) {
                      return l10n.securityPasswordMismatch;
                    }
                    return validatePassword(value, l10n);
                  },
                ),
                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: l10n.securitySavePassword,
                  isLoading: auth.isSubmitting,
                  onPressed: () async {
                    final formState = _formKey.currentState;
                    if (formState == null || !formState.validate()) {
                      return;
                    }
                    if (_otp.length < kOtpCodeLength) {
                      return;
                    }
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final ok = await ref
                        .read(authControllerProvider.notifier)
                        .setPassword(
                          otp: _otp,
                          newPassword: _newController.text,
                        );
                    if (!context.mounted) {
                      return;
                    }
                    if (!ok) {
                      return;
                    }
                    Navigator.of(context).pop();
                    messenger?.showSnackBar(
                      SnackBar(content: Text(l10n.securityPasswordChanged)),
                    );
                  },
                ),
              ] else
                AuthPrimaryButton(
                  label: l10n.securitySendCode,
                  isLoading: auth.isSendingOtp,
                  onPressed: () async {
                    final message = await ref
                        .read(authControllerProvider.notifier)
                        .requestSetPasswordOtp();
                    if (!context.mounted || message == null) {
                      return;
                    }
                    setState(() => _otpSent = true);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
