import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/registration_draft.dart';
import '../providers/auth_flow_provider.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_validators.dart';
import '../widgets/register_otp_panel.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(registerStepProvider);
    final draft = ref.watch(registrationDraftProvider);

    return AuthErrorListener(
      child: AuthScreenScaffold(
        footer: step == RegisterStep.details
            ? TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign in'),
              )
            : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: step == RegisterStep.otp && draft != null
              ? RegisterOtpPanel(
                  key: const ValueKey('register-otp'),
                  draft: draft,
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    key: const ValueKey('register-details'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthFormField(
                        controller: _fullNameController,
                        label: 'Full name',
                        hint: 'Samuel Mulu',
                        prefixIcon: Icons.person_rounded,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: validateFullName,
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        controller: _phoneController,
                        label: 'Phone number',
                        hint: '0912345678',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: validatePhoneNumber,
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Minimum 8 characters',
                        prefixIcon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthFormField(
                        controller: _confirmPasswordController,
                        label: 'Confirm password',
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return validatePassword(value);
                        },
                        onFieldSubmitted: (_) => _continueToOtp(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: 'Continue',
                        onPressed: _continueToOtp,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _continueToOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(registrationDraftProvider.notifier).save(
          RegistrationDraft(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
          ),
        );
    ref.read(registerStepProvider.notifier).showOtp();
  }
}
