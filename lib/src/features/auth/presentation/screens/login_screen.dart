import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../providers/auth_flow_provider.dart';
import '../widgets/auth_error_listener.dart';
import '../widgets/auth_form_field.dart';
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
        title: 'Welcome back',
        footer: TextButton(
          onPressed: isSubmitting
              ? null
              : () {
                  ref.read(registrationDraftProvider.notifier).clear();
                  ref.read(registerStepProvider.notifier).showDetails();
                  context.go('/register');
                },
          child: const Text('Create a new account'),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                hint: 'Enter your password',
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: validatePassword,
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
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              AuthPrimaryButton(
                label: 'Sign in',
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

