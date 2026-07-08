import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../providers/auth_flow_provider.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_validators.dart';
import '../widgets/forgot_password_reset_panel.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = ref.watch(forgotPasswordStepProvider);
    final phoneNumber = ref.watch(passwordResetPhoneProvider);

    return AuthErrorListener(
      child: AuthScreenScaffold(
        title: step == ForgotPasswordStep.phone ? l10n.forgotPasswordTitle : null,
        subtitle: step == ForgotPasswordStep.phone
            ? l10n.forgotPasswordSubtitle
            : null,
        leading: IconButton(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        footer: step == ForgotPasswordStep.phone
            ? TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.forgotPasswordBackToSignIn),
              )
            : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: step == ForgotPasswordStep.reset &&
                  phoneNumber != null &&
                  phoneNumber.isNotEmpty
              ? ForgotPasswordResetPanel(
                  key: const ValueKey('forgot-reset'),
                  phoneNumber: phoneNumber,
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    key: const ValueKey('forgot-phone'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthFormField(
                        controller: _phoneController,
                        label: l10n.loginPhone,
                        hint: l10n.loginPhoneHint,
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (v) => validatePhoneNumber(v, l10n),
                        onFieldSubmitted: (_) => _continueToReset(),
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: l10n.forgotPasswordSendCode,
                        onPressed: _continueToReset,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _continueToReset() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref
        .read(passwordResetPhoneProvider.notifier)
        .save(_phoneController.text.trim());
    ref.read(forgotPasswordStepProvider.notifier).showReset();
  }
}
