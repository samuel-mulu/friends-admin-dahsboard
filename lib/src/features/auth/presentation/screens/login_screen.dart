import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_home_back_button.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({this.initialMessage, super.key});

  final String? initialMessage;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _didShowInitialMessage = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!_didShowInitialMessage && widget.initialMessage != null) {
      _didShowInitialMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initialMessage!)),
        );
      });
    }

    final isSubmitting = ref.watch(
      authControllerProvider.select((state) => state.isSubmitting),
    );

    return AuthErrorListener(
      child: AuthScreenScaffold(
        leading: const AuthHomeBackButton(),
        title: l10n.loginTitle,
        footer: TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  ref.read(registrationDraftProvider.notifier).clear();
                  ref.read(registerStepProvider.notifier).showDetails();
                  context.go('/register');
                },
          child: Text(l10n.loginCreateAccount),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthFormField(
                controller: _phoneController,
                label: l10n.loginPhone,
                hint: l10n.loginPhoneHint,
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: (v) => validatePhoneNumber(v, l10n),
              ),
              const SizedBox(height: 18),
              AuthFormField(
                controller: _passwordController,
                label: l10n.loginPassword,
                hint: l10n.loginPasswordHint,
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (v) => validatePassword(v, l10n),
                onFieldSubmitted: (_) => _submit(),
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        ref.read(passwordResetPhoneProvider.notifier).clear();
                        ref
                            .read(forgotPasswordStepProvider.notifier)
                            .showPhone();
                        context.go('/forgot-password');
                      },
                  child: Text(l10n.loginForgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: l10n.loginSignIn,
                isLoading: isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.login(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }
}

